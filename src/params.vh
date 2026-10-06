`ifndef PARAMS
`define PARAMS

`define WIDTH 32
`define OPWIDTH 8  
`define LOG2_WIDTH $clog2(`WIDTH) 
`define PMEMDEPTH 4096
`define LOG2_PMEMDEPTH $clog2(`PMEMDEPTH)  
`define NofR 16
`define LOG2_NofR $clog2(`NofR)
`define STMDEPTH 1024
`define LOG2_STMDEPTH $clog2(`STMDEPTH)  
`define ADDR_WIDTH $clog2(16384)    // Main Memory Depth is 16K
`define FIFO_WIDTH (1+`ADDR_WIDTH+`WIDTH)   // {1bit-read/write, Address bits, Data bits}
`define MEM_DEPTH 16384 
`endif
