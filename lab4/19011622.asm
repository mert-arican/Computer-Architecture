.data
# Get MSVC comfort back
output_rows:
    .int 0
output_cols:
    .int 0
k_rows:
    .int 0
k_cols:
    .int 0
m_cols:
    .int 0
kernel:
    .quad 0
matrix:
    .quad 0
output:
    .quad 0

# Variables to use inside this function
sum:
    .int 0

.text
.globl _convolve               # Make the function globally visible
_convolve:
    movl %edi, output_rows(%rip)
    movl %esi, output_cols(%rip)
    movl %edx, k_rows(%rip)
    movl %ecx, k_cols(%rip)
    movl %r8d, m_cols(%rip)
    movq %r9, kernel(%rip)
    movq 8(%rsp), %r10 # r10 holds RSP + 8
    movq %r10, matrix(%rip)
    movq 16(%rsp), %r10 # r10 holds RSP + 16
    movq %r10, output(%rip)
    
    xorq %rcx, %rcx
    movl output_rows(%rip), %ecx
output_row_loop:
    PUSH %rcx # output_row - i
    movl output_cols(%rip), %ecx
output_col_loop:
    PUSH %rcx # output_col - j
    movl $0, sum(%rip) # sum = 0
    movl k_rows(%rip), %ecx
k_row_loop:
    PUSH %rcx # k_row - ki
    movl k_cols(%rip), %ecx # k_col - kj
k_col_loop:
    # matrix_idx
    xorq %r10, %r10
    movq 16(%rsp), %r10 # i
    addq (%rsp), %r10 # i + ki
    subq $2, %r10

    xorq %rax, %rax
    movl m_cols(%rip), %eax
    mulq %r10

    addq %rcx, %rax
    addq 8(%rsp), %rax
    subq $2, %rax
    movq %rax, %r10 # r10 = matrix_idx

    ### kernel_idx
    xorq %r11, %r11
    movq (%rsp), %r11 # ki
    decq %r11

    xorq %rax, %rax
    movl k_cols(%rip), %eax
    mulq %r11

    addq %rcx, %rax
    decq %rax
    movq %rax, %r11 # r11 = kernel_idx

    movq matrix(%rip), %rax
    movq kernel(%rip), %rdx

    movq (%rax, %r10, 4), %rax
    movq (%rdx, %r11, 4), %rdx
    mulq %rdx

    addl %eax, sum(%rip)
    LOOP k_col_loop
    
    POP %rcx
    LOOP k_row_loop

    xorq %r10, %r10

    movq 8(%rsp), %rax
    decq %rax
    movl output_cols(%rip), %r10d
    mulq %r10
    addq (%rsp), %rax
    decq %rax
    
    movq %rax, %r11
    movq output(%rip), %rax
    xorq %r10, %r10
    movl sum(%rip), %r10d
    movl %r10d, (%rax, %r11, 4)

    POP %rcx
    dec %ecx
    jnz output_col_loop

    POP %rcx
    dec %ecx
    jnz output_row_loop    
    ret # Return to caller
