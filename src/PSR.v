`include "params.vh"
`include "Opcode.vh"

module PSR (
    input wire clk,
    input wire rstn,
    input wire Zero, Carry, Neg, OV,    // From the ALU
    input wire [`OPWIDTH-1:0] ID_EX_is_load_op,
    // Processor Status Registers
    output reg [3:0] PSR
);
/*
PSR[0] = Zero
PSR[1] = Negative 
PSR[2] = Carry
PSR[3] = Overflow 
*/

localparam AZ = 2'd0,
           ZO = 2'd1,
           ZN = 2'd2,
           ZNCV = 2'd3;

reg [1:0] zncv;

always @(*) begin
    case (ID_EX_is_load_op)
        `OP_ADD, `OP_ADDI, `OP_SUB, `OP_SUBI, `OP_CMP: begin
            zncv = ZNCV;
        end 
        `OP_MUL, `OP_AND, `OP_ANDI, `OP_OR, `OP_ORI, 
        `OP_NOT, `OP_SHL, `OP_SHR, `OP_SAR, `OP_XOR, `OP_XORI,
        `OP_ROR, `OP_ROL: begin
            zncv = ZN;
        end
        `OP_SLT, `OP_SLTU, `OP_EQ: begin
            zncv = ZO;
        end
        default: zncv = AZ;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        PSR <= 'b0;
    end
    else if (zncv == ZNCV) begin
        PSR[0] <= Zero;
        PSR[1] <= Neg;
        PSR[2] <= Carry;
        PSR[3] <= OV;
    end
    else if (zncv == ZN) begin
        PSR[0] <= Zero;
        PSR[1] <= Neg;
    end
    else if (zncv == ZO) begin
        PSR[0] <= Zero;
    end
end

endmodule
