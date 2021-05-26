.data
pair: .word 1 8
p: .word 0

.text:
main:
    la $a0, p
    la $a1, pair
    jal init_polynomial

    #write test code
    move $a0, $v0
    li $v0, 1
    syscall
    la $a0, p
    lw $a0, 0($a0)
    lw $a0, 0($a0)
    li $v0, 1
    syscall
    la $a0, p
    lw $a0, 0($a0)
    lw $a0, 4($a0)
    li $v0, 1 
    syscall
    li $v0, 10
    syscall

.include "hw5.asm"
