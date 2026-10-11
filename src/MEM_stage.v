`include "params.vh"

module MEM_stage (
    input wire clk_cpu,
    input wire rstn_cpu,
    input wire clk_mem,
    input wire rstn_mem,

    input wire [`LOG2_NofR-1:0] EX_MEM_Rd_Addr,
    input wire [`WIDTH-1:0] EX_MEM_Rd_data,    
    input wire [`WIDTH-1:0] EX_MEM_Addr,       
    input wire [`WIDTH-1:0] EX_MEM_data,       
    input wire EX_MEM_is_mem_op,   
    input wire EX_MEM_is_load_op,              
    input wire EX_MEM_is_store_op,

    output wire stall,
    output wire [`WIDTH-1:0] MEM_data_out,
    output wire [`LOG2_NofR-1:0] MEM_Rd_Addr,
    output wire MEM_is_store_op
);
wire cache_done, cpu_req, cpu_wen, cpu_ren;
wire [(`ADDR_WIDTH)-1:0] cpu_addr;
wire [`WIDTH-1:0] cpu_rdata, cpu_wdata;

// Stall Logic
assign stall = EX_MEM_is_mem_op && !cache_done;

assign cpu_req = (EX_MEM_is_mem_op && !cache_done) ? 1'd1 : 1'd0;

assign cpu_wen = (EX_MEM_is_mem_op && EX_MEM_is_store_op) ? 1'd1 : 1'd0;
assign cpu_ren = (EX_MEM_is_mem_op && EX_MEM_is_load_op) ? 1'd1 : 1'd0;

assign cpu_addr = EX_MEM_Addr[(`ADDR_WIDTH)-1:0];
assign cpu_wdata = EX_MEM_data;

assign MEM_data_out = (EX_MEM_is_mem_op && cache_done) ? cpu_rdata : !EX_MEM_is_mem_op ? EX_MEM_Rd_data : 'd0;

assign MEM_Rd_Addr = EX_MEM_Rd_Addr;

assign MEM_is_store_op = EX_MEM_is_store_op;

// Memory Interface
top_mem u_top_mem(
    .clk_cpu(clk_cpu),
    .rstn_cpu(rstn_cpu),
    .clk_mem(clk_mem),
    .rstn_mem(rstn_mem),
    .cpu_req(cpu_req),
    .cpu_wen(cpu_wen), 
    .cpu_ren(cpu_ren), 
    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),
    .cpu_rdata(cpu_rdata),
    .cache_done(cache_done)
);

endmodule
