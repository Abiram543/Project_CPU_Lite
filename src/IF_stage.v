`include "params.vh"
`include "Opcode.vh"

module IF_stage (
    input wire [`INS_WIDTH-1:0] Instr,    // From Program Memory
    input wire [`LOG2_PMEMDEPTH-1:0] PC, // From PC module

    output wire [`LOG2_PMEMDEPTH-1:0] IF_PC,
    output wire [`INS_WIDTH-1:0] IF_Instr,   // To IF_ID Pipeline
    output wire is_halted   // Goes to IF_ID pipe
);

assign IF_Instr = Instr;
assign IF_PC = PC;
assign is_halted = (IF_Instr[`INS_WIDTH-1:`INS_WIDTH-`OPWIDTH] == `OP_HALT) ? 1'd1 : 'd0;    
endmodule
