`include "params.vh"

module IF_ID_Pipe (
    input wire clk_cpu,
    input wire rstn_cpu,

    input wire [`INS_WIDTH-1:0] IF_Instr,   // From IF_Stage

    input wire stall,   // From Memory controller
    input wire flush,   // Branch Controller

    output reg [`INS_WIDTH-1:0] IF_ID_Instr,
    output reg IF_ID_Instr_valid
);

always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        IF_ID_Instr <= 'd0;
        IF_ID_Instr_valid <= 'd0;
    end
    else if (stall) begin
        // stall the operation
        IF_ID_Instr <= IF_ID_Instr;
        IF_ID_Instr_valid <= IF_ID_Instr_valid;
    end
    else if (flush) begin
        IF_ID_Instr <= 'd0;
        IF_ID_Instr_valid <= 'd0;
    end
    else begin
        IF_ID_Instr <= IF_Instr;
        IF_ID_Instr_valid <= 1'd1;
    end
end

endmodule
