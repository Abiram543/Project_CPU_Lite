// =============================================================
// async_fifo.v
// Generic asynchronous FIFO, Gray-coded read/write pointers,
// synchronized through two flip-flops into the opposite domain.
// This is the ONLY module allowed to carry signals between the
// fast and slow clock domains. Instantiate it twice:
//   - once for CPU-side-to-memory requests (wr=fast, rd=slow)
//   - once for memory-to-CPU-side responses (wr=slow, rd=fast)
// =============================================================
module async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 4            // depth = 2**ADDR_WIDTH
)(
    // ---------------- Write side ----------------
    input  wire                  wr_clk,
    input  wire                  wr_rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // ---------------- Read side ----------------
    input  wire                  rd_clk,
    input  wire                  rd_rst,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    localparam DEPTH = 1 << ADDR_WIDTH;

    // Dual-port storage. In FPGA synthesis this maps to a
    // simple dual-clock block RAM.
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // One extra MSB on each pointer distinguishes full from empty
    // when binary pointers wrap (standard async-FIFO trick).
    reg [ADDR_WIDTH:0] wr_ptr_bin, wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_bin, rd_ptr_gray;

    reg full_r, empty_r;
    assign full  = full_r;
    assign empty = empty_r;

    // Synchronizers: 2 flops each, crossing into the opposite domain
    reg [ADDR_WIDTH:0] rd_ptr_gray_s1, rd_ptr_gray_s2; // read ptr  -> write domain
    reg [ADDR_WIDTH:0] wr_ptr_gray_s1, wr_ptr_gray_s2; // write ptr -> read domain

    wire [ADDR_WIDTH:0] wr_ptr_bin_next  = wr_ptr_bin + (wr_en & ~full_r);
    wire [ADDR_WIDTH:0] wr_ptr_gray_next = (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    wire [ADDR_WIDTH:0] rd_ptr_bin_next  = rd_ptr_bin + (rd_en & ~empty_r);
    wire [ADDR_WIDTH:0] rd_ptr_gray_next = (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    // ---------------- Write domain ----------------
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
            full_r      <= 1'b0;
        end else begin
            if (wr_en && !full_r)
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;

            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

            // "Full" compares the pointer we are ABOUT to have against
            // the synchronized (and therefore slightly stale) read
            // pointer. Stale-but-conservative is what makes this safe:
            // the FIFO can only ever look fuller than it truly is from
            // this side, never emptier, so it can never be over-written.
            full_r <= (wr_ptr_gray_next ==
                       {~rd_ptr_gray_s2[ADDR_WIDTH:ADDR_WIDTH-1],
                         rd_ptr_gray_s2[ADDR_WIDTH-2:0]});
        end
    end

    // ---------------- Read domain ----------------
    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            rd_data     <= 0;
            empty_r     <= 1'b1;
        end else begin
            if (rd_en && !empty_r)
                rd_data <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

            // Same logic, mirrored: stale-but-conservative means this
            // side can only look emptier than it truly is, never
            // fuller, so it can never read past a real empty FIFO.
            empty_r <= (rd_ptr_gray_next == wr_ptr_gray_s2);
        end
    end

    // ---------------- Synchronizers ----------------
    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            rd_ptr_gray_s1 <= 0;
            rd_ptr_gray_s2 <= 0;
        end else begin
            rd_ptr_gray_s1 <= rd_ptr_gray;
            rd_ptr_gray_s2 <= rd_ptr_gray_s1;
        end
    end

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            wr_ptr_gray_s1 <= 0;
            wr_ptr_gray_s2 <= 0;
        end else begin
            wr_ptr_gray_s1 <= wr_ptr_gray;
            wr_ptr_gray_s2 <= wr_ptr_gray_s1;
        end
    end

endmodule
