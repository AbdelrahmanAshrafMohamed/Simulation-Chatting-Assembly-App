                  .MODEL SMALL                                                                                                   
.STACK 64        
;------------------------------------------------------                    
.DATA
FORBIDDEN_CHAR              DB ?

COMMAND_NUMBER              DB ?

MEMORY_ADDRESSING_MODE      DB ?

DEST_REG_NUM                DB ?
DEST_MEMORY_ADDRESS         DB 5, ?, 5 DUP(0)
DEST_OPTION                 DB ?
DEST_MEMORY_ADDRESS_NUMBER  DW ?
DEST_REG_16_8_ADDRESS       DW ?

SRC_REG_NUM                 DB ?
SRC_MEMORY_ADDRESS          DB 5, ?, 5 DUP(0)
SRC_IMMEDIATE_VALUE         DB 5, ?, 5 DUP(0)
SRC_OPTION                  DB ?
SRC_MEMORY_ADDRESS_NUMBER   DW ?
SRC_IMMEDIATE_VALUE_NUMBER  DW ?
SRC_REG_16_VALUE            DW ?
SRC_REG_8_VALUE             DB ?

VAX DW 0
VBX DW 0
VCX DW 0
VDX DW 0
VSI DW 0
VDI DW 0
VSP DW 0
VBP DW 0					

COMMAND_AND_REG_NAMES               DB 'mov', 'ax', 'bx', 'cx', 'dx', 'si', 'di', 'sp', 'bp', 'al', 'ah', 'bl', 'bh', 'cl', 'ch', 'dl', 'dh', '0000', '0000', '0000'    ;   last 3 for src_address, src_immediate_value, dest_address
COMMAND_AND_REG_NAMES_START_INDEX   DB  0,     3,    5,    7,    9,    11,   13,   15,   17,   19,   21,   23,   25,   27,   29,   31,   33,   35,     39,     43
COMMAND_AND_REG_NAMES_END_INDEX     DB  2,     4,    6,    8,    10,   12,   14,   16,   18,   20,   22,   24,   26,   28,   30,   32,   34,   38,     42,     46

VSTACK DW 50 DUP(?)

;------------------------------------------------------
.CODE

CONVERT_ASCII_TO_NUMBER MACRO ASCII_ADDRESS, NUM_ADDRESS
    
    LOCAL CONVERT_LOOP, GREATER_THAN_9, CONVERT, WEIGHT_LOOP_1, NOT_1ST_DIGIT, WEIGHT_LOOP_2, NOT_2ND_DIGIT, WEIGHT_LOOP_3, NOT_3RD_DIGIT, NEXT, INVALID_DIGIT
    
    MOV SI, ASCII_ADDRESS
    MOV DI, NUM_ADDRESS
            MOV CL, 4
            CONVERT_LOOP:
                MOV CH, [SI]
                CMP CH, 30H
                JL  INVALID_DIGIT
                ;   ASCII >= 30H
                CMP CH, 39H
                JG  GREATER_THAN_9
                ;   0 <= DIGIT <= 9
                SUB CH, 30H
                JMP CONVERT
                
                GREATER_THAN_9:
                CMP CH, 61H
                JL  INVALID_DIGIT
                
                CMP CH, 66H
                JG  INVALID_DIGIT
                ;   A <= DIGIT <= F
                SUB CH, 57H
                
                CONVERT:
                CMP CL, 4
                JNE NOT_1ST_DIGIT
                ;   MULTIPLY BY 1000H
                WEIGHT_LOOP_1:
                    ADD [NUM_ADDRESS], 1000H
                    DEC CH
                    JNZ WEIGHT_LOOP_1
                JMP NEXT
                
                NOT_1ST_DIGIT:
                CMP CL, 3
                JNE NOT_2ND_DIGIT
                ;   MULTIPLY BY 100
                WEIGHT_LOOP_2:
                    ADD [NUM_ADDRESS], 100H
                    DEC CH
                    JNZ WEIGHT_LOOP_2
                JMP NEXT
                
                NOT_2ND_DIGIT:
                CMP CL, 2
                JNE NOT_3RD_DIGIT
                ;   MULTIPLY BY 100
                WEIGHT_LOOP_3:
                    ADD [NUM_ADDRESS], 10H
                    DEC CH
                    JNZ WEIGHT_LOOP_3
                JMP NEXT
                    
                NOT_3RD_DIGIT:
                ;ADD BYTE PTR SRC_IMMEDIATE_VALUE_NUMBER, CH
                ADD [NUM_ADDRESS], CH
                
                NEXT:    
                
                
                INC SI
                DEC CL
                JNZ CONVERT_LOOP
                
                INVALID_DIGIT:
ENDM

EXE_MOVE_COMMAND MACRO
    ;   SRC  => SI, DL, SRC_IMMEDIATE_VALUE_NUMBER, SRC_MEMORY_ADDRESS_NUMBER
    ;   DEST => DI, DEST_MEMORY_ADDRESS_NUMBER
    LOCAL SRC_NOT_REG_DEST_16_BIT_REG, SRC_NOT_MEMORY_DEST_16_BIT_REG, DEST_REG_IS_8_BIT, SRC_NOT_REG_DEST_8_BIT_REG, SRC_NOT_MEMORY_DEST_8_BIT_REG, DEST_IS_MEMORY, SRC_REG_8_BIT_WITH_MEMORY_DEST, SRC_NOT_REG_WITH_MEMORY_DEST, SRC_NOT_MEMORY_WITH_MEMORY_DEST
    
    CMP DEST_OPTION, 1
    JNE DEST_IS_MEMORY
    ;   DEST IS REG
    
    
    CMP DEST_REG_NUM, 7
    JG  DEST_REG_IS_8_BIT
    ;   DEST REG IS 16 BIT
    
    CMP SRC_OPTION, 1
    JNE SRC_NOT_REG_DEST_16_BIT_REG
    ;   SRC IS REGISTER
    ;   CHECKING IF SRC REGISTER IS 16 BIT
    CMP SRC_REG_NUM, 7
    JG  SIZE_MISMATCH_ERROR
    ;   SRC IS 16 REG
    MOV SI, SRC_REG_16_VALUE
    MOV [DI], SI
    JMP COMMAND_EXECUTED
    
    SRC_NOT_REG_DEST_16_BIT_REG:
    CMP SRC_OPTION, 2
    JNE SRC_NOT_MEMORY_DEST_16_BIT_REG
    ;   SRC IS MEMORY
    MOV BX, SRC_MEMORY_ADDRESS_NUMBER
    MOV DX, [BX]
    MOV BX, DEST_REG_16_8_ADDRESS
    MOV [BX], DX
    JMP COMMAND_EXECUTED
            
    SRC_NOT_MEMORY_DEST_16_BIT_REG:
    ;   SRC IS IMMEDIATE VALUE
    MOV DX, SRC_IMMEDIATE_VALUE_NUMBER
    MOV BX, DEST_REG_16_8_ADDRESS
    MOV [BX], DX
    JMP COMMAND_EXECUTED
    
    
    DEST_REG_IS_8_BIT:
    
    CMP SRC_OPTION, 1
    JNE SRC_NOT_REG_DEST_8_BIT_REG
    ;   SRC IS REGISTER
    ;   CHECKING IF SRC REGISTER IS 8 BIT
    CMP SRC_REG_NUM, 8
    JL  SIZE_MISMATCH_ERROR
    ;   SRC IS 8 REG
    MOV BX, DEST_REG_16_8_ADDRESS
    MOV DL, SRC_REG_8_VALUE
    MOV [BX], DL
    JMP COMMAND_EXECUTED
    
    SRC_NOT_REG_DEST_8_BIT_REG:
    CMP SRC_OPTION, 2
    JNE SRC_NOT_MEMORY_DEST_8_BIT_REG
    ;   SRC IS MEMORY
    MOV BX, SRC_MEMORY_ADDRESS_NUMBER
    MOV DL, [BX]
    MOV BX, DEST_REG_16_8_ADDRESS
    MOV [BX], DL
    JMP COMMAND_EXECUTED
            
    SRC_NOT_MEMORY_DEST_8_BIT_REG:
    ;   SRC IS IMMEDIATE VALUE
    CMP SRC_IMMEDIATE_VALUE_NUMBER, 0FFH
    JG  SIZE_MISMATCH_ERROR
    ;   IMMEDIATE VALUE SIZE IS CORRECT
    MOV DL, BYTE PTR SRC_IMMEDIATE_VALUE_NUMBER
    MOV BX, DEST_REG_16_8_ADDRESS
    MOV [BX], DL
    JMP COMMAND_EXECUTED
    
    
    DEST_IS_MEMORY:
    
    CMP SRC_OPTION, 1
    JNE SRC_NOT_REG_WITH_MEMORY_DEST
    ;   SRC IS REG 
    
    CMP SRC_REG_NUM, 7
    JG  SRC_REG_8_BIT_WITH_MEMORY_DEST
    ;   SRC REG IS 16 BIT
    
    MOV BX, DEST_MEMORY_ADDRESS_NUMBER
    MOV SI, SRC_REG_16_VALUE
    MOV [BX], SI
    JMP COMMAND_EXECUTED
    
    SRC_REG_8_BIT_WITH_MEMORY_DEST:
    ;   SRC REG IS 8 BIT
    
    MOV BX, DEST_MEMORY_ADDRESS_NUMBER
    MOV DL, SRC_REG_8_VALUE
    MOV [BX], DL
    JMP COMMAND_EXECUTED
    
    SRC_NOT_REG_WITH_MEMORY_DEST:
    CMP SRC_OPTION, 2
    JNE SRC_NOT_MEMORY_WITH_MEMORY_DEST
    ;   SRC IS MEMORY 
    
    JMP MEMORY_TO_MEMORY_OPERATION_ERROR
            
    SRC_NOT_MEMORY_WITH_MEMORY_DEST:
    ;   SRC IS VALUE 
    
    MOV BX, DEST_MEMORY_ADDRESS_NUMBER
    MOV DX, SRC_IMMEDIATE_VALUE_NUMBER
    MOV [BX], DX
    JMP COMMAND_EXECUTED

    
ENDM

CHECK_FORBIDDEN_CHAR MACRO STR_NUM
    LOCAL CHECKING_LOOP, NOT_FORBIDDEN_STR
    MOV BX, STR_NUM
    MOV AL, FORBIDDEN_CHAR
    MOV CL, COMMAND_AND_REG_NAMES_START_INDEX[BX]
    MOV CH, 0
    MOV SI, CX
    MOV CL, COMMAND_AND_REG_NAMES_END_INDEX[BX]
    MOV DI, CX
    CHECKING_LOOP:
        CMP COMMAND_AND_REG_NAMES[SI], AL
        JE  FORBIDDEN_STR
        CMP SI, DI
        JE  NOT_FORBIDDEN_STR
        INC SI
    JMP CHECKING_LOOP
    NOT_FORBIDDEN_STR:
ENDM
                                                 
MAIN    PROC FAR        
        MOV AX,@DATA    
        MOV DS,AX
        MOV ES,AX   

        ;   READING FORBIDDEN CHARACTER
        MOV AH, 0
        INT 16h
        MOV FORBIDDEN_CHAR, AL

        MAIN_LOOP:
            ;   READING COMMAND NUMBER
            MOV AH, 0
            INT 16h
            CMP AL, 30H
            JL  INVALID_COMMAND
            CMP AL, 66H
            JG  INVALID_COMMAND
            CMP AL, 40H
            JL  VALID_COMMAND
            CMP AL, 61H
            JL  INVALID_COMMAND
            SUB AL, 57H
            JMP CHECK_FORBIDDEN_CHAR
            
            VALID_COMMAND:
            SUB AL, 30H
            
            CHECK_FORBIDDEN_CHAR:
            CBW
            PUSH AX
            CHECK_FORBIDDEN_CHAR AX
            POP AX
            MOV COMMAND_NUMBER, AL
        
            READ_DEST_OPTION:
            ;   READING DEST OPTION
            MOV AH, 0
            INT 16h
            
            CMP AL, 31H       ;   CHECK IF 1 PRESSED (REG)
            JNE DEST_NOT_REG
            ;   READING REGISTER NUMBER
            MOV DEST_OPTION, 1          ;   DESTINATION IS A REG
            
            ;   READING REG NUMBER
            READ_DEST_REG_NUMBER:
            MOV AH, 0
            INT 16h
            
            CMP AL, 30H       
            JNE DEST_REG_NOT_AX
            PUSHA
            CHECK_FORBIDDEN_CHAR 1
            POPA
            MOV DEST_REG_NUM, 0                 ;   DESTINATION REG  IS AX
            LEA DI, VAX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_AX:
            CMP AL, 31H       
            JNE DEST_REG_NOT_BX
            PUSHA
            CHECK_FORBIDDEN_CHAR 2
            POPA
            MOV DEST_REG_NUM, 1                 ;   DESTINATION REG  IS BX
            LEA DI, VBX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_BX:
            CMP AL, 32H      
            JNE DEST_REG_NOT_CX
            PUSHA
            CHECK_FORBIDDEN_CHAR 3
            POPA
            MOV DEST_REG_NUM, 2                 ;   DESTINATION REG  IS CX
            LEA DI, VCX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_CX:
            CMP AL, 33H      
            JNE DEST_REG_NOT_DX
            PUSHA
            CHECK_FORBIDDEN_CHAR 4
            POPA
            MOV DEST_REG_NUM, 3                 ;   DESTINATION REG  IS DX
            LEA DI, VDX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_DX:
            CMP AL, 34H       
            JNE DEST_REG_NOT_SI
            PUSHA
            CHECK_FORBIDDEN_CHAR 5
            POPA
            MOV DEST_REG_NUM, 4                 ;   DESTINATION REG  IS SI
            LEA DI, VSI
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_SI:
            CMP AL, 35H      
            JNE DEST_REG_NOT_DI
            PUSHA
            CHECK_FORBIDDEN_CHAR 6
            POPA
            MOV DEST_REG_NUM, 5                 ;   DESTINATION REG  IS DI
            LEA DI, VDI
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION                                          
            
            DEST_REG_NOT_DI:
            CMP AL, 36H      
            JNE DEST_REG_NOT_SP
            PUSHA
            CHECK_FORBIDDEN_CHAR 7
            POPA
            MOV DEST_REG_NUM, 6                 ;   DESTINATION REG  IS SP
            LEA DI, VSP
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_SP:
            CMP AL, 37H       
            JNE DEST_REG_NOT_BP
            PUSHA
            CHECK_FORBIDDEN_CHAR 8
            POPA
            MOV DEST_REG_NUM, 7                 ;   DESTINATION REG  IS BP
            LEA DI, VBP
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
                        
            DEST_REG_NOT_BP:
            CMP AL, 38H      
            JNE DEST_REG_NOT_AL
            PUSHA
            CHECK_FORBIDDEN_CHAR 9
            POPA
            MOV DEST_REG_NUM, 8                 ;   DESTINATION REG  IS AL
            LEA DI, VAX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_AL:
            CMP AL, 39H      
            JNE DEST_REG_NOT_AH
            PUSHA
            CHECK_FORBIDDEN_CHAR 10
            POPA
            MOV DEST_REG_NUM, 9                 ;   DESTINATION REG  IS AH
            LEA DI, VAX
            INC DI
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_AH:
            CMP AL, 61H      
            JNE DEST_REG_NOT_BL
            PUSHA
            CHECK_FORBIDDEN_CHAR 11
            POPA
            MOV DEST_REG_NUM, 10                 ;   DESTINATION REG  IS BL
            LEA DI, VBX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_BL:
            CMP AL, 62H      
            JNE DEST_REG_NOT_BH
            PUSHA
            CHECK_FORBIDDEN_CHAR 12
            POPA
            MOV DEST_REG_NUM, 11                 ;   DESTINATION REG  IS BH
            LEA DI, VBX
            INC DI
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_BH:
            CMP AL, 63H      
            JNE DEST_REG_NOT_CL
            PUSHA
            CHECK_FORBIDDEN_CHAR 13
            POPA
            MOV DEST_REG_NUM, 12                 ;   DESTINATION REG  IS CL
            LEA DI, VCX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_CL:
            CMP AL, 64H       
            JNE DEST_REG_NOT_CH
            PUSHA
            CHECK_FORBIDDEN_CHAR 14
            POPA
            MOV DEST_REG_NUM, 13                 ;   DESTINATION REG  IS CH
            LEA DI, VCX
            INC DI     
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_CH:
            CMP AL, 65H       
            JNE DEST_REG_NOT_DL
            PUSHA
            CHECK_FORBIDDEN_CHAR 15
            POPA
            MOV DEST_REG_NUM, 14                 ;   DESTINATION REG  IS DL
            LEA DI, VDX
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            DEST_REG_NOT_DL:
            CMP AL, 66H       
            JNE INVALID_DEST_REG_NUMBER
            PUSHA
            CHECK_FORBIDDEN_CHAR 16
            POPA
            MOV DEST_REG_NUM, 15                 ;   DESTINATION REG  IS DH
            LEA DI, VDX
            INC DI
            MOV DEST_REG_16_8_ADDRESS, DI
            JMP READ_SRC_OPTION
            
            INVALID_DEST_REG_NUMBER:
            JMP READ_DEST_REG_NUMBER
            
            DEST_NOT_REG:
            CMP AL, 32H       ;   CHECK IF 2 PRESSED (MEMORY)
            JNE INVALID_DEST_OPTION
            MOV DEST_OPTION, 2
            
            READING_DEST_MEMORY_ADDRESSING_MODE:
            MOV AH, 0
            INT 16h
            CMP AL, 31H
            JNE DEST_MEMORY_ADDRESSING_MODE_NOT_DIRECT

            ;   READING DEST MEMORY LOCATION
            MOV AH, 0AH
            MOV DX, OFFSET DEST_MEMORY_ADDRESS
            INT 21h
            JMP CONVERT_DEST_MEMORY_ADDRESS

            DEST_MEMORY_ADDRESSING_MODE_NOT_DIRECT:
            CMP AL, 32H
            JNE READING_DEST_MEMORY_ADDRESSING_MODE
            READING_DEST_MEMORY_REG_NUMBER:
            MOV AH, 0
            INT 16h
            CMP AL, 31H
            JNE DEST_MEMORY_REG_NOT_BX
            PUSHA
            CHECK_FORBIDDEN_CHAR 2
            POPA
            MOV DEST_MEMORY_ADDRESS_NUMBER, BX
            JMP READ_SRC_OPTION

            DEST_MEMORY_REG_NOT_BX:
            CMP AL, 34H
            JNE DEST_MEMORY_REG_NOT_SI
            PUSHA
            CHECK_FORBIDDEN_CHAR 5
            POPA
            MOV DEST_MEMORY_ADDRESS_NUMBER, SI
            JMP READ_SRC_OPTION

            DEST_MEMORY_REG_NOT_SI:
            CMP AL, 35H
            JNE READING_DEST_MEMORY_REG_NUMBER
            PUSHA
            CHECK_FORBIDDEN_CHAR 6
            POPA
            MOV DEST_MEMORY_ADDRESS_NUMBER, DI
            JMP READ_SRC_OPTION

            ;   CONVERTING ASCII TO NUMBERS
            CONVERT_DEST_MEMORY_ADDRESS:
            PUSHA
            LEA SI, DEST_MEMORY_ADDRESS+2
            LEA DI, COMMAND_AND_REG_NAMES[43]
            MOV CX, 2
            REP MOVSW
            CHECK_FORBIDDEN_CHAR 19
            MOV DEST_MEMORY_ADDRESS_NUMBER, 0
            LEA SI, DEST_MEMORY_ADDRESS+2
            LEA DI, DEST_MEMORY_ADDRESS_NUMBER
            CONVERT_ASCII_TO_NUMBER SI, DI
            POPA
            ;ADD DEST_MEMORY_ADDRESS_NUMBER, 1000H   ;   SHIFTING VIRTUAL DS
            JMP READ_SRC_OPTION
            
            INVALID_DEST_OPTION:
            ;   READ DEST OPTION AGAIN
            JMP READ_DEST_OPTION

            READ_SRC_OPTION:
            ;   READING SRC OPTION
            MOV AH, 0
            INT 16h
            
            CMP AL, 31H       ;   CHECK IF 1 PRESSED (REG)
            JNE SRC_NOT_REG
            
            ;   SOURCE IS A REG
            MOV SRC_OPTION, 1                  
            
            ;   READING REG NUMBER
            READ_SRC_REG_NUMBER:
            MOV AH, 0
            INT 16h
            
            CMP AL, 30H
            JNE SRC_REG_NOT_AX
            PUSHA
            CHECK_FORBIDDEN_CHAR 1
            POPA
            MOV SRC_REG_NUM, 0                 ;   SOURCE REG  IS AX
            MOV SI, VAX
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_AX:
            CMP AL, 31H
            JNE SRC_REG_NOT_BX
            PUSHA
            CHECK_FORBIDDEN_CHAR 2
            POPA
            MOV SRC_REG_NUM, 1                 ;   SOURCE REG  IS BX
            MOV SI, VBX
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_BX:
            CMP AL, 32H
            JNE SRC_REG_NOT_CX
            PUSHA
            CHECK_FORBIDDEN_CHAR 3
            POPA
            MOV SRC_REG_NUM, 2                 ;   SOURCE REG  IS CX
            MOV SI, VCX
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_CX:
            CMP AL, 33H       
            JNE SRC_REG_NOT_DX
            PUSHA
            CHECK_FORBIDDEN_CHAR 4
            POPA
            MOV SRC_REG_NUM, 3                 ;   SOURCE REG  IS DX
            MOV SI, VDX
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_DX:
            CMP AL, 34H       
            JNE SRC_REG_NOT_SI
            PUSHA
            CHECK_FORBIDDEN_CHAR 5
            POPA
            MOV SRC_REG_NUM, 4                 ;   SOURCE REG  IS SI
            MOV SI, VSI
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_SI:
            CMP AL, 35H       
            JNE SRC_REG_NOT_DI
            PUSHA
            CHECK_FORBIDDEN_CHAR 6
            POPA
            MOV SRC_REG_NUM, 5                 ;   SOURCE REG  IS DI
            MOV SI, VDI
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND                                          
            
            SRC_REG_NOT_DI:
            CMP AL, 36H       
            JNE SRC_REG_NOT_SP
            PUSHA
            CHECK_FORBIDDEN_CHAR 7
            POPA
            MOV SRC_REG_NUM, 6                 ;   SOURCE REG  IS SP
            MOV SI, VSP
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_SP:
            CMP AL, 37       
            JNE SRC_REG_NOT_BP
            PUSHA
            CHECK_FORBIDDEN_CHAR 8
            POPA
            MOV SRC_REG_NUM, 7                 ;   SOURCE REG  IS BP
            MOV SI, VBP
            MOV SRC_REG_16_VALUE, SI
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_BP:
            CMP AL, 38H       
            JNE SRC_REG_NOT_AL
            PUSHA
            CHECK_FORBIDDEN_CHAR 9
            POPA
            MOV SRC_REG_NUM, 8                 ;   SOURCE REG  IS AL
            MOV DL, BYTE PTR VAX
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_AL:
            CMP AL, 39H       
            JNE SRC_REG_NOT_AH
            PUSHA
            CHECK_FORBIDDEN_CHAR 10
            POPA
            MOV SRC_REG_NUM, 9                 ;   SOURCE REG  IS AH
            MOV DL, BYTE PTR VAX+1
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_AH:
            CMP AL, 61H       
            JNE SRC_REG_NOT_BL
            PUSHA
            CHECK_FORBIDDEN_CHAR 11
            POPA
            MOV SRC_REG_NUM, 10                 ;   SOURCE REG  IS BL
            MOV DL, BYTE PTR VBX
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND 
            
            SRC_REG_NOT_BL:
            CMP AL, 62H       
            JNE SRC_REG_NOT_BH
            PUSHA
            CHECK_FORBIDDEN_CHAR 12
            POPA
            MOV SRC_REG_NUM, 11                 ;   SOURCE REG  IS BH
            MOV DL, BYTE PTR VBX+1
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_BH:
            CMP AL, 63H       
            JNE SRC_REG_NOT_CL
            PUSHA
            CHECK_FORBIDDEN_CHAR 13
            POPA
            MOV SRC_REG_NUM, 12                 ;   SOURCE REG  IS CL
            MOV DL, BYTE PTR VCX
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_CL:
            CMP AL, 64H       
            JNE SRC_REG_NOT_CH
            PUSHA
            CHECK_FORBIDDEN_CHAR 14
            POPA
            MOV SRC_REG_NUM, 13                 ;   SOURCE REG  IS CH
            MOV DL, BYTE PTR VCX+1
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_CH:
            CMP AL, 65H       
            JNE SRC_REG_NOT_DL
            PUSHA
            CHECK_FORBIDDEN_CHAR 15
            POPA
            MOV SRC_REG_NUM, 14                 ;   SOURCE REG  IS DL
            MOV DL, BYTE PTR VDX
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND
            
            SRC_REG_NOT_DL:
            CMP AL, 66H        
            JNE INVALID_SRC_REG_NUMBER
            PUSHA
            CHECK_FORBIDDEN_CHAR 16
            POPA
            MOV SRC_REG_NUM, 15                 ;   SOURCE REG  IS DH
            MOV DL, BYTE PTR VDX+1
            MOV SRC_REG_8_VALUE, DL
            JMP EXECUTE_COMMAND
            
            INVALID_SRC_REG_NUMBER:
            JMP READ_SRC_REG_NUMBER
            
            SRC_NOT_REG:
            CMP AL, 32H       ;   CHECK IF 2 PRESSED (MEMORY)
            JNE SRC_NOT_MEMORY
            MOV SRC_OPTION, 2

            READING_SRC_MEMORY_ADDRESSING_MODE:
            MOV AH, 0
            INT 16h
            CMP AL, 31H
            JNE SRC_MEMORY_ADDRESSING_MODE_NOT_DIRECT

            ;   READING SRC MEMORY LOCATION
            MOV AH, 0AH
            MOV DX, OFFSET SRC_MEMORY_ADDRESS
            INT 21h
            JMP CONVERT_SRC_MEMORY_ADDRESS

            SRC_MEMORY_ADDRESSING_MODE_NOT_DIRECT:
            CMP AL, 32H
            JNE READING_SRC_MEMORY_ADDRESSING_MODE
            READING_SRC_MEMORY_REG_NUMBER:
            MOV AH, 0
            INT 16h
            CMP AL, 31H
            JNE SRC_MEMORY_REG_NOT_BX
            PUSHA
            CHECK_FORBIDDEN_CHAR 2
            POPA
            MOV SRC_MEMORY_ADDRESS_NUMBER, BX
            JMP EXECUTE_COMMAND

            SRC_MEMORY_REG_NOT_BX:
            CMP AL, 34H
            JNE SRC_MEMORY_REG_NOT_SI
            PUSHA
            CHECK_FORBIDDEN_CHAR 5
            POPA
            MOV SRC_MEMORY_ADDRESS_NUMBER, SI
            JMP EXECUTE_COMMAND

            SRC_MEMORY_REG_NOT_SI:
            CMP AL, 35H
            JNE READING_SRC_MEMORY_REG_NUMBER
            PUSHA
            CHECK_FORBIDDEN_CHAR 6
            POPA
            MOV SRC_MEMORY_ADDRESS_NUMBER, DI
            JMP EXECUTE_COMMAND

            
            CONVERT_SRC_MEMORY_ADDRESS:
            PUSHA
            LEA SI, SRC_MEMORY_ADDRESS+2
            LEA DI, COMMAND_AND_REG_NAMES[35]
            MOV CX, 2
            REP MOVSW
            CHECK_FORBIDDEN_CHAR 17
            MOV SRC_MEMORY_ADDRESS_NUMBER, 0
            LEA SI, SRC_MEMORY_ADDRESS+2
            LEA DI, SRC_MEMORY_ADDRESS_NUMBER
            CONVERT_ASCII_TO_NUMBER SI, DI
            POPA
            ;ADD SRC_MEMORY_ADDRESS_NUMBER, 1000H    ;   SHIFTING VIRTUAL DS
            JMP EXECUTE_COMMAND
            
            SRC_NOT_MEMORY:
            CMP AL, 33H       ;   CHECK IF 3 PRESSED (IMMEDIATE)
            JNE INVALID_SRC_OPTION
            MOV SRC_OPTION, 3
            ;   READING SRC IMMEDIATE VALUE
            MOV AH, 0AH
            MOV DX, OFFSET SRC_IMMEDIATE_VALUE
            INT 21h
            
            ;   CHECKING FORBIDDEN CHAR AND CONVERTING ASCII TO NUMBERS
            PUSHA
            LEA SI, SRC_IMMEDIATE_VALUE+2
            LEA DI, COMMAND_AND_REG_NAMES[39]
            MOV CX, 2
            REP MOVSW
            CHECK_FORBIDDEN_CHAR 18
            MOV SRC_IMMEDIATE_VALUE_NUMBER, 0
            LEA SI, SRC_IMMEDIATE_VALUE+2
            LEA DI, SRC_IMMEDIATE_VALUE_NUMBER
            CONVERT_ASCII_TO_NUMBER SI, DI
            POPA
            JMP EXECUTE_COMMAND
            
            INVALID_SRC_OPTION:
            JMP READ_SRC_OPTION
            
            EXECUTE_COMMAND:
            
            CMP COMMAND_NUMBER, 0
            JNE NOT_MOV_COMMAND
            
            EXE_MOVE_COMMAND
            
            NOT_MOV_COMMAND:
            
            COMMAND_EXECUTED:
            ;   SEE RESULTS AFTER THIS COMMAND
            PUSHA
            MOV AX, VAX
            MOV BX, VBX
            MOV CX, VCX
            MOV DX, VDX
            MOV SI, VSI
            MOV DI, VDI
            MOV SP, VSP
            MOV BP, VBP
            
            MOV AH, 0
            INT 16H
            POPA
            
            SIZE_MISMATCH_ERROR:
            MEMORY_TO_MEMORY_OPERATION_ERROR:
            INVALID_COMMAND:
            FORBIDDEN_STR:
        JMP MAIN_LOOP
hlt
MAIN    ENDP
END MAIN
		