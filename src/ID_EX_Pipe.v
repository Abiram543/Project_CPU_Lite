`include "params.vh"

module ID_EX_Pipe (
    input wire clk_cpu,
    input wire rstn_cpu,

    input wire flush,   // From Branch Controller
    input wire stall,   // From Memory Controller

    input wire fwd_yes, // From Forwarding control logic

    // From ID_stage
    input wire [`OPWIDTH-1:0] ID_opcode,   
    input wire [`LOG2_NofR-1:0] ID_Rd_Addr,
    input wire [`IMM_WIDTH-1:0] ID_IMM_Val,
    input wire [`WIDTH-1:0] Rs1_data, Rs2_data,

    output reg [`OPWIDTH-1:0] ID_EX_opcode,
    output reg [`LOG2_NofR-1:0] ID_EX_Rd_Addr,
    output reg [`IMM_WIDTH-1:0] ID_EX_IMM_Val,
    output reg [`WIDTH-1:0] ID_EX_Rs1_data, ID_EX_Rs2_data

);

always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        ID_EX_opcode <= 'd0;
        ID_EX_Rd_Addr <= 'd0;
        ID_EX_IMM_Val <= 'd0;
        ID_EX_Rs1_data <= 'd0;
        ID_EX_Rs2_data <= 'd0;
    end
    else if (stall) begin
        ID_EX_opcode <= ID_EX_opcode;
        ID_EX_Rd_Addr <= ID_EX_Rd_Addr;
        ID_EX_IMM_Val <= ID_EX_IMM_Val;
        ID_EX_Rs1_data <= ID_EX_Rs1_data;
        ID_EX_Rs2_data <= ID_EX_Rs2_data;
    end
    else if (flush) begin
        ID_EX_opcode <= 'd0;
        ID_EX_Rd_Addr <= 'd0;
        ID_EX_IMM_Val <= 'd0;
        ID_EX_Rs1_data <= 'd0;
        ID_EX_Rs2_data <= 'd0;
    end
    else begin
        ID_EX_opcode <= ID_opcode;
        ID_EX_Rd_Addr <= ID_Rd_Addr;
        ID_EX_IMM_Val <= ID_IMM_Val;
        ID_EX_Rs1_data <= Rs1_data;
        ID_EX_Rs2_data <= Rs2_data;
    end
end

endmodule
