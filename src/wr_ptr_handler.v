module wr_ptr_handler #(
    parameter ADDR_WIDTH = 5
) (
    input wire wclk,
    input wire wrstn,
    input wire wr_en,
    input wire [ADDR_WIDTH:0] g_rdptr_sync,
    output wire [ADDR_WIDTH:0] g_wptr,
    output wire [ADDR_WIDTH-1:0] b_wptr,
    output reg full
);
integer i;
reg [ADDR_WIDTH:0] wptr;        // Temp for driving Output b_wptr
//wire [ADDR_WIDTH:0] gwptr;      // Temp for registering the output val
reg [ADDR_WIDTH:0] b_rptr;      // Temp for Grey to Binary conv of g_rdptr_sync
wire [ADDR_WIDTH:0] gwptr_temp;

// Write Pointer logic
always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        wptr <= 'b0;
    end
    else begin
        if (wr_en && !full) begin
            wptr <= wptr + 1;
        end
        else begin
            wptr <= wptr;
        end
    end
end

// Assigning the binary value of the WR_Address to the FIFO memory
assign b_wptr = wptr[ADDR_WIDTH-1:0];

// Binary to Grey converter
assign gwptr_temp = wptr ^ (wptr >> 1);

// Grey to Binary converter
always @(*) begin
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin
        b_rptr[i] = ^(g_rdptr_sync >> i);
    end
end

// Register the Combo output to avoid Glitch
DFF #(.ADDR_WIDTH(ADDR_WIDTH+1)) inst1 (.clk(wclk), .rstn(wrstn), .Din(gwptr_temp), .Q(g_wptr));

// Full condition
always @(*) begin
    if((b_rptr[ADDR_WIDTH] != wptr[ADDR_WIDTH]) && (b_rptr[ADDR_WIDTH-1:0] == wptr[ADDR_WIDTH-1:0])) begin
        full = 1'b1;
    end
    else begin
        full = 'b0;
    end
end

endmodule
