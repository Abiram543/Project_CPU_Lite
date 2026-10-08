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
    output reg [`WIDTH-1:0] Rs1_data, Rs2_data
);

// Instruction Bit mapping
assign ID_opcode = IF_ID_Instr[`INS_WIDTH-1:`INS_WIDTH-`OPWIDTH];   // Opcode {8 bits}
assign ID_Rd_Addr = IF_ID_Instr[`INS_WIDTH-`OPWIDTH-1:`INS_WIDTH-`OPWIDTH-`Reg_WIDTH];  // Rd Addr {4 bits}
assign ID_Rs1_Addr = IF_ID_Instr[`INS_WIDTH-`OPWIDTH-`Reg_WIDTH-1:`INS_WIDTH-`OPWIDTH-(2*`Reg_WIDTH)];  // Rs1 Addr {4 bits}
assign ID_Rs2_Addr = IF_ID_Instr[`INS_WIDTH-`OPWIDTH-(2*`Reg_WIDTH)-1:`INS_WIDTH-`OPWIDTH-(3*`Reg_WIDTH)];  // Rs2 Addr {4 bits}
assign ID_IMM_Val = IF_ID_Instr[`IMM_WIDTH-1:0];    // IMM val {12 bits}

// Control logic depends on the opcode
always @(*) begin
    case (ID_opcode)
        `OP_NOP: begin
            
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
            
        end
        `OP_STORE_IND: begin
            
        end
        `OP_ADD: begin
            
        end
        `OP_SUB: begin
            
        end
        `OP_MUL: begin
            
        end
        `OP_AND: begin
            
        end
        `OP_OR: begin
            
        end
        `OP_NOT: begin
            
        end
        `OP_CMP: begin
            
        end
        `OP_EQ: begin
            
        end
        `OP_ADDI: begin
            
        end
        `OP_SUBI: begin
            
        end
        `OP_SHL: begin
            
        end
        `OP_SHR: begin
            
        end
        `OP_SAR: begin
            
        end
        `OP_JMP: begin
            
        end
        `OP_JMP_IF: begin
            
        end
        `OP_BEQ: begin
            
        end
        `OP_BNE: begin
            
        end
        `OP_BLT: begin
            
        end
        `OP_BGE: begin
            
        end
        `OP_XOR: begin
            
        end
        `OP_ROL: begin
            
        end
        `OP_ROR: begin
            
        end
        `OP_ANDI: begin
            
        end
        `OP_ORI: begin
            
        end
        `OP_XORI: begin
            
        end
        `OP_MOV: begin
            
        end
        `OP_SLT: begin
            
        end
        `OP_SLTU: begin
            
        end
        `OP_LUI: begin
            
        end
        `OP_BLTU: begin
            
        end
        `OP_JMP_REG: begin
            
        end
        `OP_HALT: begin
            
        end
        default: ;
    endcase
end


// Direct assigning value from Regfiles
assign Rs1_data = Rs1_val;
assign Rs2_data = Rs2_val;

endmodule
