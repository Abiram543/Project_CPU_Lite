`include "params.vh"
module PC (
    input wire clk,
    input wire rstn,    // Asynchronous Active low reset
    
    input wire stall,
    input wire flush,
    input wire is_halted,   // From IF_ID Pipe

    input wire [`LOG2_PMEMDEPTH-1:0] Branch_target,

    output reg [`LOG2_PMEMDEPTH-1:0] PC_val     // Goes to Instruction memory
);

reg [`LOG2_PMEMDEPTH-1:0] Next_PC_val;

// Current PC logic
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        PC_val <= 'b0;
    end
    else if (is_halted) begin
        PC_val <= PC_val;
    end
    else begin
        PC_val <= Next_PC_val;
    end
end

// Next PC_val logic
always @(*) begin
    if (stall) begin
        Next_PC_val = PC_val;
    end
    else if (flush) begin
        if (Branch_target != (PC_val + 1)) begin
            Next_PC_val = Branch_target;
        end
        else Next_PC_val = PC_val + 1;
    end
    else Next_PC_val = PC_val + 1;
end
    
endmodule
