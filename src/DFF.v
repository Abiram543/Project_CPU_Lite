module DFF #(parameter ADDR_WIDTH = 5)(
        input wire clk,
        input wire rstn,
        input wire [ADDR_WIDTH-1:0] Din,
        output reg [ADDR_WIDTH-1:0] Q
);

always @ (posedge clk or negedge rstn) begin
        if(!rstn) begin
                Q <= 'b0;
        end
        else begin
                Q <= Din;
        end
end
endmodule
