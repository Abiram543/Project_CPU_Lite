`include "../src/params.vh"
module Main_mem (
    input wire clk_mem,
    input wire rstn_mem,

    input wire [(`FIFO_WIDTH)-1:0] Data_in, // From Request FIFO output --> {1==wen/0==ren, Address, Data}
    input wire req_empty,   // Request FIFO empty
    output reg req_rd_en,   // Read enable for Req. FIFO

    input wire resp_full,   // Response FIFO full
    output reg resp_wr_en,  // Resp. FIFO write enable signal
    output reg [(`WIDTH)-1:0] Data_out  // Response FIFO input data
);
// Main memory declaration
reg [(`WIDTH)-1:0] Main_mem [(`MEM_DEPTH)-1:0];

// Bit Mapping of input data from Req FIFO
wire en;
wire [(`ADDR_WIDTH)-1:0] index;
wire [(`WIDTH)-1:0] data;
assign en = Data_in[(`FIFO_WIDTH)-1];
assign index = Data_in[(`FIFO_WIDTH)-2:(`WIDTH)];
assign data = Data_in[(`WIDTH)-1:0];

integer i;

// Memory control logic
always @(posedge clk_mem or negedge rstn_mem ) begin
    if (!rstn_mem) begin
        Data_out <= 'b0;
        for (i = 0; i< (`MEM_DEPTH); i = i + 1) begin   // Usually should not reset the memory, just for lint pass
            Main_mem[i] <= 'b0;
        end
    end
    else if (en) begin  // Write req
        Main_mem[index] <= data;
    end
    else if (!en) begin // Read req
        Data_out <= Main_mem[index];
    end
end
// read en logic
always @(*) begin
    if (!req_empty) begin
        req_rd_en = 1;
    end
    else req_rd_en = 0;
end
// write en logic
always @(*) begin
    if (!resp_full) begin
        resp_wr_en = 1;
    end
    else resp_wr_en = 0;
end

endmodule
