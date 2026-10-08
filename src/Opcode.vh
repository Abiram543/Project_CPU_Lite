`ifndef _Opcode_vh_
`define _Opcode_vh_

`define OP_NOP       8'h00
`define OP_LOAD      8'h01
`define OP_LOAD_IND  8'h02
`define OP_LOAD_IMM  8'h03
`define OP_STORE     8'h04
`define OP_STORE_IND 8'h05
`define OP_ADD       8'h06
`define OP_SUB       8'h07
`define OP_MUL       8'h08
`define OP_AND       8'h09
`define OP_OR        8'h0A
`define OP_NOT       8'h0B
`define OP_CMP       8'h0C
`define OP_EQ        8'h0D
`define OP_ADDI      8'h16
`define OP_SUBI      8'h17
`define OP_SHL       8'h11
`define OP_SHR       8'h12
`define OP_SAR       8'h13
`define OP_JMP       8'h0E
`define OP_JMP_IF    8'h0F
`define OP_BEQ       8'h20
`define OP_BNE       8'h21
`define OP_BLT       8'h22
`define OP_BGE       8'h23
`define OP_XOR       8'h10
`define OP_ROL       8'h14
`define OP_ROR       8'h15
`define OP_ANDI      8'h18
`define OP_ORI       8'h19
`define OP_XORI      8'h1A
`define OP_MOV       8'h1B
`define OP_SLT       8'h1C
`define OP_SLTU      8'h1D
`define OP_LUI       8'h1E
`define OP_BLTU      8'h24
`define OP_JMP_REG   8'h26
`define OP_CALL      8'h27
`define OP_RET       8'h28
`define OP_HALT      8'hFF

`endif // _Opcode_vh_
