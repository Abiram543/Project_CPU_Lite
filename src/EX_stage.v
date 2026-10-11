`include "params.vh"
`include "Opcode.vh"

module EX_stage (
    input wire [`OPWIDTH-1:0] ID_EX_opcode,                
    input wire [`LOG2_NofR-1:0] ID_EX_Rd_Addr,             
    input wire [`IMM_WIDTH-1:0] ID_EX_IMM_Val,             
    input wire [`WIDTH-1:0] ID_EX_Rs1_data, ID_EX_Rs2_data,
    input wire ID_EX_is_load_op,                           
    input wire ID_EX_is_store_op,                          
    input wire ID_EX_is_alu_op,                            
    input wire ID_EX_is_branch_op, 
    input wire ID_EX_is_mem_op,                         

    output wire [`LOG2_NofR-1:0] EX_Rd_Addr,
    output wire [`WIDTH-1:0] EX_Rd_data, // Output data from Ex stage
    output wire [`WIDTH-1:0] MEM_Addr,
    output wire [`WIDTH-1:0] MEM_data,
    output wire EX_is_load_op,  
    output wire EX_is_store_op, 
    output wire EX_is_mem_op,
    output wire Zero, Carry, Neg, OV
);

wire [`WIDTH-1:0] ALU_op1, ALU_op2, ALU_out;

ALU u_alu(
    .op1(ALU_op1),
    .op2(ALU_op2),
    .opcode(ID_EX_opcode),
    .ALU_out(ALU_out),
    .Zero(Zero), 
    .Carry(Carry), 
    .Neg(Neg), 
    .OV(OV)
);

assign ALU_op1 = ID_EX_is_alu_op ? ID_EX_Rs1_data : 'd0;
assign ALU_op2 = ID_EX_is_alu_op ? ID_EX_Rs2_data : 'd0;

assign EX_Rd_data = ID_EX_is_load_op ? ID_EX_Rs1_data : ID_EX_is_alu_op ? ALU_out : 'd0;

// Mem Stage values for store operations
assign MEM_Addr = ID_EX_is_store_op ? ID_EX_Rs2_data : 'd0;
assign MEM_data = ID_EX_is_store_op ? ID_EX_Rs1_data : 'd0;

assign EX_Rd_Addr = ID_EX_Rd_Addr;

assign EX_is_mem_op = ID_EX_is_mem_op;

assign EX_is_load_op = ID_EX_is_load_op;
assign EX_is_store_op = ID_EX_is_store_op;
endmodule
