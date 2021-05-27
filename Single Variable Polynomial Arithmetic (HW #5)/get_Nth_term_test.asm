.data
pair: .word 4 3 
terms: .word 2 2 5 0 0 -1
p: .word 0
N: .word 3
N1: .word 1

.text:
main:
    la $a0, p
    la $a1, pair
    jal init_polynomial
    
    la $a0, p
    la $a1, terms
    lw $a2, N
    jal add_N_terms_to_polynomial
    la $t0, N
    addi $t1, $0, 667
    sw $t1, 0($t0)
    la $a0, p
    lw $a1, N
    jal get_Nth_term
   move $a0, $v0
   li $v0, 1
   syscall
   move $a0, $v1
   li $v0, 1
   syscall
    #write test code

    li $v0, 10
    syscall

.include "hw5.asm"
