`include "Opcode.vh"
`include "params.vh"

module ALU (
    input wire [`WIDTH-1:0]   op1,    // from the Instr. Decode unit
    input wire [`WIDTH-1:0]   op2,
    input wire [`OPWIDTH-1:0] opcode, 
    
    output reg [`WIDTH-1:0]   ALU_out,
    output reg Zero, Carry, Neg, OV
);

localparam OP_NOP       = 8'h00,
           OP_LOAD      = 8'h01,
           OP_LOAD_IND  = 8'h02,
           OP_LOAD_IMM  = 8'h03,
           OP_STORE     = 8'h04,
           OP_STORE_IND = 8'h05,
           OP_ADD       = 8'h06,
           OP_SUB       = 8'h07,
           OP_MUL       = 8'h08,
           OP_AND       = 8'h09,
           OP_OR        = 8'h0A,
           OP_NOT       = 8'h0B,
           OP_CMP       = 8'h0C,
           OP_EQ        = 8'h0D,
           OP_ADDI      = 8'h16,
           OP_SUBI      = 8'h17,
           OP_SHL       = 8'h11,
           OP_SHR       = 8'h12,
           OP_SAR       = 8'h13,
           OP_JMP       = 8'h0E,
           OP_JMP_IF    = 8'h0F,
           OP_BEQ       = 8'h20,
           OP_BNE       = 8'h21,
           OP_BLT       = 8'h22,
           OP_BGE       = 8'h23,
           OP_XOR       = 8'h10,
           OP_ROL       = 8'h14,
           OP_ROR       = 8'h15,
           OP_ANDI      = 8'h18,
           OP_ORI       = 8'h19,
           OP_XORI      = 8'h1A,
           OP_MOV       = 8'h1B,
           OP_SLT       = 8'h1C,
           OP_SLTU      = 8'h1D,
           OP_LUI       = 8'h1E,
           OP_BLTU      = 8'h24,
           OP_JMP_REG   = 8'h26,
           OP_CALL      = 8'h27,
           OP_RET       = 8'h28,
           OP_HALT      = 8'hFF;

wire [`WIDTH-1:0] shamt;
assign shamt = {{(`WIDTH-`LOG2_WIDTH){1'b0}}, op2[`LOG2_WIDTH-1:0]};

always @(*) begin
    // Default Value
    ALU_out = 'b0;
            Zero = 0;
            Neg = 0;
            Carry = 0;
            OV = 0;
    case (opcode)
        OP_ADD, OP_ADDI: begin
            {Carry, ALU_out} = op1 + op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            OV = ~(op1[`WIDTH-1] ^ op2[`WIDTH-1]) & (op1[`WIDTH-1] ^ ALU_out[`WIDTH-1]);
            Neg = ALU_out[`WIDTH-1];
        end   
        OP_SUB, OP_SUBI: begin
            {Carry, ALU_out} = op1 - op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            OV = (op1[`WIDTH-1] ^ op2[`WIDTH-1]) & (op1[`WIDTH-1] ^ ALU_out[`WIDTH-1]);
            Neg = ALU_out[`WIDTH-1];
        end
        OP_MUL: begin
            ALU_out = (op1 * op2);
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_AND, OP_ANDI: begin
            ALU_out = op1 & op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_OR, OP_ORI: begin
            ALU_out = op1 | op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_NOT: begin
            ALU_out = ~op1;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_EQ: begin
            ALU_out = (op1 == op2) ? 1'd1 : 0;
            Zero = (ALU_out == 0) ? 1 : 0;
        end
        OP_SHL: begin
            ALU_out = (op1 << shamt);
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_SHR: begin
            ALU_out = (op1 >> shamt);
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_SAR: begin
            ALU_out = ($signed(op1) >>> shamt);
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_XOR, OP_XORI: begin
            ALU_out = op1 ^ op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_ROR: begin
            ALU_out = (op1 << shamt) | (op1 >> (`WIDTH - shamt));
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_ROL: begin
            ALU_out = (op1 >> shamt) | (op1 << (`WIDTH - shamt));
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        OP_MOV: begin
            ALU_out = op1;
        end
        OP_SLT: begin
            ALU_out = ($signed(op1) < $signed(op2)) ? 1'd1 : 0;
            Zero = (ALU_out == 0) ? 1 : 0;
        end
        OP_SLTU: begin
            ALU_out = (op1 < op2) ? 1'd1 : 0;
            Zero = (ALU_out == 0) ? 1 : 0;
        end
        OP_LUI: begin
            ALU_out = op2;  // <-- {IMM, 20'b0}
        end
        OP_LOAD_IMM: begin
            ALU_out = op2;  // <--- {20'b0, IMM}
        end
        default: begin
            ALU_out = 'b0;
            Zero = 0;
            Neg = 0;
            Carry = 0;
            OV = 0;
        end 
    endcase
end
    
endmodule
