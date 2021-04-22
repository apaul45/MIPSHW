# add test cases to data section
.data
str1: .asciiz "Jane Doe\0"
str2: .asciiz "Jane Doe\0"

str3: .asciiz "Jane Does\0"
.text:
main:
	la $a0, str1
	la $a1, str2
	jal str_equals
	#write test code
	move $a0, $v0
	li $v0, 1
	syscall
	la $a0, str1
	la $a1, str3
	jal str_equals
	#write test code
	move $a0, $v0
	li $v0, 1
	syscall
	li $v0, 10
	syscall
	
.include "hw4.asm"
