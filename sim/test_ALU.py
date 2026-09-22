# COCOTb Testbench for ALU code

import random

import cocotb
from cocotb.triggers import Timer, ReadOnly

# Opcode values 
ADD  = 0x06
SUB  = 0x07
MUL  = 0x08
AND  = 0x09
OR   = 0x0A
NOT  = 0x0B
EQ   = 0x0D
ADDI = 0x16
SUBI = 0x17
SHL  = 0x11
SHR  = 0x12
SAR  = 0x13
XOR  = 0x10
ROL  = 0x14
ROR  = 0x15
ANDI = 0x18
ORI  = 0x19
XORI = 0x1A
MOV  = 0x1B
SLT  = 0x1C
SLTU = 0x1D
LUI  = 0x1E
LOAD_IMM = 0x03


WIDTH = 8

MASK = (1 << WIDTH) - 1

def to_signed(value, width):
    """Convert unsigned WIDTH-bit value to signed value."""
    sign_bit = 1 << (width - 1)

    if value & sign_bit:
        return value - (1 << width)

    return value


def alu_model(op1, op2, opcode, width=WIDTH):

    mask = (1 << width) - 1

    # Make sure inputs behave like WIDTH-bit Verilog signals
    op1 &= mask
    op2 &= mask

    if opcode == ADD or opcode == ADDI:
        result = op1 + op2

    elif opcode == SUB or opcode == SUBI:
        result = op1 - op2

    elif opcode == MUL:
        result = op1 * op2

    elif opcode == AND or opcode == ANDI:
        result = op1 & op2

    elif opcode == OR or opcode == ORI:
        result = op1 | op2

    elif opcode == NOT:
        result = ~op1

    elif opcode == EQ:
        result = 1 if op1 == op2 else 0

    elif opcode == SHL:
        shift = op2 & 0x7
        result = op1 << shift

    elif opcode == SHR:
        shift = op2 & 0x7
        result = op1 >> shift

    elif opcode == SAR:
        shift = op2 & 0x7

        signed_op1 = to_signed(op1, width)

        result = signed_op1 >> shift

    elif opcode == XOR or opcode == XORI:
        result = op1 ^ op2

    elif opcode == ROR:

        shift = op2 & 0x7

        if shift == 0:
            result = op1
        else:
            shift %= width

            result = (
                (op1 << shift) |
                (op1 >> (width - shift))
            )

    elif opcode == ROL:

        shift = op2 & 0x7

        if shift == 0:
            result = op1
        else:
            shift %= width

            result = (
                (op1 >> shift) |
                (op1 << (width - shift))
            )

    elif opcode == MOV:
        result = op1

    elif opcode == SLT:

        signed_op1 = to_signed(op1, width)
        signed_op2 = to_signed(op2, width)

        result = 1 if signed_op1 < signed_op2 else 0

    elif opcode == SLTU:
        result = 1 if op1 < op2 else 0

    elif opcode == LUI:
        result = op2

    elif opcode == LOAD_IMM:
        result = op2

    else:
        result = 0

    return result & mask


# List for Opcodes
L1 = [
    ADD ,
    SUB ,
    MUL ,
    AND ,
    OR  ,
    NOT ,
    EQ  ,
    ADDI,
    SUBI,
    SHL ,
    SHR ,
    SAR ,
    XOR ,
    ROL ,
    ROR ,
    ANDI,
    ORI ,
    XORI,
    MOV ,
    SLT ,
    SLTU,
    LUI ,
    LOAD_IMM
]

# Test cases
@cocotb.test()
async def Basic_func_test(dut):
    for i in range(500):
        opc = random.choice(L1)
        a = random.getrandbits(8)
        b = random.getrandbits(8)
        dut.opcode.value = opc
        dut.op1.value = a
        dut.op2.value = b
        await Timer (1, "ns")
        expected = alu_model(a, b, opc, WIDTH)
        actual = dut.ALU_out.value
        assert expected == actual, f"[FAIL] opcode = {opc} | op1 = {a} | op2 = {b} | EXP = {expected} | ACT = {actual}"
        cocotb.log.info("[PASS]")

