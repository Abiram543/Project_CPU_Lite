`include "params.vh"

module WB_stage (
    input wire [`LOG2_NofR-1:0] MEM_WB_Rd_Addr,
    input wire [`WIDTH-1:0] MEM_WB_Rd_data,
    input wire MEM_WB_is_store_op,

    output wire wr_en,
    output wire [`LOG2_NofR-1:0] WB_Rd_Addr,
    output wire [`WIDTH-1:0]WB_Rd_data
);

assign wr_en = !MEM_WB_is_store_op;
assign WB_Rd_Addr = MEM_WB_Rd_Addr;
assign WB_Rd_data = MEM_WB_Rd_data;

endmodule
