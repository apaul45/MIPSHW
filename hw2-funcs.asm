############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval:
is_digit: #is_digit checks whether the given char is of a valid value--which is that of a integer digit between 0 and 9 inclusive.
 #Can check using the ascii values of 0 and 9-- if the inputted char falls below ascii value of 0 (48) or above 9 (57) then return 0. If
 # char is valid, then return 1
  addi $sp, $sp, -8 #Open two spots on stack
  sw $ra, 0($sp) #Save ra before jumping to helper function
  sw $sp, 4($sp)
  move $s0, $a0 #Move the argument into s0
  jal numberVerify #numberVerify will return either a 1 or a 0 in v0, which will indicate whether it is a digit or not
  beqz $v0, printErrMsg
  lw $ra, 0($sp)
  lw $s0, 4($sp)
  addi $sp, $sp, 8
  jr $ra #For jr, only need to follow conventions for it WHEN CALLING ANOTHER FUNCTION (AKA THE JAL INSTRUCTION)
zeroPrint:
  li $v0, 1
  addi $a0, 0, $0
  syscall 
  lw $ra, 0($sp) #Restore ra of is_digit
  addi $sp, $sp, 4 #Close off stack
  jr $ra
stack_push: #Push takes in 3 arguments: in order to generalize, need to do this with the help of a helper function
  #stack_push will call a helper that takes the arguments in t registers, and then stores the word at the new address. 
  addi $sp, $sp, -4 #Make space to store the ra of stack_push, before jumping to helper function
  sw $ra, 0($sp)
  beqz $a1, printandTerminate #If the tp is negative, then the program should print error: min of tp in push is 0
  li $t0, 2004 #Since the index to store a0 is passed in a1, the max it can be is 2000 which is the limit of the stack
  bge $a1, $t0, printandTerminate #If the tp is greater than or equal to 2004, the program should print error: tp can only be 2000 at most 
  li $t0, 4
  div $a1, $t0
  mfhi $t3 #Remainder of a1/t0
  bgt $t3, $0, printErrMsg #If the tp isn't a multiple of 4 (ie, tp mod 4 >0), then print error: since each element is separated by 4 bytes, the tp must be mult of 4
  jal pushHelper #jal with all the values still in a registers. pushHelper returns the new tp in v0
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra
pushHelper: #pushHelper should store the new element at the address base+tp, then add 4 to tp and return that value (the index right above the new top)
  add $t1, $a2, $a1 #Get to address to store new element at
  sw $a0, 0($t1) #Store the new element of the stack into specified address
  addi $v0, $a1, 4 #Get new top
  jr $ra
stack_peek: #Peek returns whatever is at the (valid) stack pointer
  blt $a0, $0, printandTerminate #If given pointer is less than 0, terminate and print error: Stack pointer always STARTS (push) and STOPS (pop) at 0
  add $t6, $a2, $a1 #Get to address of the pointer
  lw $v0, 0($t6) #Load the element at the pointer address
  jr $ra
stack_pop: #Pop takes in 2 arguments: the index representing the address above top, and the base address.
  beqz $a0, printandTerminate #If tp=0, then print any error and terminate: no element can exist at tp-4
  addi $v0, $a0, -4 #Get to the index representing stack.top
  addi $t6, $a1, $v0 #Get to the address of top
  lw $v1, 0($t6) #Put the value at t6 into v1 to be returned to caller
  jr $ra #When this goes back to caller, v0 will contain tp-4 (which is the new index above the new top), and v1 will contain the value that was there.
is_stack_empty: #Returns a 0 or 1 depending on the value of the pointer a0
  addi $sp, $sp, -4
  sw $ra, 0($sp)
  blt $a0, $0, peekZero #If given pointer is less than 0, put 0 in v0: Stack pointer always STARTS (push) and STOPS (pop) at 0
  peekZero:
    li $v0, 0
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
  j peekOne
  peekOne:
    li $v0, 1
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
valid_ops: #valid_ops is very similar to is_digit but checks for operator chars, which again uses ascii values
  addi $sp, $sp, -8 #Make two spaces on the stack
  sw $ra, 0($sp) #Save ra before jumping to helper function
  sw $sp, 4($sp) #Save s0 before loading the argument into it
  move $s0, $a0 #Save the argument in s0 as a backup
  jal operatorVerify #operatorVerify will return a 1 or 0 in v0, which caller of valid_ops can then use to verify accordingly
  beqz $v0, printErrMsg
  lw $ra, 0($sp)
  lw $s0, 4($sp)
  addi $sp, $sp, 8
  jr $ra #For jr, only need to follow conventions for it WHEN CALLING ANOTHER FUNCTION (AKA THE JAL INSTRUCTION)
operatorVerify: #Meant to be used for all applicable parts rather than only the early parts, does the same thing as numberVerify but for ops
  addi $sp, $sp, -8 #Open 2 spot on the stack for the s register containing s0 and the ra of operatorVerify
  sw $s0, 4($sp)
  sw $ra, 8($sp)
  lbu $t0, 0($s0)
  li $t1, '*'
  li $t2, '/'
  li $t3, '-'
  li $t5, '+'
  beq $t0, $t1, onePlace
  beq $t0, $t2, onePlace
  beq $t0, $t3, onePlace
  beq $t0, $t5, onePlace
  j zeroPlace
onePrint: #Used for verification in early parts of the homework
  li $v0, 1
  addi $a0, $0, 1
  syscall 
  lw $ra, 0($sp)
  addi $sp, $sp, 4 #"close" off the stack after loading back ra
  jr $ra
op_precedence: #First checks if the given operator is valid using operatorVerify (REMEMBER TO SAVE AO IN S0 AND RA) then performs the given task
  addi $sp, $sp, -8 #Before jumping to precedence helper, make space for s0 and the ra of op_precedence
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  move $s0, $a0
  jal operatorVerify #Verify that the operator is valid first
  beq $v0, $0, printErrMsg
  jal precedenceHelper #precedenceHelper returns the precedence value in v0
  lw $ra, 0($sp) #Load back the ra of the original caller of op_precedence
  lw $s0, 4($sp) #Load back s0
  addi $sp, $sp, 8 #Close off the stack
  jr $ra
precedenceHelper: #helper function for finding op precedence-- meant to be used generaly in all applicable parts
  addi $sp, $sp, -8
  sw $ra, 0($sp)
  sw $s0, 4($sp) 
  lbu $t0, 0($s0)
  li $t1, '*'
  li $t2, '/'
  li $t3, '-'
  li $t5, '+'
  beq $t0, $t1, multDivPrecedence
  beq $t0, $t2, multDivPrecedence
  j addSubPrecedence
  multDivPrecedence: #Puts a precedence value higher than that of + or / into v0, returns to caller with value in v0
    li $v0, 3 #Load in a specific value to be used in the original caller of precedence_helper
    lw $ra, 0($sp) #Load back the ra so that the program can return to the original caller of precedence_helper
    lw $s0, 4($sp) #Load back the s0 of the original caller of precedence_helper
    addi $sp, $sp, 8
    jr $ra
  addDivPrecedence:#Puts a precedence value lower than that of * or - into v0, returns to caller with value in v0
    li $v0, 2 #Loads in a specific precedence value for + or - operators
    lw $ra, 0($sp) #Load back the ra so that the program can return to the original caller of precedence_helper
    lw $s0, 4($sp) #Load back the s0 of the original caller of precedence_helper
    addi $sp, $sp, 8
    jr $ra #Jump back to the original caller of precedencehelper
printErrMsg: #printErrMsg prints out an error, and also makes sure that v0 contains 0 when returning to caller 
  la $a0, ApplyOpError
  li $v0, 4
  syscall
  li $v0, 0 #Put the 0 back into v0 before jr'ing
  lw $ra, 0($sp) #Restore the value of $ra which is that of the original caller
  lw $s0, 4($sp) #Restore the value of $s0 from the original caller, which was op_precedence
  addi $sp, $sp, 8
  jr $ra
apply_bop: #This function tskes in 2 ints, and a char for the operator--WHICH MUST BE EXTRACTED (NOT VERIFICATION NEEDED, FUNCTION ASSUMED TO TAKE IN VERIFIED STUFF
  addi $sp, $sp, -4 #Save ra before jumping to expressionExtractor
  sw $ra, 0($sp)
  #jal numberVerify
  #beq $t4, $0, printErrMsg #If first int argument is invalid, jump to error message
  #addi $s0, $a2, $0 #Load the 3rd argument which should be the secodn into s0 to be checked by the numVerify helper
  #jal numberVerify
  #beq $t4, $0, printErrMsg #If first int argument is invalid, jump to error message
  #addi $s0, $a1, $0 #Load in the operator argument into s0 to be checked in the operatorVerify helper function
  #beq $t4, $0, printErrMsg
  #addi $s0, $a0, $0 #Load in the first argument again
  #jal numberExtractor #Get the int value of the first argument
  #addi $s1, $t4, 0 #Put the value of the first argument into s1
  #addi $s0, $a2, $0 #Load in the second argument again
  #jal numberExtractor #Get the int value of the second intarg
  #addi $s2, $t4, 0 #Put the value of the second int into s2
  addi $s0, $a1, 0 #Put the operator char into s0, for use in a expressionExtractor helper function
  addi $s1, $a0, 0 #Put the value of the first int into s1
  addi $s2, $a2, 0 #Put the value of the second int into s2
  jal expressionExtractor
  li $v0, 1 
  move $a0, $t6 #expressionExtractor returns the value of the expression in t6
  syscall
  jr $ra

expressionExtractor: #Helper function that stores the value of the expression into a specific register, which then can be added to a stack or printed out depending on the part
  addi $sp, $sp, -4 #Make space for the ra
  sw $ra, 0($sp)
  lbu $t0, 0($s0) #Load the operator into t0
  li $t1, '+'
  beq $t0, $t1, plus
  plus: #Add the values in s1 and s2 into a specific register, then restore values and ra to caller
    add $t6, $s1, $s2 
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4 
    jr $ra
  li $t1, '-'
  beq $t0, $t1, minus
  minus: #subtract the values in s1 and s2 into a specific register, then restore values and ra to caller
    sub	$t6, $s1, $s2 
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
  li $t1, '*'
  beq $t0, $t1, multiply
  multiply: #multiply the values in s1 and s2 into a specific register, then restore values and ra to caller
    mul	$t6, $s1, $s2 
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4 
    jr $ra
  beq $s2, $0, printErrMsg #If second int is 0, then floor dividing cannot be done: must print error
  j divide
  divide: #divide the values in s1 and s2 into a specific register, then restore values and ra to caller: REMEMBER, FLOOR DIV BY 0 IS ERROR
    beqz $s1, printErrMsg #If the first int is a 0, then print a error: floor division not possible w 0
    divu	$s1, $s2 
    mflo $t6 #Move the QUOTIENT (EXCUDES REMAINDER AS IT IS FLOOR DIVISION) into t6
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
numberExtractor: #Extracts the number located in a argument string or char--meant to be used for single, double, triple, etc digits 
  addi $sp, $sp, -8 #Open two spaces to save the argument string in and ra
  sw $s0, 0($sp) #Save argument string, as per conventions
  sw $ra, 4($sp) #Save ra 
  lbu $t0, 0($s0) #Load into t0
  addi $t4, $0, 0 #Clean out t4--THIS WILL HOLD THE EXTRACTED NUMBER
  addi $t3, $0, 1 #Counter-- multiply value in t3 by the extracted int value, and put this result in t4
  addi $t6, $0, 10 #Thing to multiply t3 by, to mimick the 10s place
  j extractLoop
  extractLoop:
    beqz $t0, doneEx #Once done extracting, jump to a loop that restores all needed values and subsequently returns to the caller
    addi $t5, $t0, -48 #Get the int value of the given char
    mul $t6, $t5, $t3 #Add the result of the int value * the numbers place into t6
    add $t4, $t4, $t6 #Take that product and add to t4
    addi $s0, $s0, 1 #Advance string (if indeed it is a string)
    lbu $t0, 0($s0) #Put into t0
    mul $t3, $t3, $t6 #Advance t3 to next digit place
    j extractLoop
  doneEx: #Restores all values used in the numberExtractor helper function, and jr back to original caller
    lw $ra, 8($sp) #Restore the ra of the original caller of op or numberVerify
    lw $s0, 4($sp)
    addi $sp, $sp, 8
    jr $ra

    

numberVerify: #Helper function separate from is_digit--meant to be used generally in all applicable parts
  addi $sp, $sp, -8 #Open two spots on the stack for the s register containing a0 and the ra (HAVE TO USE WHEN J TO LABELS AS WELL)
  sw $s0, 0($sp) #Store the s register holding the argument
  sw $ra, 4($sp) #Store ra before jumping to loops
  lbu $t0, 0($s0)
  li $t1, '0'
  li $t2, '9'
  j numLoop
  numLoop: #Loop to verify all digit(s)
    beqz $t0, onePlace #Primarily useful for string vals, but works for single chars as well
    blt $t0, $t1, zeroPlace #Lower limit of number digit
    bgt $t0, $t2, zeroPlace #Upper limit of numer digit
    addi $s0, $s0, 1
    lbu $t0, 0($s0)
    j numLoop
onePlace: #Stores a 1 in t4 to be used as proof that the digit(s) was/were verified
  li $v0, 1
  lw $ra, 4($sp) #Restore the ra to the original caller of numberVerify
  lw $s0, 0($sp) #Restore the so of the original caller of numberVerify
  addi $sp, $sp, 8 #"Restore stack pointer to that of the original caller of numberVerify or opverify
  jr $ra
zeroPlace: #Does same thing as onePlace but with a 0 to indicate that a digit was invalid
  li $v0, 0
  lw $ra, 8($sp) #Restore the ra of the original caller of op or numberVerify
  lw $s0, 4($sp)
  addi $sp, $sp, 8
  jr $ra

printandTerminate: #Print any error message and terminate the program: same as printErrMsg but with termination added
  la $a0, ApplyOpError
  li $v0, 4
  syscall
  li $v0, 10
  syscall



