`include "params.vh"

module Stack_Mem (
    input wire clk,
    input wire rstn,
    input wire push, 
    input wire pop,
    input wire [`LOG2_PMEMDEPTH-1:0] Data_in,   // Address has to save during CALL Instruction

    output reg [`LOG2_PMEMDEPTH-1:0] Data_out,   // RET Address which has to drive PC when the Sub-Routine Finishes 
    output reg Overflow
);

reg [`LOG2_PMEMDEPTH-1:0] Stack_Mem [`STMDEPTH-1:0];

reg [`LOG2_STMDEPTH-1:0] SP;    // Stack Pointer

wire OVF, EMT;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        SP <= 'b0;
        Overflow <= 'b0;
        Data_out <= 'b0;
    end
    else if(push && OVF) begin // Overflow happens when SP == 1023
        Overflow <= 1'b1;
    end
    else if (push) begin
        Stack_Mem[SP] <= Data_in;
        SP <= SP + 1'b1;
    end
    else if (pop && !EMT) begin
        Data_out <= Stack_Mem[SP-1];
        SP <= SP - 1'b1;
    end
end

assign OVF = (SP == `STMDEPTH-1);
assign EMT = (SP == 0);
endmodule