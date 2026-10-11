`include "../src/params.vh"
`include "Opcode.vh"

module ALU (
    input wire [`WIDTH-1:0]   op1,    // from the Instr. Decode unit
    input wire [`WIDTH-1:0]   op2,
    input wire [`OPWIDTH-1:0] opcode,

    output reg [`WIDTH-1:0]   ALU_out,
    output reg Zero, Carry, Neg, OV
);

reg [`WIDTH-1:0] temp;

wire [`WIDTH-1:0] shamt;
assign shamt = {{(`WIDTH-`LOG2_WIDTH){1'b0}}, op2[`LOG2_WIDTH-1:0]};

wire [(2*`WIDTH)-1:0] mulval;
assign mulval = op1 * op2;

always @(*) begin
    // Default Value
    ALU_out = 'b0;
            Zero = 0;
            Neg = 0;
            Carry = 0;
            OV = 0;
    case (opcode)
        `OP_ADD, `OP_ADDI: begin
            {Carry, ALU_out} = op1 + op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            OV = ~(op1[`WIDTH-1] ^ op2[`WIDTH-1]) & (op1[`WIDTH-1] ^ ALU_out[`WIDTH-1]);
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_SUB, `OP_SUBI: begin
            {Carry, ALU_out} = op1 - op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            OV = (op1[`WIDTH-1] ^ op2[`WIDTH-1]) & (op1[`WIDTH-1] ^ ALU_out[`WIDTH-1]);
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_CMP: begin
            {Carry, temp} = op1 - op2;
            Zero = (temp == 0) ? 1 : 0;
            OV = (op1[`WIDTH-1] ^ op2[`WIDTH-1]) & (op1[`WIDTH-1] ^ temp[`WIDTH-1]);
            Neg = temp[`WIDTH-1];
        end
        `OP_MUL: begin
            ALU_out = mulval[`WIDTH-1:0];
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_AND, `OP_ANDI: begin
            ALU_out = op1 & op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_OR, `OP_ORI: begin
            ALU_out = op1 | op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_NOT: begin
            ALU_out = ~op1;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_EQ: begin
            ALU_out = (op1 == op2) ? 1'd1 : 0;
            Zero = (ALU_out == 0) ? 1 : 0;
        end
        `OP_SHL: begin
            ALU_out = (op1 << shamt);
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_SHR: begin
            ALU_out = (op1 >> shamt);
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_SAR: begin
            ALU_out = $unsigned($signed(op1) >>> shamt);
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_XOR, `OP_XORI: begin
            ALU_out = op1 ^ op2;
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_ROR: begin
            ALU_out = (op1 << shamt) | (op1 >> (`WIDTH - shamt));
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_ROL: begin
            ALU_out = (op1 >> shamt) | (op1 << (`WIDTH - shamt));
            Zero = (ALU_out == 0) ? 1 : 0;
            Neg = ALU_out[`WIDTH-1];
        end
        `OP_SLT: begin
            ALU_out = ($signed(op1) < $signed(op2)) ? 1'd1 : 0;
            Zero = (ALU_out == 0) ? 1 : 0;
        end
        `OP_SLTU: begin
            ALU_out = (op1 < op2) ? 1'd1 : 0;
            Zero = (ALU_out == 0) ? 1 : 0;
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
