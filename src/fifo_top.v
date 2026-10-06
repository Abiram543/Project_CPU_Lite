module async_fifo_top #(parameter DATA_WIDTH = 8, DEPTH = 32)(
        input wire rclk, rd_en,
        input wire wclk, wr_en,
        input wire rdrstn, wrstn,
        input wire [DATA_WIDTH-1:0] Data_in,
        output wire full,
        output wire empty, 
        output wire [DATA_WIDTH-1:0] Data_out
);

localparam ADDR_WIDTH = $clog2(DEPTH);

wire [ADDR_WIDTH-1:0] Wr_Addr, Rd_Addr;
wire [ADDR_WIDTH:0] g_rdptr_sync, g_wptr, g_rdptr, g_wptr_sync;


// FIFO Memory
fifo_mem #(.DATA_WIDTH(DATA_WIDTH), .DEPTH(DEPTH), .ADDR_WIDTH(ADDR_WIDTH)) inst1 (.wclk(wclk), .rclk(rclk), .rd_en(rd_en), .wr_en(wr_en), .rdrstn(rdrstn), .Data_in(Data_in), .Data_out(Data_out), .full(full), .empty(empty), .Wr_Addr(Wr_Addr), .Rd_Addr(Rd_Addr));

// Write pointer handler
wr_ptr_handler #(.ADDR_WIDTH(ADDR_WIDTH)) inst2(.wclk(wclk), .wrstn(wrstn), .wr_en(wr_en), .full(full), .g_rdptr_sync(g_rdptr_sync), .b_wptr(Wr_Addr), .g_wptr(g_wptr));

// Read Pointer handler
rd_ptr_handler #(.ADDR_WIDTH(ADDR_WIDTH)) inst3(.rclk(rclk), .rdrstn(rdrstn), .rd_en(rd_en), .empty(empty), .g_wptr_sync(g_wptr_sync), .b_rdptr(Rd_Addr), .g_rdptr(g_rdptr));

// 2FF Synchronizer
ff2_sync #(.ADDR_WIDTH(ADDR_WIDTH+1)) inst4(.clk(rclk), .rstn(rdrstn), .Din(g_wptr), .Syn_out(g_wptr_sync));

ff2_sync #(.ADDR_WIDTH(ADDR_WIDTH+1)) inst5(.clk(wclk), .rstn(wrstn), .Din(g_rdptr), .Syn_out(g_rdptr_sync));

endmodule
