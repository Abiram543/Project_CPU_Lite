`include "params.vh"

module top_mem (
    input wire clk_cpu,
    input wire rstn_cpu,

    input wire clk_mem,
    input wire rstn_mem,

    // CPU core side ports
    input wire cpu_req,
    input wire cpu_wen, cpu_ren, 
    input wire [(`ADDR_WIDTH)-1:0] cpu_addr,
    input wire [(`WIDTH)-1:0] cpu_wdata,
    output reg [(`WIDTH)-1:0] cpu_rdata,
    output reg cache_done
);
// Connection wires:
wire req_full, req_wr_en, resp_empty, resp_rd_en, req_empty, req_rd_en, resp_full, resp_wr_en; 
wire [(`FIFO_WIDTH)-1:0] req_wr_data, req_rd_data;
wire [(`WIDTH)-1:0] resp_rd_data, resp_wr_data;


// Fast mem -- L1  Cache
L1_cache u_cache(
    .clk_cpu(clk_cpu),
    .rstn_cpu(rstn_cpu),
    .cpu_req(cpu_req),
    .cpu_wen(cpu_wen), 
    .cpu_ren(cpu_ren), 
    .cpu_addr(cpu_addr),
    .cpu_wdata(cpu_wdata),
    .cpu_rdata(cpu_rdata),
    .cache_done(cache_done),
    .req_full(req_full),
    .req_wr_en(req_wr_en),
    .req_wr_data(req_wr_data),
    .resp_empty(resp_empty),
    .resp_rd_en(resp_rd_en),
    .resp_rd_data(resp_rd_data)

);

// CDC -- Req FIFO
fifo_top #(.DATA_WIDTH(`FIFO_WIDTH), .DEPTH(4)) u_reqFIFO(
        .rclk(clk_mem), 
        .rdrstn(rstn_mem),
        .rd_en(req_rd_en),
        .wclk(clk_cpu), 
        .wrstn(rstn_cpu),
        .wr_en(req_wr_en), 
        .Data_in(req_wr_data),
        .full(req_full),
        .empty(req_empty), 
        .Data_out(req_rd_data)
);

// Slow mem -- Main Memory
Main_mem u_mainmem(
    .clk_mem(clk_mem),
    .rstn_mem(rstn_mem),
    .Data_in(req_rd_data),
    .req_empty(req_empty),   
    .req_rd_en(req_rd_en), 
    .resp_full(resp_full),   
    .resp_wr_en(resp_wr_en),  
    .Data_out(resp_wr_data)
);

// CDC -- Resp. FIFO
fifo_top #(.DATA_WIDTH(`WIDTH), .DEPTH(4))u_respFIFO(
        .rclk(clk_cpu), 
        .rdrstn(rstn_cpu), 
        .wclk(clk_mem), 
        .wrstn(rstn_mem),
        .rd_en(resp_rd_en),
        .wr_en(resp_wr_en),
        .Data_in(resp_wr_data),
        .full(resp_full),
        .empty(resp_empty), 
        .Data_out(resp_rd_data)
);

endmodule
