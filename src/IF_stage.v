`include "params.vh"

module IF_stage (
    input wire [`INS_WIDTH-1:0] Instr,    // From Program Memory
    output wire [`INS_WIDTH-1:0] IF_Instr   // To IF_ID Pipeline
);

assign IF_Instr = Instr;
    
endmodule
