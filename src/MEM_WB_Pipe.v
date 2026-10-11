`include "params.vh"

module MEM_WB_Pipe (
    input wire clk_cpu,
    input wire rstn_cpu,

    input wire stall,
    input wire [`WIDTH-1:0] MEM_data_out,
    input wire [`LOG2_NofR-1:0] MEM_Rd_Addr,
    input wire MEM_is_store_op,

    output reg [`LOG2_NofR-1:0] MEM_WB_Rd_Addr,
    output reg [`WIDTH-1:0] MEM_WB_Rd_data,
    output reg MEM_WB_is_store_op
);

always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        MEM_WB_Rd_Addr <= 'd0;
        MEM_WB_Rd_data <= 'd0;
        MEM_WB_is_store_op <= 'd0;
    end
    else if (stall) begin
        MEM_WB_Rd_Addr <= MEM_WB_Rd_Addr;
        MEM_WB_Rd_data <= MEM_WB_Rd_data;
        MEM_WB_is_store_op <= MEM_WB_is_store_op;
    end
    else begin
        MEM_WB_Rd_Addr <= MEM_Rd_Addr;
        MEM_WB_Rd_data <= MEM_data_out;
        MEM_WB_is_store_op <= MEM_is_store_op;
    end
end

endmodule
