# Test program

        LOAD_IMM x1, 0x100
        LOAD_IMM x2, 0x00A 
        LOAD_IMM x3, 0x000 
        LOAD_IMM x4, 0x000 
loop:   
        CMP      x4, x2        
        BGE      done          
        ADD      x5, x1, x4    
        LOAD_IND x6, x5     
        ADD      x3, x3, x6    
        ADDI     x4, x4, 0x001 
        JMP      loop
done:   
        STORE    x3, 0x200 
        HALT
