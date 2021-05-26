.data
pair: .word 12 8
terms: .word  2 3 4 3 5 0 0 -1
p: .word 0
N: .word 3

.text:
main:
    la $a0, p
    la $a1, pair
    jal init_polynomial
    la $a0, p
    la $a1, terms
    lw $a2, N
    jal add_N_terms_to_polynomial
   move $a0, $v0
   li $v0, 1
   syscall
    #write test code
    la $t0, p
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
    exit:
   	 li $v0, 10
    	syscall

.include "hw5.asm"
