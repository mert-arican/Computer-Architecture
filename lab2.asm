the_segment SEGMENT PARA 'common'
                ORG 100h
                ASSUME DS: the_segment, CS: the_segment, SS: the_segment
Start:          JMP MAIN_TASK
N                       DB 50
LIMIT                   DW 2500
primeIndex              DB 0
nonPrimeIndex           DB 0
primeOddSum             DB 15 DUP(0)
nonPrimeOrEvenSum       DB 15 DUP(0)

; element -> 1/0
IS_PRIME        PROC NEAR
                PUSH BP
                MOV BP, SP
                MOV CL, 2
prime_loop:     
                XOR AX, AX
                MOV AL, [BP + 4] ; first argument of function, x
                DIV CL
                INC CL
                TEST AH, AH ; x is not prime
                JZ is_not_prime
                MOV AL, [BP + 4]
                CMP AL, CL
                JZ _is_prime
                JMP prime_loop
is_not_prime:
                MOV AL, 0
                JMP is_prime_exit
_is_prime:
                MOV AL, 1
is_prime_exit:
                POP BP
                RET
IS_PRIME        ENDP

; address, element, count -> 1/0
UNIQUELY_APPEND PROC NEAR
                PUSH BP
                MOV BP, SP
                MOV SI, 0 ; SI = index
                XOR CX,CX
                XOR AX, AX
                MOV CL, [BP+8] ; CX = element count of array 
                MOV AL, [BP+6] ; AX = element
                MOV BX, [BP+4] ; BX = base address of array
append_loop:
                CMP SI, CX
                JB continue_loop ; if index < count of array

                ; Add element to array, then exit
                MOV DI, BX
                ADD DI, SI
                MOV [DI], AL
                MOV AL, 1
                JMP append_exit
continue_loop:
                MOV DI, BX
                ADD DI, SI
                CMP AL, [DI] ; compare element with array[index]
                JZ dont_append ; if array contains element, then exit
                INC SI
                JMP append_loop
dont_append:
                MOV AL, 0
append_exit:
                POP BP
                RET
UNIQUELY_APPEND ENDP

; a, b, hypotenuse
ADD_HYPOTENUSE PROC NEAR
                PUSH BP
                MOV BP, SP
                XOR AH, AH
                MOV AL, [BP+8] ; Third arg is hypotenuse
                PUSH AX
                CALL IS_PRIME ; AL set to 1 if hypotenuse is prime, else 0
                ADD SP, 2
                TEST AL, AL
                JZ addToNonPrimeOrEvenSum; If x is not prime
                MOV AL, [BP+4]
                MOV AH, [BP+6]
                ADD AL, AH ; AL = a + b
                XOR AH, AH ; AX = AL
                MOV BL, 2
                DIV BL ; Remainder in AH
                TEST AH, AH ; if remainder is zero
                JNZ addToPrimeOddSum
addToNonPrimeOrEvenSum:
                XOR AX, AX
                MOV AL, nonPrimeIndex
                ;MOV SI, AX
                PUSH AX ; add the length of array
                MOV AL, [BP+8]
                PUSH AX ; push the element to be appended
                LEA AX, nonPrimeOrEvenSum
                PUSH AX ; push address of array
                CALL UNIQUELY_APPEND ; AL = 1 if element appended, else 0
                ADD SP, 6
                TEST AL, AL
                JZ check_exit ; if not added exit func
added1:
                MOV AL, nonPrimeIndex
                INC AL
                MOV [nonPrimeIndex], AL
                JMP check_exit
addToPrimeOddSum:
                XOR AX, AX
                MOV AL, primeIndex
                MOV SI, AX
                PUSH SI ; add the length of array
                MOV AL, [BP+8]
                PUSH AX ; push the element to be appended
                LEA AX, primeOddSum
                PUSH AX ; push address of array
                CALL UNIQUELY_APPEND ; AL = 1 if element appended, else 0
                ADD SP, 6
                TEST AL, AL
                JZ check_exit ; if not added exit func
added2:
                MOV AL, primeIndex
                INC AL
                MOV [primeIndex], AL
check_exit:
                POP BP
                RET
ADD_HYPOTENUSE ENDP

MAIN_TASK       PROC NEAR
                ; for a in 1...50
                ; for b in a...50
                MOV CL, 1 ; a = 1
outer_loop:
                MOV CH, CL ; b = a
inner_loop:
                MOV AL, CL
                XOR AH, AH
                MUL AL
                MOV BX, AX ; BX = a^2
                MOV AL, CH
                XOR AH, AH
                MUL AL ; AX = b^2
                ADD BX, AX ; BX = a^2 + b^2
                CMP BX, LIMIT ; if a^2 + b^2 > 2500, i.e. c > 50
                JA outer_loop_exit ; go to next one
                MOV DL, 1 ; DL = c
hypo_nominee_loop:
                MOV AL, DL
                XOR AH, AH
                MUL AL ; AX = c^2
                CMP AX, BX
                JZ hypo_found ; AX == BX then integer hypotenuse found
                JA inner_loop_exit ; if c^2 > BX then continue next triangle
                INC DL
                CMP DL, N
                JNA hypo_nominee_loop
                JMP inner_loop_exit
hypo_found:
                ; DL = c = hypotenuse
                XOR DH, DH
                PUSH DX

                ; CL = a
                MOV AL, CL
                XOR AH, AH
                PUSH AX

                ; CH = b
                MOV AL, CH
                XOR AH, AH
                PUSH AX

                ; Fix CX and DL registers
                ; Because they store a, b and c
                CALL ADD_HYPOTENUSE
                POP AX ; contains CH
                POP CX ; contains CL
                MOV CH, AL ; Fix CH
                POP DX ; contains DL
                JMP inner_loop_exit
inner_loop_exit:
                INC CH
                CMP CH, N
                JNA inner_loop
outer_loop_exit:
                INC CL
                CMP CL, N
                JNA outer_loop
main_exit:
                RET
MAIN_TASK       ENDP
the_segment     ENDS
                END Start