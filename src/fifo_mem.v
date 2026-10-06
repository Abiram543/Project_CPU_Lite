module fifo_mem #(parameter DATA_WIDTH = 8,
                  parameter  DEPTH = 32,
                  parameter ADDR_WIDTH = 5
)
(
    input wire wclk, rclk,
    input wire rdrstn,
    input wire wr_en, rd_en,
    input wire full, empty,
    input wire [DATA_WIDTH-1:0] Data_in,
    input wire [ADDR_WIDTH-1:0] Wr_Addr, Rd_Addr,
    output reg [DATA_WIDTH-1:0] Data_out
);

reg [DATA_WIDTH-1:0] fifomem [DEPTH-1:0];
// Write Logic
always @(posedge wclk) begin
    if (!full && wr_en) begin
            fifomem[Wr_Addr] <= Data_in;
    end
end
// Read Logic
// always @(posedge rclk or negedge rdrstn) begin
//     if(!rdrstn) begin
//         Data_out <= 'b0;
//     end
//     else begin
//         if (!empty && rd_en) begin
//             Data_out <= fifomem[Rd_Addr];
//         end
//     end
// end
always @(*) begin
    if (!empty) begin
        Data_out = fifomem[Rd_Addr];
    end
    else Data_out = 0;

end
endmodule
