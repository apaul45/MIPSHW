# add test cases to data section
# Test your code with different Network layouts
# Don't assume that we will use the same layout in all our tests
.data
Name1: .asciiz "Jane Doe\0"
Name2: .asciiz "Getafix"
Name_prop: .asciiz "NAME"

Network:
  .word 5   #total_nodes (bytes 0 - 3)
  .word 10  #total_edges (bytes 4- 7)
  .word 12  #size_of_node (bytes 8 - 11)
  .word 12  #size_of_edge (bytes 12 - 15)
  .word 3   #curr_num_of_nodes (bytes 16 - 19)
  .word 0   #curr_num_of_edges (bytes 20 - 23)
  .asciiz "NAME" # Name property (bytes 24 - 28)
  .asciiz "FRIEND" # FRIEND property (bytes 29 - 35)
   # nodes (bytes 36 - 95)	
  .byte 'J' 'a' 'n' 'e' ' ' 'D' 'o' 'e' 0 0 0 0 74 111 104 110 ' ' 68 111 101 0 0 0 0 65 'l' 'i' ' ' 'T' 'o' 'u' 'r' 'r' 'e' 0 0 0 0 0 0 0 0 0 0 0 
   # set of edges (bytes 96 - 215)
  .word 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

.text:
main:
	la $a0, Network
	la $a1, Name1
	jal get_person
	la $a0, Network
	addi $a0, $a0, 36
	beq $a0, $v0, returnmain
	li $a0, 0 
	li $v0, 1
	syscall
	#write test code
	li $v0, 10
	syscall
returnmain:
	li $a0, 1
	li $v0, 1
	syscall
	li $v0, 10
	syscall
.include "hw4.asm"
