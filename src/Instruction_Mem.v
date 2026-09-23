module Instruction_Mem (
    input wire clk, 
    input wire rstn,
    input wire PC_val,      // From PC [Program Counter]
    input wire I_Rd_en,     // From Control Unit

    output reg [`WIDTH-1:0] Instr
);

reg [`WIDTH-1:0] P_Mem [`PMEMDEPTH-1:0];

initial begin
     $readmemh("programmem.h", P_Mem);
end

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        Instr <= 'hFF000000;    // Halt
    end
    else if (I_Rd_en) begin
        Instr <= P_Mem[PC_val];
    end
end


endmodule