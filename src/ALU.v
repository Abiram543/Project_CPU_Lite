`include "Opcode.vh"
`include "params.vh"

module ALU (
    input wire [`WIDTH-1:0]   op1,    // from the Instr. Decode unit
    input wire [`WIDTH-1:0]   op2,
    input wire [`OPWIDTH-1:0] opcode, 
    
    output reg [`WIDTH-1:0]   ALU_out,
    output reg Z, C, N, V
);

always @(*) begin
    // Default Value
    ALU_out = 'b0;
            Z = 0;
            N = 0;
            C = 0;
            V = 0;
    case (opcode)
        `ADD, `ADDI: begin
            {C, ALU_out} = op1 + op2;
            Z = !ALU_out ? 1 : 0;
            V = ~(op1[WIDTH-1] ^ op2[WIDTH-1]) & (op1[WIDTH-1] ^ ALU_out[WIDTH-1]);
            N = ALU_out[WIDTH-1];
        end   
        `SUB, `SUBI: begin
            {C, ALU_out} = op1 - op2;
            Z = !ALU_out ? 1 : 0;
            V = (op1[WIDTH-1] ^ op2[WIDTH-1]) & (op1[WIDTH-1] ^ ALU_out[WIDTH-1]);
            N = ALU_out[WIDTH-1];
        end
        `MUL: begin
            ALU_out = (op1 * op2);
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `AND, `ANDI: begin
            ALU_out = op1 & op2;
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `OR, `ORI: begin
            ALU_out = op1 | op2;
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `NOT: begin
            ALU_out = ~op1;
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `EQ: begin
            ALU_out = (op1 == op2);
            Z = !ALU_out ? 1 : 0;
        end
        `SHL: begin
            ALU_out = (op1 << op2[`LOG2_WIDTH-1:0]);
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `SHR: begin
            ALU_out = (op1 >> op2[`LOG2_WIDTH-1:0]);
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `SAR: begin
            ALU_out = ($signed(op1) >>> op2[`LOG2_WIDTH-1:0]);
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `XOR, `XORI: begin
            ALU_out = op1 ^ op2;
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `ROR: begin
            ALU_out = (op1 << op2[`LOG2_WIDTH-1:0]) | (op1 >> (`WIDTH - op2[`LOG2_WIDTH-1:0]));
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `ROL: begin
            ALU_out = (op1 >> op2[`LOG2_WIDTH-1:0]) | (op1 << (`WIDTH - op2[`LOG2_WIDTH-1:0]));
            Z = !ALU_out ? 1 : 0;
            N = ALU_out[WIDTH-1];
        end
        `MOV: begin
            ALU_out = op1;
        end
        `SLT: begin
            ALU_out = ($signed(op1) < $signed(op2));
            Z = !ALU_out ? 1 : 0;
        end
        `SLTU: begin
            ALU_out = (op1 < op2);
            Z = !ALU_out ? 1 : 0;
        end
        `LUI: begin
            ALU_out = op2;  // <-- {IMM, 20'b0}
        end
        `LOAD_IMM: begin
            ALU_out = op2;  // <--- {20'b0, IMM}
        end
        default: begin
            ALU_out = 'b0;
            Z = 0;
            N = 0;
            C = 0;
            V = 0;
        end 
    endcase
end
    
endmodule