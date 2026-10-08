`include "params.vh"

module RegFiles (
    input wire clk,
    input wire rstn,
    input wire [`LOG2_NofR-1:0] Rs1_Addr, Rs2_Addr,
    input wire [`LOG2_NofR-1:0] Rd_Addr,        // From Write back Stage
    input wire [`WIDTH-1:0] Rd_val,             // From Write back stage
    input wire wr_en,                           // From Control unit
    output wire [`WIDTH-1:0] Rs1_val, Rs2_val   // To ALU op1, op2
);

reg [`WIDTH-1:0] Reg [`NofR-1:0];
integer i;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        for (i = 0; i < `NofR; i = i + 1 ) begin
            Reg[i] <= 'b0;
        end
    end 
    else if (wr_en) begin
        Reg[Rd_Addr] <= Rd_val;
    end
end
// Read source values Rs1, Rs2:
assign Rs1_val = Reg[Rs1_Addr];
assign Rs2_val = Reg[Rs2_Addr];

endmodule
