// =============================================================
// cpu_lite_mem_system_top.v
//
// Wires: CPU-side cache (fast domain) <-> 2x async FIFO <-> main
// memory (slow domain). This module's port list exposes ONLY the
// CPU-facing cache interface. There is no signal anywhere in this
// file that connects the fast and slow domains except through
// req_fifo and resp_fifo — exactly the spec's requirement that
// the CDC bridge is the only legal crossing.
// =============================================================
module cpu_lite_mem_system_top #(
    parameter ADDR_W   = 14,
    parameter INDEX_W  = 6,
    parameter DATA_W   = 32,
    parameter FIFO_AW  = 4        // FIFO depth = 2**FIFO_AW entries
)(
    // Fast domain (CPU + cache + program memory live here)
    input  wire               clk_fast,
    input  wire                rst_fast,

    // Slow domain (main data memory lives here)
    input  wire               clk_slow,
    input  wire                rst_slow,

    // CPU <-> cache interface (fast domain only)
    input  wire               cpu_req,
    input  wire               cpu_we,
    input  wire [ADDR_W-1:0]  cpu_addr,
    input  wire [DATA_W-1:0]  cpu_wdata,
    output wire [DATA_W-1:0]  cpu_rdata,
    output wire               cpu_done
);

    localparam REQ_W = 1 + ADDR_W + DATA_W;   // {we, addr, wdata}

    // ---- Cache <-> request FIFO (push side) ----
    wire               req_wr_en;
    wire [REQ_W-1:0]   req_wr_data;
    wire               req_full;

    // ---- Request FIFO (pop side) <-> memory ----
    wire               req_rd_en;
    wire [REQ_W-1:0]   req_rd_data;
    wire               req_empty;

    // ---- Memory <-> response FIFO (push side) ----
    wire               resp_wr_en;
    wire [DATA_W-1:0]  resp_wr_data;
    wire               resp_full;

    // ---- Response FIFO (pop side) <-> cache ----
    wire               resp_rd_en;
    wire [DATA_W-1:0]  resp_rd_data;
    wire               resp_empty;

    // =========================================================
    // Cache: entirely in the fast domain
    // =========================================================
    l1_cache_writeback #(
        .ADDR_W(ADDR_W), .INDEX_W(INDEX_W), .DATA_W(DATA_W)
    ) u_cache (
        .clk          (clk_fast),
        .rst          (rst_fast),

        .cpu_req      (cpu_req),
        .cpu_we       (cpu_we),
        .cpu_addr     (cpu_addr),
        .cpu_wdata    (cpu_wdata),
        .cpu_rdata    (cpu_rdata),
        .cpu_done     (cpu_done),

        .req_wr_en    (req_wr_en),
        .req_wr_data  (req_wr_data),
        .req_full     (req_full),

        .resp_rd_en   (resp_rd_en),
        .resp_rd_data (resp_rd_data),
        .resp_empty   (resp_empty)
    );

    // =========================================================
    // CDC bridge #1: fast -> slow (read/write requests)
    // =========================================================
    async_fifo #(
        .DATA_WIDTH(REQ_W), .ADDR_WIDTH(FIFO_AW)
    ) u_req_fifo (
        .wr_clk  (clk_fast), .wr_rst(rst_fast),
        .wr_en   (req_wr_en), .wr_data(req_wr_data), .full(req_full),

        .rd_clk  (clk_slow), .rd_rst(rst_slow),
        .rd_en   (req_rd_en), .rd_data(req_rd_data), .empty(req_empty)
    );

    // =========================================================
    // CDC bridge #2: slow -> fast (read responses)
    // =========================================================
    async_fifo #(
        .DATA_WIDTH(DATA_W), .ADDR_WIDTH(FIFO_AW)
    ) u_resp_fifo (
        .wr_clk  (clk_slow), .wr_rst(rst_slow),
        .wr_en   (resp_wr_en), .wr_data(resp_wr_data), .full(resp_full),

        .rd_clk  (clk_fast), .rd_rst(rst_fast),
        .rd_en   (resp_rd_en), .rd_data(resp_rd_data), .empty(resp_empty)
    );

    // =========================================================
    // Main memory: entirely in the slow domain
    // =========================================================
    data_memory_slow #(
        .ADDR_W(ADDR_W), .DATA_W(DATA_W)
    ) u_mem (
        .clk          (clk_slow),
        .rst          (rst_slow),

        .req_rd_en    (req_rd_en),
        .req_rd_data  (req_rd_data),
        .req_empty    (req_empty),

        .resp_wr_en   (resp_wr_en),
        .resp_wr_data (resp_wr_data),
        .resp_full    (resp_full)
    );

endmodule