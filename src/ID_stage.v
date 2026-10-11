`include "params.vh"
`include "Opcode.vh"

module ID_stage (
    input wire [`INS_WIDTH-1:0] IF_ID_Instr,    // From IF_ID Pipeline reg
    input wire IF_ID_Instr_valid,

    input wire [`WIDTH-1:0] Rs1_val, Rs2_val,   // From Register Files
    // To ID_EX pipe
    output wire [`OPWIDTH-1:0] ID_opcode,   
    output wire [`LOG2_NofR-1:0] ID_Rd_Addr,
    output wire [`LOG2_NofR-1:0] ID_Rs1_Addr, ID_Rs2_Addr,
    output wire [`IMM_WIDTH-1:0] ID_IMM_Val,
    output reg [`WIDTH-1:0] Rs1_data, Rs2_data,
    // Control Signals for which operation need to be performed by EX Stage
    output reg is_load_op, 
    output reg is_store_op, 
    output reg is_alu_op, 
    output reg is_branch_op,
    output reg is_mem_op
);

// Instruction Bit mapping
assign ID_opcode = IF_ID_Instr_valid ? IF_ID_Instr[`INS_WIDTH-1:`INS_WIDTH-`OPWIDTH] : 'd0;   // Opcode {8 bits}
assign ID_Rd_Addr = IF_ID_Instr_valid ? IF_ID_Instr[`INS_WIDTH-`OPWIDTH-1:`INS_WIDTH-`OPWIDTH-`LOG2_NofR] : 'd0;  // Rd Addr {4 bits}
assign ID_Rs1_Addr = IF_ID_Instr_valid ? (((ID_opcode == `OP_STORE)||(ID_opcode == `OP_STORE_IND)) ? (IF_ID_Instr[`INS_WIDTH-`OPWIDTH-1:`INS_WIDTH-`OPWIDTH-`LOG2_NofR]) :   // Rd Addr for Store Operations
                                                                              (IF_ID_Instr[`INS_WIDTH-`OPWIDTH-`LOG2_NofR-1:`INS_WIDTH-`OPWIDTH-(2*`LOG2_NofR)])) : 4'd0;  // Rs1 Addr {4 bits}
assign ID_Rs2_Addr = IF_ID_Instr_valid ? IF_ID_Instr[`INS_WIDTH-`OPWIDTH-(2*`LOG2_NofR)-1:`INS_WIDTH-`OPWIDTH-(3*`LOG2_NofR)] : 'd0;  // Rs2 Addr {4 bits}
assign ID_IMM_Val = IF_ID_Instr_valid ? IF_ID_Instr[`IMM_WIDTH-1:0] : 'd0;    // IMM val {12 bits}

// Data logic based on the opcode
always @(*) begin
    case (ID_opcode)
        `OP_NOP: begin
            Rs1_data = 0;   // No Operation
            Rs2_data = 0;
        end 
        `OP_LOAD: begin
            Rs1_data = {{`INS_WIDTH-`IMM_WIDTH{1'd0}}, ID_IMM_Val};
            Rs2_data = 'd0;
        end
        `OP_LOAD_IND: begin
            Rs1_data = Rs1_val;
            Rs2_data = 'd0;
        end
        `OP_LOAD_IMM: begin
            Rs1_data = {{`INS_WIDTH-`IMM_WIDTH{1'd0}}, ID_IMM_Val};
            Rs2_data = 'd0;
        end
        `OP_STORE: begin
            Rs1_data = Rs1_val;     // This is the source value need to store into mem[ADDR]
            Rs2_data = {{`INS_WIDTH-`IMM_WIDTH{1'd0}}, ID_IMM_Val};       // This is mem Addr val
        end
        `OP_STORE_IND: begin
            Rs1_data = Rs1_val;     // This is source value (Rd) need to store into mem[Rs2]
            Rs2_data = Rs2_val;     // This is Addr value (Rs2 value) for mem address
        end
        `OP_ADD: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;            
        end
        `OP_SUB: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_MUL: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_AND: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_OR: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_NOT: begin
            Rs1_data = Rs1_val;
            Rs2_data = 'd0;
        end
        `OP_CMP: begin
            Rs1_data = Rs1_val; // But No write back to Rd Addr
            Rs2_data = Rs2_val;
        end
        `OP_EQ: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_ADDI: begin
            Rs1_data = Rs1_val;
            Rs2_data = {{`INS_WIDTH-`IMM_WIDTH{ID_IMM_Val[`IMM_WIDTH-1]}}, ID_IMM_Val};     // Sign Extension of IMM Value
        end
        `OP_SUBI: begin
            Rs1_data = Rs1_val;
            Rs2_data = {{`INS_WIDTH-`IMM_WIDTH{ID_IMM_Val[`IMM_WIDTH-1]}}, ID_IMM_Val};     // Sign Extension of IMM Value
        end
        `OP_SHL: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_SHR: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_SAR: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_JMP: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        `OP_JMP_IF: begin
            Rs1_data = Rs1_val;
            Rs2_data = 0;
        end
        `OP_BEQ: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        `OP_BNE: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        `OP_BLT: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        `OP_BGE: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        `OP_XOR: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_ROL: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_ROR: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_ANDI: begin
            Rs1_data = Rs1_val;     
            Rs2_data = {{`INS_WIDTH-`IMM_WIDTH{1'd0}}, ID_IMM_Val};
        end
        `OP_ORI: begin
            Rs1_data = Rs1_val;     
            Rs2_data = {{`INS_WIDTH-`IMM_WIDTH{1'd0}}, ID_IMM_Val};
        end
        `OP_XORI: begin
            Rs1_data = Rs1_val;     
            Rs2_data = {{`INS_WIDTH-`IMM_WIDTH{1'd0}}, ID_IMM_Val};
        end
        `OP_MOV: begin
            Rs1_data = Rs1_val;
            Rs2_data = 0;
        end
        `OP_SLT: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_SLTU: begin
            Rs1_data = Rs1_val;
            Rs2_data = Rs2_val;
        end
        `OP_LUI: begin
            Rs1_data = {ID_IMM_Val, {`INS_WIDTH-`IMM_WIDTH{1'd0}}};
            Rs2_data = 0;
        end
        `OP_BLTU: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        `OP_BGEU: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        `OP_JMP_REG: begin
            Rs1_data = Rs1_val;
            Rs2_data = 0;
        end
        `OP_HALT: begin
            Rs1_data = 0;
            Rs2_data = 0;
        end
        default: begin
            Rs1_data = 0;
            Rs2_data = 0; 
        end
    endcase
end

// Control signals Logic
always @(*) begin
    case (ID_opcode)
        `OP_LOAD, `OP_LOAD_IND, `OP_LOAD_IMM, `OP_LUI, `OP_MOV: begin
            is_load_op = 1;
            is_alu_op = 0;
            is_branch_op = 0;
            is_store_op = 0;
        end
        `OP_STORE, `OP_STORE_IND: begin
            is_load_op = 0;
            is_alu_op = 0;
            is_branch_op = 0;
            is_store_op = 1;
        end
        `OP_ADD, `OP_SUB, `OP_MUL, `OP_AND, `OP_OR, `OP_NOT, `OP_CMP,
        `OP_EQ, `OP_ADDI, `OP_SUBI, `OP_SHL, `OP_SHR, `OP_SAR, `OP_XOR,
        `OP_ROL, `OP_ROR, `OP_ANDI, `OP_ORI, `OP_XORI, `OP_SLTU, `OP_SLT: begin
            is_load_op = 0;
            is_alu_op = 1;
            is_branch_op = 0;
            is_store_op = 0;
        end
        `OP_JMP, `OP_JMP_IF, `OP_BEQ, `OP_BNE, `OP_BLT, 
        `OP_BGE, `OP_BLTU, `OP_BGEU, `OP_JMP_REG: begin
            is_load_op = 0;
            is_alu_op = 0;
            is_branch_op = 1;
            is_store_op = 0;
        end
        default: begin  // NOP, HALT
            is_load_op = 0;
            is_alu_op = 0;
            is_branch_op = 0;
            is_store_op = 0;
        end
    endcase
end

// Memory Control Signals Logic
always @(*) begin
    case (ID_opcode)
        `OP_LOAD, `OP_LOAD_IND, `OP_STORE, `OP_STORE_IND: begin
            is_mem_op = 1'd1;
        end
        default: is_mem_op = 1'd0;
    endcase
end

endmodule
