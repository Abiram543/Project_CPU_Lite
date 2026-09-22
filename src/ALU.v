`include "Opcode.vh"
`include "params.vh"

module ALU (
    input wire [`WIDTH-1:0]   op1,    // from the Instr. Decode unit
    input wire [`WIDTH-1:0]   op2,
    input wire [`OPWIDTH-1:0] opcode, 
    
    output reg [`WIDTH-1:0]   ALU_out
);

localparam integer LOG2_WIDTH = $clog2(`WIDTH);

always @(*) begin
    case (opcode)
        `ADD, `ADDI: begin
            ALU_out = op1 + op2;
        end   
        `SUB, `SUBI: begin
            ALU_out = op1 - op2;
        end
        `MUL: begin
            ALU_out = (op1 * op2);
        end
        `AND, `ANDI: begin
            ALU_out = op1 & op2;
        end
        `OR, `ORI: begin
            ALU_out = op1 | op2;
        end
        `NOT: begin
            ALU_out = ~op1;
        end
        `EQ: begin
            ALU_out = (op1 == op2);
        end
        `SHL: begin
            ALU_out = (op1 << op2[LOG2_WIDTH-1:0]);
        end
        `SHR: begin
            ALU_out = (op1 >> op2[LOG2_WIDTH-1:0]);
        end
        `SAR: begin
            ALU_out = ($signed(op1) >>> op2[LOG2_WIDTH-1:0]);
        end
        `XOR, `XORI: begin
            ALU_out = op1 ^ op2;
        end
        `ROR: begin
            ALU_out = (op1 << op2[LOG2_WIDTH-1:0]) | (op1 >> (`WIDTH - op2[LOG2_WIDTH-1:0]));
        end
        `ROL: begin
            ALU_out = (op1 >> op2[LOG2_WIDTH-1:0]) | (op1 << (`WIDTH - op2[LOG2_WIDTH-1:0]));
        end
        `MOV: begin
            ALU_out = op1;
        end
        `SLT: begin
            ALU_out = ($signed(op1) < $signed(op2));
        end
        `SLTU: begin
            ALU_out = (op1 < op2);
        end
        `LUI: begin
            ALU_out = op2;  // <-- {IMM, 20'b0}
        end
        `LOAD_IMM: begin
            ALU_out = op2;  // <--- {20'b0, IMM}
        end
        default: begin
            ALU_out = 'b0;
        end 
    endcase
end
    
endmodule