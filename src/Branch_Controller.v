`include "params.vh"
`include "Opcode.vh"

module Branch_Controller (
    input wire is_branch_op,    // From ID Stage
    input wire [`OPWIDTH-1:0] ID_opcode,    // From ID Stage
    input wire [`WIDTH-1:0] Rs1_data,   // From ID Stage
    input wire [`IMM_WIDTH-1:0] ID_IMM_Val, // From ID Stage
    input wire [`LOG2_PMEMDEPTH-1:0] IF_ID_PC,  // From IF_ID Pipe

    output reg [`LOG2_PMEMDEPTH-1:0] Branch_target, // Goeas to PC
    output wire flush    // Goes to IF_ID, ID_EX Pipes and PC
);

// BRanch Target logic
always @(*) begin
    if (is_branch_op) begin
        if (ID_opcode == `OP_JMP_REG) begin
            if (Rs1_data != 0) begin
                Branch_target = ID_IMM_Val;
            end
            else begin
                Branch_target = IF_ID_PC + 1;
            end
        end
        else Branch_target = ID_IMM_Val;
    end
    else Branch_target = 'd0;
end

// Flush Logic
assign flush = is_branch_op ? 1'd1 : 1'd0;

endmodule
