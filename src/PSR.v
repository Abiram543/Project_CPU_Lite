module PSR (
    input wire clk,
    input wire rstn,
    input wire Z, C, N, V,  // From the ALU
    // Processor Status Registers
    output reg [3:0] PSR
);
/*
PSR[0] = Zero
PSR[1] = Negative 
PSR[2] = Carry
PSR[3] = Overflow 
*/
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        PSR <= 'b0;
    end
    else begin
        PSR[0] <= Z;
        PSR[1] <= N;
        PSR[2] <= C;
        PSR[3] <= V;
    end
end

endmodule
