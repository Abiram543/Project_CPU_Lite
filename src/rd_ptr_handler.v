module rd_ptr_handler #(
    parameter ADDR_WIDTH = 5
) (
    input wire rclk,
    input wire rdrstn,
    input wire rd_en,
    input wire [ADDR_WIDTH:0] g_wptr_sync,
    output wire empty,
    output wire [ADDR_WIDTH-1:0] b_rdptr,
    output wire [ADDR_WIDTH:0] g_rdptr
);
integer i;
reg [ADDR_WIDTH:0] rdptr;
reg [ADDR_WIDTH:0] b_wptr;
wire [ADDR_WIDTH:0] g_rdptr_temp;

// Read pointer logic
always @(posedge rclk or negedge rdrstn) begin
    if (!rdrstn) begin
        rdptr <= 'b0;
    end
    else begin
        if (rd_en && !empty) begin
            rdptr <= rdptr + 1;
        end
        else begin
            rdptr <= rdptr;
        end
    end
end

// Binary read pointer output
assign b_rdptr = rdptr[ADDR_WIDTH-1:0];

// Binary to grey coverter
assign g_rdptr_temp = rdptr ^ (rdptr >> 1);

// Grey to Binary converter
always @(*) begin
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin
        b_wptr[i] = ^(g_wptr_sync >> i);
    end
end

// Register the Combo output to avoid Glitch
DFF #(.ADDR_WIDTH(ADDR_WIDTH+1)) inst1(.clk(rclk), .rstn(rdrstn), .Din(g_rdptr_temp), .Q(g_rdptr));

// Empty logic
assign empty = (rdptr == b_wptr);

endmodule
