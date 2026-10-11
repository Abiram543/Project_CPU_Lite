module top ();

// Program Memory
Instruction_Mem u_program_mem(
    .clk(), 
    .rstn(),
    .PC_val(),      
    .Instr()
);

// PC
PC u_programCounter(
    .clk(),
    .rstn(),
    .stall(),
    .flush(),
    .is_halted(),
    .Branch_target(),
    .PC_val()
);

// IF Stage
IF_stage u_if_stage(
    .Instr(),    
    .PC(),
    .IF_PC(),
    .IF_Instr(), 
    .is_halted() 
);

// IF_ID Pipeline
IF_ID_Pipe u_if_id_pipe(
    .clk_cpu(),
    .rstn_cpu(),
    .IF_Instr(),   
    .IF_PC(), 
    .stall(), 
    .flush(), 
    .Branch_target(),
    .is_halted(),   
    .IF_ID_Instr(),
    .IF_ID_Instr_valid(),
    .IF_ID_PC()  
);

// ID Stage
ID_stage u_id_stage(
    .IF_ID_Instr(),
    .IF_ID_Instr_valid(),
    .Rs1_val(), 
    .Rs2_val(),
    .ID_opcode(),   
    .ID_Rd_Addr(),
    .ID_Rs1_Addr(), 
    .ID_Rs2_Addr(),
    .ID_IMM_Val(),
    .Rs1_data(), 
    .Rs2_data(),
    .is_load_op(), 
    .is_store_op(), 
    .is_alu_op(), 
    .is_branch_op(),
    .is_mem_op()
);

// Reg Files
RegFiles u_Regifiles(
    .clk(),
    .rstn(),
    .Rs1_Addr(), 
    .Rs2_Addr(),
    .Rd_Addr(),        
    .Rd_val(),          
    .wr_en(),           
    .Rs1_val(), 
    .Rs2_val() 
);

// Branch Controller logic
Branch_Controller u_branch_cntrl(
    .is_branch_op(),
    .ID_opcode(),     
    .Rs1_data(),   
    .ID_IMM_Val(), 
    .IF_ID_PC(),  
    .Branch_target(),
    .flush()
);

// ID_EX Pipeline
ID_EX_Pipe u_id_ex(
    .clk_cpu(),
    .rstn_cpu(),
    .flush(),   
    .stall(),  
    .EX_fwd_A(), 
    .EX_fwd_B(), 
    .MEM_fwd_A(), 
    .MEM_fwd_B(),  
    .ID_opcode(),   
    .ID_Rd_Addr(),
    .Rs1_data(), 
    .Rs2_data(),
    .is_load_op(),  
    .is_store_op(), 
    .is_alu_op(),   
    .is_branch_op(), 
    .is_mem_op(),
    .EX_Rd_data(), 
    .MEM_data_out(),
    .ID_EX_opcode(),
    .ID_EX_Rd_Addr(),
    .ID_EX_Rs1_data(), 
    .ID_EX_Rs2_data(),
    .ID_EX_is_load_op(),
    .ID_EX_is_store_op(), 
    .ID_EX_is_alu_op(),
    .ID_EX_is_branch_op(),
    .ID_EX_is_mem_op()
);

// EX Stage
EX_stage u_ex(
    .ID_EX_opcode (),                
    .ID_EX_Rd_Addr(),             
    .ID_EX_IMM_Val(),             
    .ID_EX_Rs1_data(), 
    .ID_EX_Rs2_data(),
    .ID_EX_is_load_op(),                           
    .ID_EX_is_store_op(),                          
    .ID_EX_is_alu_op(),                            
    .ID_EX_is_branch_op(), 
    .ID_EX_is_mem_op(),  
    .EX_Rd_Addr(),
    .EX_Rd_data(), 
    .MEM_Addr(),
    .MEM_data(),
    .EX_is_load_op(),  
    .EX_is_store_op(), 
    .EX_is_mem_op(),
    .Zero(), 
    .Carry(), 
    .Neg(), 
    .OV()
);

// PSR Logic
PSR u_psr(
    .clk(),
    .rstn(),
    .Zero(), 
    .Carry(), 
    .Neg(), 
    .OV(),
    .ID_EX_is_load_op(),
    .PSR()
);

// Forwarding logic
Forward_logic u_fwd_logic(
    .EX_Rd_Addr (),
    .MEM_Rd_Addr(),
    .EX_MEM_Addr(),
    .ID_Rs1_Addr(), 
    .ID_Rs2_Addr(),
    .EX_fwd_A (), 
    .EX_fwd_B (),  
    .MEM_fwd_A(), 
    .MEM_fwd_B()
);

// Ex_MEM Pipeline
EX_MEM_Pipe u_ex_mem_pipe(
    .clk_cpu(),
    .rstn_cpu(),
    .stall(),
    .EX_Rd_Addr(),
    .EX_Rd_data(),
    .MEM_Addr(),      
    .MEM_data(),  
    .EX_is_load_op(), 
    .EX_is_store_op(),    
    .EX_is_mem_op(),              
    .EX_MEM_Rd_Addr(),
    .EX_MEM_Rd_data(),
    .EX_MEM_Addr(),
    .EX_MEM_data(),
    .EX_MEM_is_load_op(),
    .EX_MEM_is_store_op(),
    .EX_MEM_is_mem_op()
);

// MEM stage
MEM_stage u_mem_stage(
    .clk_cpu(),
    .rstn_cpu(),
    .clk_mem(),
    .rstn_mem(),
    .EX_MEM_Rd_Addr(),
    .EX_MEM_Rd_data(),    
    .EX_MEM_Addr(),       
    .EX_MEM_data(),       
    .EX_MEM_is_mem_op(),   
    .EX_MEM_is_load_op(),              
    .EX_MEM_is_store_op(),
    .stall(),
    .MEM_data_out(),
    .MEM_Rd_Addr(),
    .MEM_is_store_op()
);

// Mem + Cache + CDC
top_mem u_top_mem(
    .clk_cpu(),
    .rstn_cpu(),
    .clk_mem(),
    .rstn_mem(),
    .cpu_req(),
    .cpu_wen(), 
    .cpu_ren(), 
    .cpu_addr (),
    .cpu_wdata(),
    .cpu_rdata(),
    .cache_done()
);

// MEM_WB pipe
MEM_WB_Pipe u_mem_wb_pipe(
    .clk_cpu(),
    .rstn_cpu(),
    .stall(),
    .MEM_data_out(),
    .MEM_Rd_Addr(),
    .MEM_is_store_op(),
    .MEM_WB_Rd_Addr(),
    .MEM_WB_Rd_data(),
    .MEM_WB_is_store_op()
);

// WB Stage
WB_stage u_wb(
    .MEM_WB_Rd_Addr(),
    .MEM_WB_Rd_data(),
    .MEM_WB_is_store_op(),
    .wr_en(),
    .WB_Rd_Addr(),
    .WB_Rd_data()
);


endmodule
