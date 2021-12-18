                  .MODEL SMALL                                                                                                   
.STACK 64        
;------------------------------------------------------                    
.DATA

DEST_REG_NUM                DB ?
DEST_MEMORY_ADDRESS         DB 5, ?, 5 DUP(0)
DEST_OPTION                 DB ?
DEST_MEMORY_ADDRESS_NUMBER  DW ?

SRC_REG_NUM                 DB ?
SRC_MEMORY_ADDRESS          DB 5, ?, 5 DUP(0)
SRC_IMMEDIATE_VALUE         DB 5, ?, 5 DUP(0)
SRC_OPTION                  DB ?
SRC_MEMORY_ADDRESS_NUMBER   DW ?
SRC_IMMEDIATE_VALUE_NUMBER  DW ?

VAX DW 0
VBX DW 0
VCX DW 0
VDX DW 0
VSI DW 0
VDI DW 0
VSP DW 0
VBP DW 0					

VSTACK DW 50 DUP(?)

;------------------------------------------------------
.CODE

EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG MACRO DEST_ADDRESS
    LOCAL COMMAND_ONE_SOURC_OPTION_NOT_REGISTER, COMMAND_ONE_SOURC_OPTION_NOT_MEMORY
    ;   CHECKING IF SRC IS REG
    CMP SRC_OPTION, 1
    JNE COMMAND_ONE_SOURC_OPTION_NOT_REGISTER
    ;   SRC IS REGISTER
    ;   CHECKING IF SRC REGISTER IS 16 BIT
    CMP SRC_REG_NUM, 7
    JG  SIZE_MISMATCH_ERROR
    ;   MOVING VALUE OF THE SOURCE TO THE DESTINATION
    MOV BX, DEST_ADDRESS
    MOV [BX], SI
    JMP COMMAND_EXECUTED
    
    COMMAND_ONE_SOURC_OPTION_NOT_REGISTER:
    CMP SRC_OPTION, 2
    JNE COMMAND_ONE_SOURC_OPTION_NOT_MEMORY
    ;   SRC IS MEMORY
    MOV BX, SRC_MEMORY_ADDRESS_NUMBER
    MOV DX, [BX]
    MOV BX, DEST_ADDRESS
    MOV [BX], DX
    JMP COMMAND_EXECUTED
            
    COMMAND_ONE_SOURC_OPTION_NOT_MEMORY:
    ;   SRC IS IMMEDIATE VALUE
    MOV DX, SRC_IMMEDIATE_VALUE_NUMBER
    MOV BX, DEST_ADDRESS
    MOV [BX], DX
    JMP COMMAND_EXECUTED
    
ENDM


EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG MACRO DEST_ADDRESS
    LOCAL COMMAND_ONE_SOURC_OPTION_NOT_REGISTER, COMMAND_ONE_SOURC_OPTION_NOT_MEMORY
    ;   CHECKING IF SRC IS REG
    CMP SRC_OPTION, 1
    JNE COMMAND_ONE_SOURC_OPTION_NOT_REGISTER
    ;   SRC IS REGISTER
    ;   CHECKING IF SRC REGISTER IS 8 BIT
    CMP SRC_REG_NUM, 8
    JL  SIZE_MISMATCH_ERROR
    ;   MOVING VALUE OF THE SOURCE TO THE DESTINATION
    MOV BX, DEST_ADDRESS
    MOV [BX], DL
    JMP COMMAND_EXECUTED
    
    COMMAND_ONE_SOURC_OPTION_NOT_REGISTER:
    CMP SRC_OPTION, 2
    JNE COMMAND_ONE_SOURC_OPTION_NOT_MEMORY
    ;   SRC IS MEMORY
    MOV BX, SRC_MEMORY_ADDRESS_NUMBER
    MOV DL, [BX]
    MOV BX, DEST_ADDRESS
    MOV [BX], DL
    JMP COMMAND_EXECUTED
            
    COMMAND_ONE_SOURC_OPTION_NOT_MEMORY:
    ;   SRC IS IMMEDIATE VALUE
    MOV DL, BYTE PTR SRC_IMMEDIATE_VALUE_NUMBER
    MOV BX, DEST_ADDRESS
    MOV [BX], DL
    JMP COMMAND_EXECUTED
    
ENDM

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

                                                 
MAIN    PROC FAR        
        MOV AX,@DATA    
        MOV DS,AX   

        MAIN_LOOP:
            ;   READING COMMAND NUMBER
            MOV AH, 0
            INT 16h
            
            CMP AL, 30H      ;   CHECK IF 0 PRESSED (MOV COMMAND)
            JNE NOT_COMMAND_ONE
            ;   EXECUTEING COMMAND ONE (MOV)
            
            
            
            
            
            
            
            
             READ_SRC_OPTION:
            ;   READING SRC OPTION
            MOV AH, 0
            INT 16h
            
            CMP AL, 31H       ;   CHECK IF 1 PRESSED (REG)
            JNE COMMAND_ONE_SRC_OPTION_NOT_ONE
            ;   READING REGISTER NUMBER
            MOV SRC_OPTION, 1          ;   SOURCE IS A REG
            
            ;   READING REG NUMBER
            READ_SRC_REG_NUMBER:
            MOV AH, 0
            INT 16h
            
            CMP AL, 30H
            JNE COMMAND_ONE_SRC_REG_NOT_AX
            ;   REG AX IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 0                 ;   SOURCE REG  IS AX
            MOV SI, VAX
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_AX:
            CMP AL, 31H
            JNE COMMAND_ONE_SRC_REG_NOT_BX
            ;   REG BX IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 1                 ;   SOURCE REG  IS BX
            MOV SI, VBX
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_BX:
            CMP AL, 32H       ;   CX
            JNE COMMAND_ONE_SRC_REG_NOT_CX
            ;   REG CX IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 2                 ;   SOURCE REG  IS CX
            MOV SI, VCX
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_CX:
            CMP AL, 33H       ;   DX
            JNE COMMAND_ONE_SRC_REG_NOT_DX
            ;   REG DX IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 3                 ;   SOURCE REG  IS DX
            MOV SI, VDX
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_DX:
            CMP AL, 34H       ;   SI
            JNE COMMAND_ONE_SRC_REG_NOT_SI
            ;   REG SI IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 4                 ;   SOURCE REG  IS SI
            MOV SI, VSI
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_SI:
            CMP AL, 35H       ;   DI
            JNE COMMAND_ONE_SRC_REG_NOT_DI:
            ;   REG DI IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 5                 ;   SOURCE REG  IS DI
            MOV SI, VDI
            JMP READ_DEST_OPTION                                          
            
            COMMAND_ONE_SRC_REG_NOT_DI:
            CMP AL, 36H       ;   SP
            JNE COMMAND_ONE_SRC_REG_NOT_SP
            ;   REG SP IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 6                 ;   SOURCE REG  IS SP
            MOV SI, VSP
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_SP:
            CMP AL, 37       ;   BP
            JNE COMMAND_ONE_SRC_REG_NOT_BP
            ;   REG BP IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 7                 ;   SOURCE REG  IS BP
            MOV SI, VBP
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_BP:
            CMP AL, 38H       ;   AL
            JNE COMMAND_ONE_SRC_REG_NOT_AL
            ;   REG AL IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 8                 ;   SOURCE REG  IS AL
            MOV DL, BYTE PTR VAX
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_AL:
            CMP AL, 39H       ;   AH
            JNE COMMAND_ONE_SRC_REG_NOT_AH
            ;   REG AH IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 9                 ;   SOURCE REG  IS AH
            MOV DL, BYTE PTR VAX+1
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_AH:
            CMP AL, 61H       ;   BL
            JNE COMMAND_ONE_SRC_REG_NOT_BL
            ;   REG BL IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 10                 ;   SOURCE REG  IS BL
            MOV DL, BYTE PTR VBX
            JMP READ_DEST_OPTION 
            
            COMMAND_ONE_SRC_REG_NOT_BL:
            CMP AL, 62H       ;   BH
            JNE COMMAND_ONE_SRC_REG_NOT_BH
            ;   REG BH IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 11                 ;   SOURCE REG  IS BH
            MOV DL, BYTE PTR VBX+1
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_BH:
            CMP AL, 63H       ;   CL
            JNE COMMAND_ONE_SRC_REG_NOT_CL
            ;   REG CL IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 12                 ;   SOURCE REG  IS CL
            MOV DL, BYTE PTR VCX
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_CL:
            CMP AL, 64H       ;   CH
            JNE COMMAND_ONE_SRC_REG_NOT_CH
            ;   REG CH IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 13                 ;   SOURCE REG  IS CH
            MOV DL, BYTE PTR VCX+1
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_CH:
            CMP AL, 65H       ;   DL
            JNE COMMAND_ONE_SRC_REG_NOT_DL
            ;   REG DL IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 14                 ;   SOURCE REG  IS DL
            MOV DL, BYTE PTR VDX
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_REG_NOT_DL:
            CMP AL, 66H       ;   DH
            JNE INVALID_SRC_REG_NUMBER
            ;   REG DH IS CHOSEN AS SRC
            MOV SRC_REG_NUM, 15                 ;   SOURCE REG  IS DH
            MOV DL, BYTE PTR VDX+1
            JMP READ_DEST_OPTION
            
            
            INVALID_SRC_REG_NUMBER:
            ;   READ SRC REG NUMBER AGAIN
            JMP READ_SRC_REG_NUMBER
            
            
            COMMAND_ONE_SRC_OPTION_NOT_ONE:
            CMP AL, 32H       ;   CHECK IF 2 PRESSED (MEMORY)
            JNE COMMAND_ONE_SRC_OPTION_NOT_TWO
            ;   READING SRC MEMORY LOCATION

            MOV AH, 0AH
            MOV DX, OFFSET SRC_MEMORY_ADDRESS
            INT 21h
            
            PUSHA
            MOV SRC_MEMORY_ADDRESS_NUMBER, 0
            LEA SI, SRC_MEMORY_ADDRESS+2
            LEA DI, SRC_MEMORY_ADDRESS_NUMBER
            CONVERT_ASCII_TO_NUMBER SI, DI
            POPA
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    SHIFTING VIRTUAL DS
            
            JMP READ_DEST_OPTION
            
            COMMAND_ONE_SRC_OPTION_NOT_TWO:
            CMP AL, 33H       ;   CHECK IF 3 PRESSED (IMMEDIATE)
            JNE INVALID_SRC_OPTION
            ;   READING SRC MEMORY LOCATION

            MOV AH, 0AH
            MOV DX, OFFSET SRC_IMMEDIATE_VALUE
            INT 21h
            
            PUSHA
            MOV SRC_IMMEDIATE_VALUE_NUMBER, 0
            LEA SI, SRC_IMMEDIATE_VALUE+2
            LEA DI, SRC_IMMEDIATE_VALUE_NUMBER
            CONVERT_ASCII_TO_NUMBER SI, DI
            ;MOV DX, SRC_IMMEDIATE_VALUE_NUMBER
            ;MOV AH, 0
            ;INT 16H
            POPA
            
            JMP READ_DEST_OPTION
            
            INVALID_SRC_OPTION:
            ;   READ SRC OPTION AGAIN
            JMP READ_SRC_OPTION
            
            
            
            
            
            
            
            
            
            
            
            
            
            READ_DEST_OPTION:
            ;   READING DEST OPTION
            MOV AH, 0
            INT 16h
            
            CMP AL, 31H       ;   CHECK IF 1 PRESSED (REG)
            JNE COMMAND_ONE_DEST_OPTION_NOT_ONE
            ;   READING REGISTER NUMBER
            MOV DEST_OPTION, 1          ;   DESTINATION IS A REG
            
            ;   READING REG NUMBER
            READ_DEST_REG_NUMBER:
            MOV AH, 0
            INT 16h
            
            
            
            CMP AL, 30H       ;   AX
            JNE COMMAND_ONE_DEST_REG_NOT_AX
            ;   REG AX IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 0                 ;   DESTINATION REG  IS AX
            LEA AX, VAX
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX
            
            
            COMMAND_ONE_DEST_REG_NOT_AX:
            CMP AL, 31H       ;   BX
            JNE COMMAND_ONE_DEST_REG_NOT_BX
            ;   REG BX IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 1                 ;   DESTINATION REG  IS BX
            LEA AX, VBX
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_BX:
            CMP AL, 32H       ;   CX
            JNE COMMAND_ONE_DEST_REG_NOT_CX
            ;   REG CX IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 2                 ;   DESTINATION REG  IS CX
            LEA AX, VCX
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_CX:
            CMP AL, 33H       ;   DX
            JNE COMMAND_ONE_DEST_REG_NOT_DX
            ;   REG DX IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 3                 ;   DESTINATION REG  IS DX
            LEA AX, VDX
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_DX:
            CMP AL, 34H       ;   SI
            JNE COMMAND_ONE_DEST_REG_NOT_SI
            ;   REG SI IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 4                 ;   DESTINATION REG  IS SI
            LEA AX, VSI
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_SI:
            CMP AL, 35H       ;   DI
            JNE COMMAND_ONE_DEST_REG_NOT_DI
            ;   REG DI IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 5                 ;   DESTINATION REG  IS DI
            LEA AX, VDI
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX                                          
            
            
            COMMAND_ONE_DEST_REG_NOT_DI:
            CMP AL, 36H       ;   SP
            JNE COMMAND_ONE_DEST_REG_NOT_SP
            ;   REG SP IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 6                 ;   DESTINATION REG  IS SP
            LEA AX, VSP
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_SP:
            CMP AL, 37H       ;   BP
            JNE COMMAND_ONE_DEST_REG_NOT_BP
            ;   REG BP IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 7                 ;   DESTINATION REG  IS BP
            LEA AX, VBP
            EXE_MOV_COMMAND_WITH_DEST_16_BIT_REG AX
                        
                        
                        
            COMMAND_ONE_DEST_REG_NOT_BP:
            CMP AL, 38H       ;   AL
            JNE COMMAND_ONE_DEST_REG_NOT_AL
            ;   REG AL IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 8                 ;   DESTINATION REG  IS AL
            LEA AX, VAX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_AL:
            CMP AL, 39H       ;   AH
            JNE COMMAND_ONE_DEST_REG_NOT_AH
            ;   REG AH IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 9                 ;   DESTINATION REG  IS AH
            LEA AX, VAX
            INC AX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_AH:
            CMP AL, 61H       ;   BL
            JNE COMMAND_ONE_DEST_REG_NOT_BL
            ;   REG BL IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 10                 ;   DESTINATION REG  IS BL
            LEA AX, VBX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX 
            
            COMMAND_ONE_DEST_REG_NOT_BL:
            CMP AL, 62H       ;   BH
            JNE COMMAND_ONE_DEST_REG_NOT_BH
            ;   REG BH IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 11                 ;   DESTINATION REG  IS BH
            LEA AX, VBX
            INC AX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_BH:
            CMP AL, 63H       ;   CL
            JNE COMMAND_ONE_DEST_REG_NOT_CL
            ;   REG CL IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 12                 ;   DESTINATION REG  IS CL
            LEA AX, VCX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_CL:
            CMP AL, 64H       ;   CH
            JNE COMMAND_ONE_DEST_REG_NOT_CH
            ;   REG CH IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 13                 ;   DESTINATION REG  IS CH
            LEA AX, VCX
            INC AX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_CH:
            CMP AL, 65H       ;   DL
            JNE COMMAND_ONE_DEST_REG_NOT_DL
            ;   REG DL IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 14                 ;   DESTINATION REG  IS DL
            LEA AX, VDX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX
            
            COMMAND_ONE_DEST_REG_NOT_DL:
            CMP AL, 66H       ;   DH
            JNE INVALID_DEST_REG_NUMBER
            ;   REG DH IS CHOSEN AS DEST
            MOV DEST_REG_NUM, 15                 ;   DESTINATION REG  IS DH
            LEA AX, VDX
            INC AX
            EXE_MOV_COMMAND_WITH_DEST_8_BIT_REG AX
            
            
            INVALID_DEST_REG_NUMBER:
            ;   READ REG NUMBER AGAIN
            JMP READ_DEST_REG_NUMBER
            
            
            COMMAND_ONE_DEST_OPTION_NOT_ONE:
            CMP AL, 32H       ;   CHECK IF 2 PRESSED (MEMORY)
            JNE INVALID_DEST_OPTION
            ;   READING DEST MEMORY LOCATION

            MOV AH, 0AH
            MOV DX, OFFSET DEST_MEMORY_ADDRESS
            INT 21h
            
            PUSHA
            MOV DEST_MEMORY_ADDRESS_NUMBER, 0
            LEA SI, DEST_MEMORY_ADDRESS+2
            LEA DI, DEST_MEMORY_ADDRESS_NUMBER
            CONVERT_ASCII_TO_NUMBER SI, DI
            POPA
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    SHIFTING VIRTUAL DS
            
            ;   CHECKING IF SOURCE IS REGISTER
            CMP SRC_OPTION, 1
            JNE COMMAND_ONE_SOURCE_NOT_REGISTER_WITH_MEMORY_DEST
            ;   SOURCE IS REGISTER
            ;   CHECKING THE SIZE OF THE REGISTER
            CMP SRC_REG_NUM, 7
            JG  COMMAND_ONE_SRC_REG_8_BIT_WITH_MEMORY_DEST
            ;   SOURCE REGISTER IS 16 BIT
            MOV BX, DEST_MEMORY_ADDRESS_NUMBER
            MOV [BX], SI
            JMP COMMAND_EXECUTED
            
            COMMAND_ONE_SRC_REG_8_BIT_WITH_MEMORY_DEST:
            ;   SOURCE REGISTER IS 8 BIT
            MOV BX, DEST_MEMORY_ADDRESS_NUMBER
            MOV [BX], DL
            JMP COMMAND_EXECUTED
            
            COMMAND_ONE_SOURCE_NOT_REGISTER_WITH_MEMORY_DEST:
            CMP SRC_OPTION, 2
            JNE COMMAND_ONE_SOURCE_NOT_MEMORY_WITH_MEMORY_DEST
            ;   SOURCE IS MEMORY
            JMP MEMORY_TO_MEMORY_OPERATION_ERROR
            
            COMMAND_ONE_SOURCE_NOT_MEMORY_WITH_MEMORY_DEST:
            ;   SOURCE IS IMMEDIATE VALUE
            MOV BX, DEST_MEMORY_ADDRESS_NUMBER
            MOV DX, SRC_IMMEDIATE_VALUE_NUMBER
            MOV [BX], DX
            JMP COMMAND_EXECUTED
            
            
            INVALID_DEST_OPTION:
            ;   READ DEST OPTION AGAIN
            JMP READ_DEST_OPTION
            
            
            
            NOT_COMMAND_ONE:
            CMP AL, 31H       ;   1 KEY PRESSED
            ;JNE COMMAND_THREE
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
            
        JMP MAIN_LOOP   

hlt
MAIN    ENDP
;-------------------------------------------------

    END MAIN        ; End of the program  
		