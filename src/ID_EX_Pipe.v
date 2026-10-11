`include "params.vh"

module ID_EX_Pipe (
    input wire clk_cpu,
    input wire rstn_cpu,

    input wire flush,   // From Branch Controller
    input wire stall,   // From Memory Controller

    input wire EX_fwd_A, EX_fwd_B, // From EX stage Forwarding val Control signal
    input wire MEM_fwd_A, MEM_fwd_B,    // From MEM Stage Forwarding Val Control signal

    // From ID_stage
    input wire [`OPWIDTH-1:0] ID_opcode,   
    input wire [`LOG2_NofR-1:0] ID_Rd_Addr,
    input wire [`WIDTH-1:0] Rs1_data, Rs2_data,
    input wire is_load_op,  
    input wire is_store_op, 
    input wire is_alu_op,   
    input wire is_branch_op, 
    input wire is_mem_op,

    input wire [`WIDTH-1:0] EX_Rd_data, // From EX Stage
    input wire [`WIDTH-1:0] MEM_data_out,    // From Mem Stage

    output reg [`OPWIDTH-1:0] ID_EX_opcode,
    output reg [`LOG2_NofR-1:0] ID_EX_Rd_Addr,
    output reg [`WIDTH-1:0] ID_EX_Rs1_data, ID_EX_Rs2_data,
    output reg ID_EX_is_load_op,
    output reg ID_EX_is_store_op, 
    output reg ID_EX_is_alu_op,
    output reg ID_EX_is_branch_op,
    output reg ID_EX_is_mem_op
);

always @(posedge clk_cpu or negedge rstn_cpu ) begin
    if (!rstn_cpu) begin
        ID_EX_opcode <= 'd0;
        ID_EX_Rd_Addr <= 'd0;
        ID_EX_Rs1_data <= 'd0;
        ID_EX_Rs2_data <= 'd0;
        ID_EX_is_load_op <= 'd0;
        ID_EX_is_store_op <= 'd0; 
        ID_EX_is_alu_op <= 'd0; 
        ID_EX_is_branch_op <= 'd0; 
        ID_EX_is_mem_op <= 'd0;
    end
    else if (stall) begin
        ID_EX_opcode <= ID_EX_opcode;
        ID_EX_Rd_Addr <= ID_EX_Rd_Addr;
        ID_EX_Rs1_data <= ID_EX_Rs1_data;
        ID_EX_Rs2_data <= ID_EX_Rs2_data;
        ID_EX_is_load_op <= ID_EX_is_load_op;
        ID_EX_is_store_op <= ID_EX_is_store_op; 
        ID_EX_is_alu_op <= ID_EX_is_alu_op; 
        ID_EX_is_branch_op <= ID_EX_is_branch_op; 
        ID_EX_is_mem_op <= ID_EX_is_mem_op;
    end
    else if (flush) begin
        ID_EX_opcode <= 'd0;
        ID_EX_Rd_Addr <= 'd0;
        ID_EX_Rs1_data <= 'd0;
        ID_EX_Rs2_data <= 'd0;
        ID_EX_is_load_op <= 'd0;
        ID_EX_is_store_op <= 'd0; 
        ID_EX_is_alu_op <= 'd0; 
        ID_EX_is_branch_op <= 'd0; 
        ID_EX_is_mem_op <= 'd0;
    end
    else begin
        ID_EX_opcode <= ID_opcode;
        ID_EX_Rd_Addr <= ID_Rd_Addr;
        ID_EX_Rs1_data <= EX_fwd_A ? EX_Rd_data : MEM_fwd_A ? MEM_data_out : Rs1_data;
        ID_EX_Rs2_data <= EX_fwd_B ? EX_Rd_data : MEM_fwd_B ? MEM_data_out : Rs2_data;
        ID_EX_is_load_op <= is_load_op;
        ID_EX_is_store_op <= is_store_op; 
        ID_EX_is_alu_op <= is_alu_op; 
        ID_EX_is_branch_op <= is_branch_op;
        ID_EX_is_mem_op <= is_mem_op;
    end
end

endmodule
