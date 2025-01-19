.data
.p2align 4
min_cd:
    .int 0
range:
    .int 0

.text
.globl _inverse
.globl _calc_hist
.globl _calc_cdf
.globl _normalize_cdf
.globl _apply_hist


_inverse:
    movl %edx, %r10d
    xor %rdx, %rdx
inversion_loop:
    movb (%rdi, %rdx), %r11b
    subb $255, %r11b
    neg %r11b
    movb %r11b, (%rsi, %rdx)
    inc %edx
    cmpl %edx, %r10d
    jnz inversion_loop
    ret


_calc_hist:
    movl %edx, %r10d
    xor %rdx, %rdx
    xor %r11, %r11
hist_loop:
    movb (%rdi, %rdx), %r11b # element in r11b
    incl (%rsi, %r11, 4)
    inc %edx
    cmpl %edx, %r10d
    jnz hist_loop
    ret


_calc_cdf:
    xor %r10, %r10
    movl %edx, %r10d
    movq $1, %rdx
    # cdf[0] = hist[0]
    movl (%rdi), %ecx
    movl %ecx, (%rsi)
cdf_loop:
    movl (%rdi, %rdx, 4), %r11d # hist[i] in r11d
    addl %r11d, %ecx # cdf[i] = cdf[i-1] + hist[i]
    movl %ecx, (%rsi, %rdx, 4)
    inc %edx
    cmpl %edx, %r10d
    jnz cdf_loop
    ret


_normalize_cdf:
    xor %r10, %r10
    xor %r11, %r11
    # min_cd
min_cd_loop:
    cmpl (%rdi, %r10, 4), %r11d
    inc %r10
    je min_cd_loop
    dec %r10
    movl (%rdi, %r10, 4), %r10d
    movl %r10d, min_cd(%rip)
    # range
    movl %edx, %r10d
    subl min_cd(%rip), %r10d
    movl %r10d, range(%rip)
    xor %r10, %r10 # loop var
normalization_loop:
    movl min_cd(%rip), %r11d
    subl %r11d, (%rdi, %r10, 4) # (cdf[i] - min_cd)
    movl (%rdi, %r10, 4), %eax
    movl $255, %r11d
    mull %r11d # eax = (cdf[i] - min_cd) * 255
    movl range(%rip), %r11d
    divl %r11d # eax = (cdf[i] - min_cd) * 255 / range
    movl %eax, (%rdi, %r10, 4)
    inc %r10d
    cmpl %r10d, %esi
    jnz normalization_loop
    movl min_cd(%rip), %eax
    ret


_apply_hist:
    xor %r11, %r11
    xor %r10, %r10
apply_loop:
    movb (%rdi, %r10), %r11b # get pixel
    movl (%rsi, %r11, 4), %r11d # get val cdf
    movb %r11b, (%rcx, %r10)
    inc %r10d
    cmpl %edx, %r10d
    jnz apply_loop
    ret