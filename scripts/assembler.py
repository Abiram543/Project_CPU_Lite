#!/usr/bin/env python3

import sys
import re
from pathlib import Path


# ============================================================
# OPCODES
# ============================================================

OPCODES = {
    "NOP":      0x00,
    "LOAD":     0x01,
    "LOAD_IND": 0x02,
    "LOAD_IMM": 0x03,
    "STORE":    0x04,
    "STORE_IND":0x05,

    "ADD":      0x06,
    "SUB":      0x07,
    "MUL":      0x08,
    "AND":      0x09,
    "OR":       0x0A,
    "NOT":      0x0B,
    "CMP":      0x0C,
    "EQ":       0x0D,

    "JMP":      0x0E,
    "JMP_IF":   0x0F,

    "XOR":      0x10,
    "SHL":      0x11,
    "SHR":      0x12,
    "SAR":      0x13,
    "ROL":      0x14,
    "ROR":      0x15,

    "ADDI":     0x16,
    "SUBI":     0x17,
    "ANDI":     0x18,
    "ORI":      0x19,
    "XORI":     0x1A,
    "MOV":      0x1B,
    "SLT":      0x1C,
    "SLTU":     0x1D,
    "LUI":      0x1E,

    "BEQ":      0x20,
    "BNE":      0x21,
    "BLT":      0x22,
    "BGE":      0x23,
    "BLTU":     0x24,
    "BGEU":     0x25,

    "JMP_REG":  0x26,

    # CALL = 0x27 ignored
    # RET  = 0x28 ignored

    "HALT":     0xFF,
}


# ============================================================
# INSTRUCTION TYPES
# ============================================================

R_TYPE = {
    "ADD", "SUB", "MUL",
    "AND", "OR", "XOR",
    "EQ",
    "SHL", "SHR", "SAR",
    "ROL", "ROR",
    "SLT", "SLTU"
}

I_TYPE = {
    "ADDI", "SUBI",
    "ANDI", "ORI", "XORI"
}

ONE_SRC = {
    "NOT", "MOV"
}

NO_OPERAND = {
    "NOP", "HALT"
}

LOAD_STORE = {
    "LOAD", "STORE"
}

INDIRECT = {
    "LOAD_IND", "STORE_IND"
}

BRANCH = {
    "BEQ", "BNE",
    "BLT", "BGE",
    "BLTU", "BGEU"
}

JUMP = {
    "JMP"
}


# ============================================================
# UTILITY FUNCTIONS
# ============================================================

def error(message, line_number=None):
    if line_number is not None:
        raise ValueError(f"Line {line_number}: {message}")
    raise ValueError(message)


def parse_register(token, line_number):
    """
    Convert x0 ... x15 to register number.
    """

    token = token.strip().upper()

    if not re.fullmatch(r"X\d+", token):
        error(f"Invalid register '{token}'. Expected x0-x15.", line_number)

    number = int(token[1:])

    if number < 0 or number > 15:
        error(f"Register '{token}' out of range. Valid registers: x0-x15.", line_number)

    return number


def parse_number(token, line_number):
    """
    Parse decimal or hexadecimal number.

    Examples:
        10
        -10
        0x10
        -0x10
    """

    token = token.strip()

    try:
        return int(token, 0)
    except ValueError:
        error(f"Invalid number '{token}'.", line_number)


def parse_imm12_unsigned(token, labels, line_number):
    """
    Parse a 12-bit unsigned immediate/address.
    Labels are allowed.
    """

    token = token.strip()

    if token.upper() in labels:
        value = labels[token.upper()]
    else:
        value = parse_number(token, line_number)

    if value < 0 or value > 0xFFF:
        error(
            f"Value {value} does not fit in 12-bit unsigned field "
            f"(0 to 4095).",
            line_number
        )

    return value


def parse_imm12_signed(token, line_number):
    """
    Parse a signed 12-bit immediate.
    Range: -2048 to +2047
    """

    value = parse_number(token, line_number)

    if value < -2048 or value > 2047:
        error(
            f"Immediate {value} does not fit in signed 12-bit range "
            f"(-2048 to 2047).",
            line_number
        )

    # Convert negative number to 12-bit two's complement
    return value & 0xFFF


def parse_imm12_zero_extended(token, line_number):
    """
    Parse a 12-bit zero-extended immediate.
    Range: 0 to 4095
    """

    value = parse_number(token, line_number)

    if value < 0 or value > 0xFFF:
        error(
            f"Immediate {value} does not fit in unsigned 12-bit range "
            f"(0 to 4095).",
            line_number
        )

    return value


# ============================================================
# CLEAN SOURCE LINE
# ============================================================

def clean_line(line):
    """
    Remove comments and whitespace.

    Supports:
        # comment
        // comment
    """

    line = re.split(r"#|//", line, maxsplit=1)[0]

    return line.strip()


# ============================================================
# SPLIT OPERANDS
# ============================================================

def split_operands(text):
    if not text.strip():
        return []

    return [x.strip() for x in text.split(",")]


# ============================================================
# FIRST PASS
# ============================================================

def first_pass(lines):
    """
    Find labels and assign instruction addresses.

    PC increases by 1 for every instruction.
    Therefore:

        instruction 0 -> address 0
        instruction 1 -> address 1
        instruction 2 -> address 2
        ...

    Labels therefore represent instruction numbers.
    """

    labels = {}
    pc = 0

    for line_number, original_line in enumerate(lines, start=1):

        line = clean_line(original_line)

        if not line:
            continue

        # Allow:
        #   loop:
        #
        # or:
        #   loop: ADD x1, x2, x3

        while ":" in line:

            label, remaining = line.split(":", 1)

            label = label.strip()

            if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", label):
                error(f"Invalid label '{label}'.", line_number)

            label_upper = label.upper()

            if label_upper in labels:
                error(f"Duplicate label '{label}'.", line_number)

            labels[label_upper] = pc

            line = remaining.strip()

            if not line:
                break

        if line:
            pc += 1

    return labels


# ============================================================
# ENCODE INSTRUCTION
# ============================================================

def encode_instruction(line, labels, line_number):

    # --------------------------------------------------------
    # Remove label from instruction
    # --------------------------------------------------------

    if ":" in line:
        line = line.split(":", 1)[1].strip()

    if not line:
        return None

    # --------------------------------------------------------
    # Separate mnemonic and operands
    # --------------------------------------------------------

    parts = line.split(None, 1)

    mnemonic = parts[0].upper()

    if mnemonic not in OPCODES:
        if mnemonic in {"CALL", "RET"}:
            error(
                f"{mnemonic} is intentionally unsupported.",
                line_number
            )

        error(f"Unknown instruction '{mnemonic}'.", line_number)

    opcode = OPCODES[mnemonic]

    operand_text = parts[1] if len(parts) > 1 else ""

    operands = split_operands(operand_text)

    # Default fields
    rd = 0
    rs1 = 0
    rs2 = 0
    imm = 0

    # ========================================================
    # NOP / HALT
    # ========================================================

    if mnemonic in NO_OPERAND:

        if len(operands) != 0:
            error(f"{mnemonic} takes no operands.", line_number)

    # ========================================================
    # R-TYPE
    # ========================================================

    elif mnemonic in R_TYPE:

        if len(operands) != 3:
            error(
                f"{mnemonic} requires 3 operands: "
                "Rd, Rs1, Rs2.",
                line_number
            )

        rd = parse_register(operands[0], line_number)
        rs1 = parse_register(operands[1], line_number)
        rs2 = parse_register(operands[2], line_number)

    # ========================================================
    # I-TYPE
    # ========================================================

    elif mnemonic in I_TYPE:

        if len(operands) != 3:
            error(
                f"{mnemonic} requires 3 operands: "
                "Rd, Rs1, IMM.",
                line_number
            )

        rd = parse_register(operands[0], line_number)
        rs1 = parse_register(operands[1], line_number)

        # ADDI and SUBI use signed immediate
        if mnemonic in {"ADDI", "SUBI"}:
            imm = parse_imm12_signed(
                operands[2],
                line_number
            )

        # ANDI, ORI, XORI use zero-extended immediate
        else:
            imm = parse_imm12_zero_extended(
                operands[2],
                line_number
            )

    # ========================================================
    # NOT / MOV
    # ========================================================

    elif mnemonic in ONE_SRC:

        if len(operands) != 2:
            error(
                f"{mnemonic} requires 2 operands: Rd, Rs1.",
                line_number
            )

        rd = parse_register(operands[0], line_number)
        rs1 = parse_register(operands[1], line_number)

    # ========================================================
    # LOAD
    # ========================================================

    elif mnemonic == "LOAD":

        if len(operands) != 2:
            error(
                "LOAD syntax: LOAD Rd, ADDR",
                line_number
            )

        rd = parse_register(operands[0], line_number)

        imm = parse_imm12_unsigned(
            operands[1],
            labels,
            line_number
        )

    # ========================================================
    # STORE
    # ========================================================

    elif mnemonic == "STORE":

        if len(operands) != 2:
            error(
                "STORE syntax: STORE Rd, ADDR",
                line_number
            )

        # Rd field contains the source register
        rd = parse_register(operands[0], line_number)

        imm = parse_imm12_unsigned(
            operands[1],
            labels,
            line_number
        )

    # ========================================================
    # LOAD_IND
    # ========================================================

    elif mnemonic == "LOAD_IND":

        if len(operands) != 2:
            error(
                "LOAD_IND syntax: LOAD_IND Rd, Rs1",
                line_number
            )

        rd = parse_register(operands[0], line_number)
        rs1 = parse_register(operands[1], line_number)

    # ========================================================
    # STORE_IND
    # ========================================================

    elif mnemonic == "STORE_IND":

        if len(operands) != 2:
            error(
                "STORE_IND syntax: STORE_IND Rd(src), Rs2(addr)",
                line_number
            )

        # According to your specification:
        #
        # STORE_IND Rd, Rs2
        #
        # DATA[Rs2] = Rd

        rd = parse_register(operands[0], line_number)
        rs2 = parse_register(operands[1], line_number)

    # ========================================================
    # CMP
    # ========================================================

    elif mnemonic == "CMP":

        if len(operands) != 2:
            error(
                "CMP syntax: CMP Rs1, Rs2",
                line_number
            )

        rs1 = parse_register(operands[0], line_number)
        rs2 = parse_register(operands[1], line_number)

    # ========================================================
    # JMP
    # ========================================================

    elif mnemonic == "JMP":

        if len(operands) != 1:
            error(
                "JMP syntax: JMP ADDR",
                line_number
            )

        imm = parse_imm12_unsigned(
            operands[0],
            labels,
            line_number
        )

    # ========================================================
    # JMP_IF
    # ========================================================

    elif mnemonic == "JMP_IF":

        if len(operands) != 2:
            error(
                "JMP_IF syntax: JMP_IF Rs1, ADDR",
                line_number
            )

        rs1 = parse_register(operands[0], line_number)

        imm = parse_imm12_unsigned(
            operands[1],
            labels,
            line_number
        )

    # ========================================================
    # BRANCHES
    # ========================================================

    elif mnemonic in BRANCH:

        if len(operands) != 1:
            error(
                f"{mnemonic} syntax: {mnemonic} ADDR",
                line_number
            )

        # Branches use PSR flags.
        # No register fields are required.

        imm = parse_imm12_unsigned(
            operands[0],
            labels,
            line_number
        )

    # ========================================================
    # JMP_REG
    # ========================================================

    elif mnemonic == "JMP_REG":

        if len(operands) != 1:
            error(
                "JMP_REG syntax: JMP_REG Rs1",
                line_number
            )

        rs1 = parse_register(operands[0], line_number)

    # ========================================================
    # LOAD_IMM
    # ========================================================

    elif mnemonic == "LOAD_IMM":

        if len(operands) != 2:
            error(
                "LOAD_IMM syntax: LOAD_IMM Rd, IMM",
                line_number
            )

        rd = parse_register(operands[0], line_number)

        imm = parse_imm12_zero_extended(
            operands[1],
            line_number
        )

    # ========================================================
    # LUI
    # ========================================================

    elif mnemonic == "LUI":

        if len(operands) != 2:
            error(
                "LUI syntax: LUI Rd, IMM",
                line_number
            )

        rd = parse_register(operands[0], line_number)

        imm = parse_imm12_zero_extended(
            operands[1],
            line_number
        )

    # ========================================================
    # BUILD 32-BIT INSTRUCTION
    # ========================================================

    instruction = (
        (opcode << 24) |
        (rd     << 20) |
        (rs1    << 16) |
        (rs2    << 12) |
        imm
    )

    return instruction


# ============================================================
# SECOND PASS
# ============================================================

def second_pass(lines, labels):

    machine_code = []

    for line_number, original_line in enumerate(lines, start=1):

        line = clean_line(original_line)

        if not line:
            continue

        # Remove label-only lines
        if ":" in line:

            remaining = line.split(":", 1)[1].strip()

            if not remaining:
                continue

        instruction = encode_instruction(
            line,
            labels,
            line_number
        )

        if instruction is not None:
            machine_code.append(instruction)

    return machine_code


# ============================================================
# WRITE HEX FILE
# ============================================================

def write_hex(machine_code, output_file):

    with open(output_file, "w") as f:

        for instruction in machine_code:

            # 32-bit instruction = exactly 8 hexadecimal digits
            f.write(f"{instruction:08X}\n")


# ============================================================
# MAIN
# ============================================================

def main():

    if len(sys.argv) < 2 or len(sys.argv) > 3:

        print(
            "Usage:\n"
            "  python assembler.py program.asm\n"
            "  python assembler.py program.asm program.hex"
        )

        sys.exit(1)

    input_file = Path(sys.argv[1])

    if not input_file.exists():

        print(f"Error: file '{input_file}' not found.")
        sys.exit(1)

    # If output file isn't supplied,
    # automatically use same filename with .hex extension.

    if len(sys.argv) == 3:
        output_file = Path(sys.argv[2])
    else:
        output_file = input_file.with_suffix(".hex")

    try:

        # ----------------------------------------------------
        # Read source
        # ----------------------------------------------------

        with open(input_file, "r") as f:
            lines = f.readlines()

        # ----------------------------------------------------
        # PASS 1
        # ----------------------------------------------------

        labels = first_pass(lines)

        # ----------------------------------------------------
        # PASS 2
        # ----------------------------------------------------

        machine_code = second_pass(
            lines,
            labels
        )

        # ----------------------------------------------------
        # WRITE HEX
        # ----------------------------------------------------

        write_hex(
            machine_code,
            output_file
        )

        print("Assembly successful!")
        print(f"Input : {input_file}")
        print(f"Output: {output_file}")
        print(f"Instructions: {len(machine_code)}")

        if labels:
            print("\nLabels:")
            for label, address in labels.items():
                print(f"  {label} = {address}")

    except ValueError as e:

        print(f"Assembly error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()