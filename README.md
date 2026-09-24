# Project_CPU_Lite
Single Issue CPU lite version with non-pipelined processor design.


****Instruction Set:****
**Mnemonic	        Opcode	        Fields used	            Operation**
# No Operation (Stall)
NOP		            00	            —		                No operation.
# Load/Store Instructions
LOAD		        01	            Rd, ADDR	            Rd ← DATA[ADDR]  (via cache)
LOAD_IND	        02	            Rd, Rs1		            Rd ← DATA[Rs1]  (via cache)
STORE		        04	            Rd(src), ADDR	        DATA[ADDR] ← Rd  (through cache)
STORE_IND	        05	            Rd(src), Rs2	        DATA[Rs2] ← Rd
# Register type Intructions
ADD		            06	            Rd, Rs1, Rs2	        Rd ← Rs1 + Rs2
SUB		            07	            Rd, Rs1, Rs2	        Rd ← Rs1 − Rs2
MUL		            08	            Rd, Rs1, Rs2	        Rd ← (Rs1 × Rs2)[31:0]
AND		            09	            Rd, Rs1, Rs2	        Rd ← Rs1 & Rs2
OR		            0A	            Rd, Rs1, Rs2	        Rd ← Rs1 | Rs2
NOT	    	        0B	            Rd, Rs1	                Rd ← ~Rs1
XOR		            10	            Rd, Rs1, Rs2	        Rd ← Rs1 ^ Rs2
CMP	    	        0C	            Rs1, Rs2	            flags ← (Rs1 − Rs2); no write-back
EQ	    	        0D	            Rd, Rs1, Rs2	        Rd ← (Rs1 == Rs2) ? 1 : 0
ADDI		        16	            Rd, Rs1, IMM	        Rd ← Rs1 + sign_ext(IMM)
SUBI		        17	            Rd, Rs1, IMM	        Rd ← Rs1 − sign_ext(IMM)
SHL	    	        11	            Rd, Rs1, Rs2	        Rd ← Rs1 << Rs2[4:0]  (logical)
SHR	    	        12	            Rd, Rs1, Rs2	        Rd ← Rs1 >> Rs2[4:0]  (logical)
SAR	    	        13	            Rd, Rs1, Rs2	        Rd ← Rs1 >>> Rs2[4:0]  (arithmetic)
ROL / ROR		    14 / 15		    Rd, Rs1, Rs2	        Rotate left / right by Rs2[4:0]
ANDI / ORI / XORI	18 / 19 / 1A	Rd, Rs1, IMM	        Logical op with zero_ext(IMM)
MOV			        1B		        Rd, Rs1		            Rd ← Rs1
SLT / SLTU		    1C / 1D		    Rd, Rs1, Rs2	        Rd ← (Rs1 < Rs2) ? 1 : 0  (signed / unsigned)
LUI			        1E		        Rd, IMM		            Rd ← {IMM, 20’b0}
LOAD_IMM	        03	            Rd, IMM		            Rd ← zero_ext(IMM)
# Branch Intructions
JMP	    	        0E	            ADDR	                PC ← ADDR
JMP_IF	            0F	            Rs1, ADDR	            if (Rs1 ≠ 0) PC ← ADDR
BEQ	    	        20	            ADDR	                if Z: PC ← ADDR
BNE	    	        21	            ADDR	                if ¬Z: PC ← ADDR
BLT	    	        22	            ADDR	                if (N ⊕ V): PC ← ADDR  (signed <)
BGE	    	        23	            ADDR	                if ¬(N ⊕ V): PC ← ADDR  (signed ≥)
BLTU / BGEU		    24 / 25		    ADDR		            Unsigned < / ≥ branch (uses if C = 0, BLTU valid | if C = 1, BGEU valid)
JMP_REG			    26		        Rs1		                PC ← Rs1[11:0]  (computed jump / return)
CALL / RET		    27 / 28		    ADDR / —		        Subroutine call / return (define a link register + stack)
# Stop 
HALT                FF	            —	                    Stop execution.



