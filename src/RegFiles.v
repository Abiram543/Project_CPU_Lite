module RegFiles (
    input wire clk,
    input wire rstn,
    input wire [`LOG2_NofR-1:0] Rs1_Addr, Rs2_Addr,
    input wire [`LOG2_NofR-1:0] Rd_Addr,        // From Write back Stage
    input wire [`WIDTH-1:0] Rd_val,             // From Write back stage
    input wire wr_en,                           // From Control unit
    output reg [`WIDTH-1:0] Rs1_val, Rs2_val    // To ALU op1, op2
);

reg [`WIDTH-1:0] Reg [`NofR-1:0];

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        Rs1_val <= 'b0;
        Rs2_val <= 'b0;
        for (i = 0; i < `NofR; i = i + 1 ) begin
            Reg[i] <= 'b0;
        end
    end 
    else begin
        Rs1 <= Reg[Rs1_Addr];
        Rs2 <= Reg[Rs2_Addr];
        if (wr_en) begin
            Reg[Rd_Addr] <= Rd_val;
        end
    end
end

endmodule