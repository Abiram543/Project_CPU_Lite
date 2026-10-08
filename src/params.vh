`ifndef PARAMS
`define PARAMS

`define WIDTH 32    // Data Width
`define OPWIDTH 8   // Opcode width
`define LOG2_WIDTH $clog2(`WIDTH) 
`define PMEMDEPTH 4096   // Program Memory Depth is 4k
`define LOG2_PMEMDEPTH $clog2(`PMEMDEPTH)  // Program Mem Depth Address width
`define NofR 16     // No. of General Purpose Registers
`define LOG2_NofR $clog2(`NofR)     // Registers' Address Width size
`define STMDEPTH 1024   // Stack Memory Depth
`define LOG2_STMDEPTH $clog2(`STMDEPTH)  // Stack Pointer width
`define MEM_DEPTH 16384     // Main Memory Depth is 16k
`define ADDR_WIDTH $clog2(`MEM_DEPTH)    // Main Memory Address width (P.A Size)
`define FIFO_WIDTH (1+`ADDR_WIDTH+`WIDTH)   // {1bit-read/write, Address bits, Data bits}

// Instruction set Architecture Params
`define INS_WIDTH 32    // Instruction Memory
`define Reg_WIDTH 4      // Rd, Rs1, Rs2 Address size width (16 General purpose Registers)
`define IMM_WIDTH 12     // IMM value width
`endif
