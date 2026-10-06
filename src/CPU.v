// =============================================================
// cpu_lite_pipeline_top.v
//
// 5-stage pipelined CPU Lite: IF - ID - EX - MEM - WB
// Full ISA from ISA.txt except CALL/RET (per request).
// CPU, cache, and program memory all live in the FAST domain.
// Main memory lives in the SLOW domain, reachable only through
// cpu_lite_mem_system_top's internal CDC FIFOs.
//
// Key design choices (see accompanying explanation):
//   - Branches/jumps resolve in EX -> 2-instruction flush when taken.
//   - Any LOAD/STORE in MEM freezes the whole pipeline (PC, IF/ID,
//     ID/EX, EX/MEM) until the cache asserts cpu_done. This also
//     gives load-use hazards a free ride: the dependent instruction
//     is still frozen upstream when the loaded data lands in
//     MEM/WB, so MEM/WB -> EX forwarding catches it.
//   - EX/MEM forwarding of a load specifically forwards cache_rdata
//     (not alu_result, which for a load only holds the address).
// =============================================================
module cpu_lite_pipeline_top (
    input  wire clk_fast,
    input  wire rst_fast,
    input  wire clk_slow,
    input  wire rst_slow,

    output wire halted,          // HALT has reached WB: program finished
    output wire [11:0] pc_debug  // for simulation/debug visibility
);

    // --------------------------------------------------------
    // Opcodes (per ISA.txt, no CALL/RET)
    // --------------------------------------------------------
    localparam OP_NOP=8'h00, OP_LOAD=8'h01, OP_LOADI=8'h02, OP_LOADIMM=8'h03,
               OP_STORE=8'h04, OP_STOREI=8'h05, OP_ADD=8'h06, OP_SUB=8'h07,
               OP_MUL=8'h08, OP_AND=8'h09, OP_OR=8'h0A, OP_NOT=8'h0B,
               OP_CMP=8'h0C, OP_EQ=8'h0D, OP_JMP=8'h0E, OP_JMPIF=8'h0F,
               OP_XOR=8'h10, OP_SHL=8'h11, OP_SHR=8'h12, OP_SAR=8'h13,
               OP_ROL=8'h14, OP_ROR=8'h15, OP_ADDI=8'h16, OP_SUBI=8'h17,
               OP_ANDI=8'h18, OP_ORI=8'h19, OP_XORI=8'h1A, OP_MOV=8'h1B,
               OP_SLT=8'h1C, OP_SLTU=8'h1D, OP_LUI=8'h1E,
               OP_BEQ=8'h20, OP_BNE=8'h21, OP_BLT=8'h22, OP_BGE=8'h23,
               OP_BLTU=8'h24, OP_BGEU=8'h25, OP_JMPREG=8'h26,
               OP_HALT=8'hFF;

    // Internal ALU op codes
    localparam A_ADD=4'd0,A_SUB=4'd1,A_MUL=4'd2,A_AND=4'd3,A_OR=4'd4,A_XOR=4'd5,
               A_NOT=4'd6,A_SHL=4'd7,A_SHR=4'd8,A_SAR=4'd9,A_ROL=4'd10,A_ROR=4'd11,
               A_SLT=4'd12,A_SLTU=4'd13,A_EQ=4'd14,A_LUI=4'd15;

    // Branch/jump types
    localparam BR_NONE=4'd0,BR_BEQ=4'd1,BR_BNE=4'd2,BR_BLT=4'd3,BR_BGE=4'd4,
               BR_BLTU=4'd5,BR_BGEU=4'd6,BR_JMP=4'd7,BR_JMPIF=4'd8,BR_JMPREG=4'd9;

    // Flag write modes
    localparam FM_NONE=2'd0, FM_ZN=2'd1, FM_ZNCV=2'd2, FM_Z=2'd3;

    // Address-source select for memory ops
    localparam AS_DIRECT=2'd0, AS_RS1=2'd1, AS_RS2=2'd2;

    // ==========================================================
    // PSR (flags): bit0=Z bit1=N bit2=C bit3=V
    // ==========================================================
    reg [3:0] psr;

    // ==========================================================
    // Global stall / flush
    // ==========================================================
    wire stall;
    wire flush;

    // ==========================================================
    // IF stage
    // ==========================================================
    reg  [11:0] pc;
    wire [31:0] if_instr;
    wire        if_is_halt = (if_instr[31:24] == OP_HALT);

    program_memory u_prog_mem (
        .addr(pc),
        .instr(if_instr)
    );

    assign pc_debug = pc;

    // --------------- IF/ID pipeline register -----------------
    reg [31:0] if_id_instr;
    reg        if_id_valid;

    always @(posedge clk_fast or posedge rst_fast) begin
        if (rst_fast) begin
            if_id_instr <= 32'd0;
            if_id_valid <= 1'b0;
        end else if (stall) begin
            // hold
        end else if (flush) begin
            if_id_instr <= 32'd0;   // NOP
            if_id_valid <= 1'b0;
        end else begin
            if_id_instr <= if_instr;
            if_id_valid <= 1'b1;
        end
    end

    // ==========================================================
    // ID stage: decode
    // ==========================================================
    wire [7:0] id_opcode = if_id_instr[31:24];
    wire [3:0] id_rd_fld = if_id_instr[23:20];
    wire [3:0] id_rs1_fld = if_id_instr[19:16];
    wire [3:0] id_rs2_fld = if_id_instr[15:12];
    wire [11:0] id_imm12  = if_id_instr[11:0];

    reg        d_regwrite, d_memread, d_memwrite, d_use_imm, d_imm_sign;
    reg        d_force_a_zero, d_force_b_zero, d_halt, d_store_src_is_rd;
    reg [3:0]  d_alu_op;
    reg [3:0]  d_branch_type;
    reg [1:0]  d_flag_mode;
    reg [1:0]  d_addr_sel;

    always @* begin
        // defaults: NOP
        d_regwrite = 1'b0; d_memread = 1'b0; d_memwrite = 1'b0;
        d_use_imm = 1'b0; d_imm_sign = 1'b0;
        d_force_a_zero = 1'b0; d_force_b_zero = 1'b0; d_halt = 1'b0;
        d_store_src_is_rd = 1'b0;
        d_alu_op = A_ADD; d_branch_type = BR_NONE; d_flag_mode = FM_NONE;
        d_addr_sel = AS_DIRECT;

        case (id_opcode)
            OP_NOP: ; // all defaults
            OP_LOAD: begin d_regwrite=1; d_memread=1; d_addr_sel=AS_DIRECT; end
            OP_LOADI: begin d_regwrite=1; d_memread=1; d_addr_sel=AS_RS1; end
            OP_LOADIMM: begin d_regwrite=1; d_use_imm=1; d_imm_sign=0; d_force_a_zero=1; d_alu_op=A_ADD; end
            OP_STORE: begin d_memwrite=1; d_addr_sel=AS_DIRECT; d_store_src_is_rd=1; end
            OP_STOREI: begin d_memwrite=1; d_addr_sel=AS_RS2; d_store_src_is_rd=1; end
            OP_ADD:  begin d_regwrite=1; d_alu_op=A_ADD; d_flag_mode=FM_ZNCV; end
            OP_SUB:  begin d_regwrite=1; d_alu_op=A_SUB; d_flag_mode=FM_ZNCV; end
            OP_MUL:  begin d_regwrite=1; d_alu_op=A_MUL; d_flag_mode=FM_ZN; end
            OP_AND:  begin d_regwrite=1; d_alu_op=A_AND; d_flag_mode=FM_ZN; end
            OP_OR:   begin d_regwrite=1; d_alu_op=A_OR;  d_flag_mode=FM_ZN; end
            OP_NOT:  begin d_regwrite=1; d_alu_op=A_NOT; d_flag_mode=FM_ZN; end
            OP_CMP:  begin d_alu_op=A_SUB; d_flag_mode=FM_ZNCV; end
            OP_EQ:   begin d_regwrite=1; d_alu_op=A_EQ;  d_flag_mode=FM_Z; end
            OP_JMP:    d_branch_type = BR_JMP;
            OP_JMPIF:  d_branch_type = BR_JMPIF;
            OP_XOR:  begin d_regwrite=1; d_alu_op=A_XOR; d_flag_mode=FM_ZN; end
            OP_SHL:  begin d_regwrite=1; d_alu_op=A_SHL; d_flag_mode=FM_ZN; end
            OP_SHR:  begin d_regwrite=1; d_alu_op=A_SHR; d_flag_mode=FM_ZN; end
            OP_SAR:  begin d_regwrite=1; d_alu_op=A_SAR; d_flag_mode=FM_ZN; end
            OP_ROL:  begin d_regwrite=1; d_alu_op=A_ROL; d_flag_mode=FM_ZN; end
            OP_ROR:  begin d_regwrite=1; d_alu_op=A_ROR; d_flag_mode=FM_ZN; end
            OP_ADDI: begin d_regwrite=1; d_use_imm=1; d_imm_sign=1; d_alu_op=A_ADD; d_flag_mode=FM_ZNCV; end
            OP_SUBI: begin d_regwrite=1; d_use_imm=1; d_imm_sign=1; d_alu_op=A_SUB; d_flag_mode=FM_ZNCV; end
            OP_ANDI: begin d_regwrite=1; d_use_imm=1; d_imm_sign=0; d_alu_op=A_AND; d_flag_mode=FM_ZN; end
            OP_ORI:  begin d_regwrite=1; d_use_imm=1; d_imm_sign=0; d_alu_op=A_OR;  d_flag_mode=FM_ZN; end
            OP_XORI: begin d_regwrite=1; d_use_imm=1; d_imm_sign=0; d_alu_op=A_XOR; d_flag_mode=FM_ZN; end
            OP_MOV:  begin d_regwrite=1; d_alu_op=A_ADD; d_force_b_zero=1; end
            OP_SLT:  begin d_regwrite=1; d_alu_op=A_SLT;  d_flag_mode=FM_Z; end
            OP_SLTU: begin d_regwrite=1; d_alu_op=A_SLTU; d_flag_mode=FM_Z; end
            OP_LUI:  begin d_regwrite=1; d_use_imm=1; d_imm_sign=0; d_alu_op=A_LUI; end
            OP_BEQ:   d_branch_type = BR_BEQ;
            OP_BNE:   d_branch_type = BR_BNE;
            OP_BLT:   d_branch_type = BR_BLT;
            OP_BGE:   d_branch_type = BR_BGE;
            OP_BLTU:  d_branch_type = BR_BLTU;
            OP_BGEU:  d_branch_type = BR_BGEU;
            OP_JMPREG: d_branch_type = BR_JMPREG;
            OP_HALT:  d_halt = 1'b1;
            default: ; // unrecognized -> behaves as NOP
        endcase

        if (!if_id_valid) begin
            // bubble: force completely inert regardless of opcode bits
            d_regwrite=0; d_memread=0; d_memwrite=0; d_branch_type=BR_NONE; d_halt=0;
        end
    end

    // Register read address selection (STORE/STORE_IND source is the "Rd" field)
    wire [3:0] id_ra1 = (id_opcode == OP_STORE || id_opcode == OP_STOREI) ? id_rd_fld : id_rs1_fld;
    wire [3:0] id_ra2 = id_rs2_fld;

    wire [31:0] id_rs1_data, id_rs2_data;

    // ==========================================================
    // WB stage signals declared early (regfile needs them)
    // ==========================================================
    wire        wb_regwrite;
    wire [3:0]  wb_rd_addr;
    wire [31:0] wb_data;

    regfile u_regfile (
        .clk(clk_fast), .rst(rst_fast),
        .ra1(id_ra1), .ra2(id_ra2),
        .wa(wb_rd_addr), .we(wb_regwrite), .wd(wb_data),
        .rd1(id_rs1_data), .rd2(id_rs2_data)
    );

    // --------------- ID/EX pipeline register -----------------
    reg        ex_regwrite, ex_memread, ex_memwrite, ex_use_imm, ex_imm_sign;
    reg        ex_force_a_zero, ex_force_b_zero, ex_halt, ex_store_src_is_rd;
    reg [3:0]  ex_alu_op;
    reg [3:0]  ex_branch_type;
    reg [1:0]  ex_flag_mode;
    reg [1:0]  ex_addr_sel;
    reg [3:0]  ex_rd_addr, ex_rs1_addr, ex_rs2_addr;
    reg [31:0] ex_rs1_data, ex_rs2_data;
    reg [11:0] ex_imm12;

    always @(posedge clk_fast or posedge rst_fast) begin
        if (rst_fast) begin
            ex_regwrite<=0; ex_memread<=0; ex_memwrite<=0; ex_halt<=0;
            ex_branch_type<=BR_NONE;
        end else if (stall) begin
            // hold
        end else if (flush) begin
            ex_regwrite<=0; ex_memread<=0; ex_memwrite<=0; ex_halt<=0;
            ex_branch_type<=BR_NONE;
        end else begin
            ex_regwrite<=d_regwrite; ex_memread<=d_memread; ex_memwrite<=d_memwrite;
            ex_use_imm<=d_use_imm; ex_imm_sign<=d_imm_sign;
            ex_force_a_zero<=d_force_a_zero; ex_force_b_zero<=d_force_b_zero;
            ex_halt<=d_halt; ex_store_src_is_rd<=d_store_src_is_rd;
            ex_alu_op<=d_alu_op; ex_branch_type<=d_branch_type;
            ex_flag_mode<=d_flag_mode; ex_addr_sel<=d_addr_sel;
            ex_rd_addr<=id_rd_fld; ex_rs1_addr<=id_ra1; ex_rs2_addr<=id_ra2;
            ex_rs1_data<=id_rs1_data; ex_rs2_data<=id_rs2_data;
            ex_imm12<=id_imm12;
        end
    end

    // ==========================================================
    // EX stage
    // ==========================================================

    // ---- forwarding ----
    wire [31:0] ex_mem_fwd_data;  // defined below once EX/MEM + cache signals exist
    wire        ex_mem_regwrite_w;
    wire [3:0]  ex_mem_rd_addr_w;

    wire fwdA_exmem = ex_mem_regwrite_w && (ex_mem_rd_addr_w != 4'd0 || 1'b1) && (ex_mem_rd_addr_w == ex_rs1_addr);
    wire fwdA_memwb = wb_regwrite && (wb_rd_addr == ex_rs1_addr);
    wire fwdB_exmem = ex_mem_regwrite_w && (ex_mem_rd_addr_w == ex_rs2_addr);
    wire fwdB_memwb = wb_regwrite && (wb_rd_addr == ex_rs2_addr);

    wire [31:0] ex_a_fwd = fwdA_exmem ? ex_mem_fwd_data : (fwdA_memwb ? wb_data : ex_rs1_data);
    wire [31:0] ex_b_fwd = fwdB_exmem ? ex_mem_fwd_data : (fwdB_memwb ? wb_data : ex_rs2_data);

    wire [31:0] ex_imm_ext = ex_imm_sign ? {{20{ex_imm12[11]}}, ex_imm12} : {20'd0, ex_imm12};

    wire [31:0] ex_a = ex_force_a_zero ? 32'd0 : ex_a_fwd;
    wire [31:0] ex_b_premux = ex_use_imm ? ex_imm_ext : ex_b_fwd;
    wire [31:0] ex_b = ex_force_b_zero ? 32'd0 : ex_b_premux;

    wire [31:0] alu_result;
    wire        alu_z, alu_n, alu_c, alu_v;

    alu u_alu (
        .a(ex_a), .b(ex_b), .op(ex_alu_op),
        .result(alu_result), .z(alu_z), .n(alu_n), .c(alu_c), .v(alu_v)
    );

    // Effective address for memory ops
    wire [13:0] ex_ea = (ex_addr_sel == AS_DIRECT) ? {2'b00, ex_imm12} :
                        (ex_addr_sel == AS_RS2)    ? ex_b_fwd[13:0]   :
                                                      ex_a_fwd[13:0];
    wire [31:0] ex_store_data = ex_a_fwd;   // STORE/STORE_IND source rides the A bus

    // Branch condition
    reg branch_cond;
    always @* begin
        case (ex_branch_type)
            BR_BEQ:    branch_cond = psr[0];
            BR_BNE:    branch_cond = ~psr[0];
            BR_BLT:    branch_cond = psr[1] ^ psr[3];
            BR_BGE:    branch_cond = ~(psr[1] ^ psr[3]);
            BR_BLTU:   branch_cond = ~psr[2];
            BR_BGEU:   branch_cond = psr[2];
            BR_JMP:    branch_cond = 1'b1;
            BR_JMPIF:  branch_cond = (ex_a_fwd != 32'd0);
            BR_JMPREG: branch_cond = 1'b1;
            default:   branch_cond = 1'b0;
        endcase
    end
    wire branch_taken = branch_cond && (ex_branch_type != BR_NONE);
    wire [11:0] branch_target = (ex_branch_type == BR_JMPREG) ? ex_a_fwd[11:0] : ex_imm12;

    assign flush = branch_taken && !stall;

    // --------------- EX/MEM pipeline register -----------------
    reg        mem_regwrite, mem_memread, mem_memwrite, mem_halt;
    reg [3:0]  mem_rd_addr;
    reg [31:0] mem_alu_result, mem_store_data;
    reg [13:0] mem_ea;

    always @(posedge clk_fast or posedge rst_fast) begin
        if (rst_fast) begin
            mem_regwrite<=0; mem_memread<=0; mem_memwrite<=0; mem_halt<=0;
        end else if (stall) begin
            // hold EX/MEM: keep driving the same request until cache finishes
        end else begin
            mem_regwrite<=ex_regwrite; mem_memread<=ex_memread; mem_memwrite<=ex_memwrite;
            mem_halt<=ex_halt;
            mem_rd_addr<=ex_rd_addr;
            mem_alu_result<=alu_result;
            mem_store_data<=ex_store_data;
            mem_ea<=ex_ea;

            // PSR update happens here conceptually "in EX", gated the same way
        end
    end

    // PSR update (separate always block, same gating as EX/MEM capture)
    always @(posedge clk_fast or posedge rst_fast) begin
        if (rst_fast) begin
            psr <= 4'd0;
        end else if (!stall) begin
            case (ex_flag_mode)
                FM_ZNCV: psr <= {alu_v, alu_c, alu_n, alu_z};
                FM_ZN:   psr <= {psr[3], psr[2], alu_n, alu_z};
                FM_Z:    psr <= {psr[3], psr[2], psr[1], alu_z};
                default: psr <= psr;
            endcase
        end
    end

    // ==========================================================
    // MEM stage: talk to cache (and, through it, the CDC bridge
    // and slow-domain main memory) — the ONLY path to memory.
    // ==========================================================
    localparam MS_IDLE = 1'b0, MS_WAIT = 1'b1;
    reg mem_state;

    wire mem_op = mem_memread | mem_memwrite;
    wire cpu_req_pulse = (mem_state == MS_IDLE) && mem_op;

    wire        cache_cpu_done;
    wire [31:0] cache_cpu_rdata;

    always @(posedge clk_fast or posedge rst_fast) begin
        if (rst_fast) begin
            mem_state <= MS_IDLE;
        end else begin
            case (mem_state)
                MS_IDLE: if (mem_op) mem_state <= MS_WAIT;
                MS_WAIT: if (cache_cpu_done) mem_state <= MS_IDLE;
                default: mem_state <= MS_IDLE;
            endcase
        end
    end

    assign stall = mem_op && !(mem_state == MS_WAIT && cache_cpu_done);

    cpu_lite_mem_system_top #(
        .ADDR_W(14), .INDEX_W(6), .DATA_W(32), .FIFO_AW(4)
    ) u_mem_system (
        .clk_fast  (clk_fast),  .rst_fast(rst_fast),
        .clk_slow  (clk_slow),  .rst_slow(rst_slow),
        .cpu_req   (cpu_req_pulse),
        .cpu_we    (mem_memwrite),
        .cpu_addr  (mem_ea),
        .cpu_wdata (mem_store_data),
        .cpu_rdata (cache_cpu_rdata),
        .cpu_done  (cache_cpu_done)
    );

    // EX/MEM forward value: for a load, forward the just-returned
    // cache data, not the (address-only) alu_result field.
    assign ex_mem_fwd_data   = mem_memread ? cache_cpu_rdata : mem_alu_result;
    assign ex_mem_regwrite_w = mem_regwrite;
    assign ex_mem_rd_addr_w  = mem_rd_addr;

    // Only meaningful once a memory op has actually completed (or
    // isn't one) — during the wait, the stall prevents anything
    // from latching this value, so its transient state is harmless.
    wire mem_commit = !mem_op || (mem_state == MS_WAIT && cache_cpu_done);

    // --------------- MEM/WB pipeline register -----------------
    reg        wb_regwrite_r, wb_halt_r;
    reg [3:0]  wb_rd_addr_r;
    reg [31:0] wb_data_r;

    always @(posedge clk_fast or posedge rst_fast) begin
        if (rst_fast) begin
            wb_regwrite_r <= 0; wb_halt_r <= 0;
        end else if (!mem_commit) begin
            // memory op still in flight: WB gets a bubble this cycle
            wb_regwrite_r <= 0;
        end else begin
            wb_regwrite_r <= mem_regwrite;
            wb_halt_r     <= mem_halt;
            wb_rd_addr_r  <= mem_rd_addr;
            wb_data_r     <= mem_memread ? cache_cpu_rdata : mem_alu_result;
        end
    end

    assign wb_regwrite = wb_regwrite_r;
    assign wb_rd_addr  = wb_rd_addr_r;
    assign wb_data     = wb_data_r;
    assign halted       = wb_halt_r;

    // ==========================================================
    // PC update
    // ==========================================================
    always @(posedge clk_fast or posedge rst_fast) begin
        if (rst_fast) begin
            pc <= 12'd0;
        end else if (stall) begin
            // hold
        end else if (flush) begin
            pc <= branch_target;
        end else if (if_is_halt) begin
            pc <= pc;   // stop fetching once HALT is seen
        end else begin
            pc <= pc + 12'd1;
        end
    end

endmodule