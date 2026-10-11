`include "params.vh"

module EX_MEM_Pipe (
    input wire clk_cpu,
    input wire rstn_cpu,

    input wire stall,

    input wire [`LOG2_NofR-1:0] EX_Rd_Addr,
    input wire [`WIDTH-1:0] EX_Rd_data,
    input wire [`WIDTH-1:0] MEM_Addr,      
    input wire [`WIDTH-1:0] MEM_data,  
    input wire EX_is_load_op, 
    input wire EX_is_store_op,    
    input wire EX_is_mem_op,              

    output reg [`LOG2_NofR-1:0] EX_MEM_Rd_Addr,
    output reg [`WIDTH-1:0] EX_MEM_Rd_data,
    output reg [`WIDTH-1:0] EX_MEM_Addr,
    output reg [`WIDTH-1:0] EX_MEM_data,
    output reg EX_MEM_is_load_op,
    output reg EX_MEM_is_store_op,
    output reg EX_MEM_is_mem_op
);

always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        EX_MEM_Rd_Addr <= 'd0;
        EX_MEM_Rd_data <= 'd0;
        EX_MEM_Addr <= 'd0;
        EX_MEM_data <= 'd0;
        EX_MEM_is_mem_op <= 'd0;
        EX_MEM_is_load_op <= 'd0;
        EX_MEM_is_store_op <= 'd0;
    end
    else if (stall) begin
        EX_MEM_Rd_Addr <= EX_MEM_Rd_Addr;
        EX_MEM_Rd_data <= EX_MEM_Rd_data;
        EX_MEM_Addr <= EX_MEM_Addr;
        EX_MEM_data <= EX_MEM_data;
        EX_MEM_is_mem_op <= EX_MEM_is_mem_op;
        EX_MEM_is_load_op <= EX_MEM_is_load_op;
        EX_MEM_is_store_op <= EX_MEM_is_store_op;
    end
    else begin
        EX_MEM_Rd_Addr <= EX_Rd_Addr;
        EX_MEM_Rd_data <= EX_Rd_data;
        EX_MEM_Addr <= MEM_Addr;
        EX_MEM_data <= MEM_data;
        EX_MEM_is_mem_op <= EX_is_mem_op;
        EX_MEM_is_load_op <= EX_is_load_op;
        EX_MEM_is_store_op <= EX_is_store_op;
    end
end

endmodule
