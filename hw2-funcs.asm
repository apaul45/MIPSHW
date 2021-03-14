############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval:
  li $a0, 'x'
  lw $s0, 0($a0)
  jal is_digit
  li $a0, '+'
  lw $s0, 0($a0)
  jal valid_ops
  li $a0, '+'
  lw $s0, 0($a0)
  jal op_precedence
  jr $ra #NOTE: When jumping between multiple functions, MUST SAVE $ra as per REGISTER CONVENTIONS!
  li $a0, '-'
  li $a1, '+'
  li $a2, '*'
  lw $s0, 0($a0)
  lw $s2, 0($a1)
  lw $s3, 0($a2)
is_digit: #is_digit checks whether the given char is of a valid value--which is that of a integer digit between 0 and 9 inclusive.
 #Can check using the ascii values of 0 and 9-- if the inputted char falls below ascii value of 0 (48) or above 9 (57) then return 0. If
 # char is valid, then return 1
  li $t0, '0'
  blt $s0, $t0, zeroPrint
  li $t0, '9'
  bgt $s0, $t0, zeroPrint
  j onePrint
  jr $ra #For jr, only need to follow conventions for it WHEN CALLING ANOTHER FUNCTION (AKA THE JAL INSTRUCTION)
zeroPrint:
  li $v0, 1
  addi $a0, 0, $0
  addi $s1, $0, $a0 #Store the 0 in s1 to be used in part 3 for op_precedence-- can overwrite as needed but HAVE TO FOLLOW CONVENTIONS!
  syscall 
  jr $ra #Return to main (aka eval)
stack_push:
  jr $ra

stack_peek:
  jr $ra

stack_pop:
  jr $ra

is_stack_empty:
  jr $ra

valid_ops: #valid_ops is very similar to is_digit but checks for operator chars, which again uses ascii values
  li $t0, '+'
  beq $a0, $t0, onePrint
  li $t0, '-'
  beq $a0, $t0, onePrint
  li $t0, '*'
  beq $a0, $t0, onePrint
  li $t0, '/'
  beq $a0, $t0, onePrint
  j zeroPrint
  jr $ra
onePrint: 
  li $v0, 1
  addi $a0, $0, 1
  addi $s1, $0, $a0 #Store the 1 in s1 to be used in part 3 for op_precedence
  syscall 
  jr $ra #Return to main (aka eval)
op_precedence: #First checks if the inputted operator is valid using valid_ops (MEANING RA MUST BE SAVED BEFORE JAL IS CALLED,
#and then returns the proper integer value such that * and / have a higher (but equal to eachother) int value than + and - (but = to eachother)
  addi $sp, $sp, -4 #Make space for ra on the stack
  sw $ra, 0($sp) #Store $ra--offset of 0 since stack pointer is now -4 the base address from addi
  jal valid_ops #Call the valid-ops function after preserving the $ra register
  li $t0, 0 
  beq $s1, $t0, printErrMsg #Check if the valid_ops function returned a 1 or 0 in $s0-- an error should be printed if 0
  lw $ra, 0($sp) #Restore the value of $ra before using branch statements to print out the appropriate precedences
  li $t0, '+' #Lower limit in terms of ascii
  li $t1, '-' #Higher limit in terms of ascii-- if value in s0 is either less than + or greater than - , then it is either * or -
  blt $s0, $t0, multDivPrecedence
  bgt $s0, $t1, multDivPrecedence
  li $v0, 1
  addi	$a0, $0, 0	#Precedence of a + or - operator
  syscall
  jr $ra
multDivPrecedence: #Returns a precedence of two for a * or - operator, which is higher than that of + or -
  li $v0, 1
  addi $a0, $0, 1
  syscall
  jr $ra
printErrMsg:
  la $a0, ApplyOpError
  li $v0, 4
  syscall
  jr $ra
apply_bop:
  jr $ra
