`include "params.vh"

module IF_ID_Pipe (
    input wire clk_cpu,
    input wire rstn_cpu,

    input wire [`INS_WIDTH-1:0] IF_Instr,   // From IF_Stage
    input wire [`LOG2_PMEMDEPTH-1:0] IF_PC, // From IF_Stage 

    input wire stall,   // From Memory controller
    input wire flush,   // From Branch Controller
    input wire [`LOG2_PMEMDEPTH-1:0] Branch_target, // From ID_Stage
    input wire is_halted,   // From IF_stage

    // Outputs of the IF_ID Pipereg
    output reg [`INS_WIDTH-1:0] IF_ID_Instr,
    output reg IF_ID_Instr_valid,
    output reg [`LOG2_PMEMDEPTH-1:0] IF_ID_PC  // Goes to Pc
);

always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        IF_ID_Instr <= 'd0;
        IF_ID_Instr_valid <= 'd0;
    end
    else if (is_halted) begin
        IF_ID_Instr <= 'd0;
        IF_ID_Instr_valid <= 'd0;
    end
    else if (stall) begin
        // stall the operation
        IF_ID_Instr <= IF_ID_Instr;
        IF_ID_Instr_valid <= IF_ID_Instr_valid;
    end
    else if (flush) begin
        if (Branch_target == IF_PC) begin      // If the Branch Address is exactly the next PC addr.
            IF_ID_Instr <= IF_ID_Instr;         // No Need of flush the pipe
            IF_ID_Instr_valid <= IF_ID_Instr_valid;
        end
        else begin
            IF_ID_Instr <= 'd0;
            IF_ID_Instr_valid <= 'd0; 
        end
    end
    else begin
        IF_ID_Instr <= IF_Instr;
        IF_ID_Instr_valid <= 1'd1;
    end
end

// IF_ID_PC Logic
always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        IF_ID_PC <= 'd0;
    end
    else begin
        IF_ID_PC <= IF_PC;
    end
end

endmodule
