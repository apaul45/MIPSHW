.data
coeff: .word 2
exp: .word -3

.text:
main:
    lw $a0, coeff
    lw $a1, exp
    jal create_term
    move $a0, $v0
    li $v0, 1
    syscall
    #write test code

    li $v0, 10
    syscall

.include "hw5.asm"
