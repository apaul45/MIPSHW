.data
filename: .asciiz"/Users/apaul23/MIPSHW/moves01.txt"
.align 0
moves: .byte 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.text
.globl main
main:
la $a0, moves
la $a1, filename
jal load_moves

# You must write your own code here to check the correctness of the function implementation.
move $a0, $v0
li $v0, 1
syscall
li $t0, 22
li $t1, 0
la $a0, moves
mainLoop:
	beq $t1, $t0, mainExit
	lb $t3, 0($a0)
	addi $a0, $a0, 1
	move $t9, $a0
	move $a0, $t3
	li $v0, 1
	syscall
	addi $t1, $t1, 2
	move $a0, $t9
	j mainLoop
mainExit:
	li $v0, 10
	syscall

.include "hw3.asm"
