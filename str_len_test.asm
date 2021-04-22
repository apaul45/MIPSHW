# add test cases to data section
.data
str1: .asciiz "Ali Tourre"

.text:
main:
	la $a0, str1
	jal str_len
	#write test code
	move $a0, $v0
	li $v0, 1
	syscall
	li $v0, 10
	syscall
	
.include "hw4.asm"
