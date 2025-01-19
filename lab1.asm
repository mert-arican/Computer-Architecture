stack_segment SEGMENT PARA STACK 'stack'
    DW 20 DUP(?)
stack_segment ENDS

data_segment SEGMENT PARA 'data'
    midterms DW 77, 85, 64, 96
    finals DW 56, 63, 86, 74
    average_grades DW 4 DUP(?)
    number_of_students DW 4
data_segment ENDS

code_segment SEGMENT PARA 'code'
                ASSUME DS: data_segment, CS: code_segment, SS: stack_segment
MAIN_TASK       PROC FAR
                PUSH DS
                XOR AX, AX
                PUSH AX
                MOV AX, data_segment
                MOV DS, AX

                MOV CX, number_of_students
                LEA SI, midterms
                LEA DI, finals
                LEA BX, average_grades
CALC_AVG_LOOP:      
                MOV AX, [SI] ; Get corresponding midterm
                PUSH CX ; Save CX value needed for the loop
                MOV CX, 4
                MUL CX
                PUSH AX ; Push AX to stack
                MOV AX, [DI] ; Get corresponding final
                MOV CX, 6
                MUL CX
                POP DX ; Fetch AX value to DX
                ADD AX, DX
                MOV DX, 0 ; Prep for division
                MOV CX, 10 ; Prep for division
                DIV CX ; Remainder in DX
                CMP DX, 4 ; Compare DX with 4
                JNA DONT_INCREMENT ; If last digit is not greater than 4 don't round up to the ceiling value
                INC AX
DONT_INCREMENT: 
                MOV [BX], AX ; Add average grade to 'average_grades'
                ADD SI, 2
                ADD DI, 2
                ADD BX, 2
                POP CX ; Fetch index from stack into CX
                LOOP CALC_AVG_LOOP

INSERTION_SORT:
                MOV CX, number_of_students
                MOV DI, 1 ; DI = i throughout the sort
                LEA SI, average_grades
OUTER_LOOP:
                CMP DI, CX
                JGE END_OUTER_LOOP

                ; elem = arr[i]
                MOV BX, SI
                MOV AX, DI
                SHL AX, 1
                ADD BX, AX
                MOV DX, [BX] ; arr[i] = DX = elem
                
                ; BX = j = i - 1
                MOV BX, DI
                DEC BX
INNER_WHILE:
                CMP BX, 0
                JL INSERT_ELEM ; If j < 0, then jump out of the while loop

                ; calculate arr[j]
                PUSH BX
                SHL BX, 1
                ADD BX, SI
                MOV AX, [BX] ; AX = arr[j]
                POP BX
                CMP AX, DX ; compare arr[j] with elem
                JGE INSERT_ELEM

                ; arr[j+1] = arr[j]
                PUSH BX
                INC BX
                SHL BX, 1
                ADD BX, SI
                MOV [BX], AX ; arr[j+1] = arr[j]
                POP BX
                DEC BX ; j--
                JMP INNER_WHILE
INSERT_ELEM:
                ; arr[j+1] = arr[i] = elem
                PUSH BX
                INC BX
                SHL BX, 1
                ADD BX, SI
                MOV [BX], DX ; arr[j+1] = arr[i]
                POP BX
                INC DI
                JMP OUTER_LOOP
END_OUTER_LOOP:
                RETF
MAIN_TASK       ENDP
code_segment ENDS
                END MAIN_TASK