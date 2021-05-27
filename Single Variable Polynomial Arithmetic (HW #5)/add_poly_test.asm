.data
p_pair: .word 5 2
p_terms: .word 7 1 3 2 1 1 0 -1
q_pair: .word -5 2
q_terms: .word 1 2 0 -1
p: .word 0
q: .word 0
r: .word 0
N: .word 0

.text:
main:
    la $a0, p
    la $a1, p_pair
    jal init_polynomial

    la $a0, p
    la $a1, p_terms
    lw $a2, N
    jal add_N_terms_to_polynomial

    la $a0, q
    la $a1, q_pair
    jal init_polynomial

    la $a0, q
    la $a1, q_terms
    li $a2, 0
    jal add_N_terms_to_polynomial

    la $a0, p
    la $a1, q
    la $a2, r
    jal add_poly
   move $a0, $v0
   li $v0, 1
   syscall
    la $t0, r
    lw $s0, 0($t0)
    mainLoop:
    	lw $t1, 0($s0)
    	lw $t2, 4($s0)
    	move $a0, $t1
    	li $v0, 1
    	syscall
    	move $a0, $t2
    	li $v0, 1
    	syscall
    	lw $s0, 8($s0)
    	beqz $s0, exit
    	j mainLoop
    #write test code
  exit:
    li $v0, 10
    syscall
    li $v0, 10
    syscall
    #write test code

    li $v0, 10
    syscall

.include "hw5.asm"
