`include "params.vh"

module Forward_logic (
    input wire [`LOG2_NofR-1:0] EX_Rd_Addr,
    input wire [`LOG2_NofR-1:0] MEM_Rd_Addr,
    input wire [`WIDTH-1:0] EX_MEM_Addr,

    input wire [`LOG2_NofR-1:0] ID_Rs1_Addr, ID_Rs2_Addr,

    output reg EX_fwd_A, EX_fwd_B,  
    output reg MEM_fwd_A, MEM_fwd_B
);
    
assign EX_fwd_A = (EX_Rd_Addr == ID_Rs1_Addr) ? 1'd1 : 1'd0;
assign EX_fwd_B = (EX_Rd_Addr == ID_Rs2_Addr) ? 1'd1 : 1'd0;

assign MEM_fwd_A = (MEM_Rd_Addr == ID_Rs1_Addr) ? 1'd1 : 1'd0;
assign MEM_fwd_B = (MEM_Rd_Addr == ID_Rs2_Addr) ? 1'd1 : 1'd0;
endmodule
