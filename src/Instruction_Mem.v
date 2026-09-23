module Instruction_Mem (
    input wire clk, 
    input wire rstn,
    input wire PC_val,      // From PC [Program Counter]

    output reg [`WIDTH-1:0] Instr
);

reg [`WIDTH-1:0] P_Mem [`PMEMDEPTH-1:0];

initial begin
     $readmemh("programmem.h", P_Mem);
end

assign Instr = P_Mem[PC_val];


endmodule