############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

############################## Do not .include any files! #############################

.text
eval: #eval evaluates a arithmetic expression taken in as a string with the help of all the previous parts.
  addi $sp, $sp, -20 #
  sw $ra, 0($sp)
  sw $s0, 4($sp) #register to store the value stack base address in
  sw $s1, 8($sp) #register to store the op stack base address in
  sw $s2, 12($sp) #Use this register to store the argument string in: extractor shouldn't alter the string
  sw $s3, 16($sp) #Use this register to store the individual chars from the argument string: extractor itself shouldn't alter the pointer
  move $t0, $a0 #Use a t register for holding the argument string: don't want to keep the value in cases such as trying to extract a full #
  li $t1, 0($t0) #Use a t register for holding the individual chars
  la $s0, val_stack #Load the address for the value stack into s0--since push and pop take care of placing the elements at their respective indexes, there's no need to add to the base address
  la $s1, op_stack  #Load the address for the operator stack into s1-- shouldn't need to be changed for same reason as val_stack
  addi $s1, $s1, 2000 #Place one stack 2000 bytes away from the other, to prevent any overlap
  addi $t8, $0, -4 #val stack top tracker-- in a t register so that it can be updated and passed accordingly (DONT USE T8 IN OTHER FNS)
  addi $t9, $0, -4 #op stack top tracker-- in a t register so that it can be used and updated accordingly (DONT USE T9 IN OTHER FNS)
  j evaLoop
  evaLoop:
    beqz $t1, popLastOps #Once the loop is done iterating over the expression, jump to another loop that pops any remaining ops/values
    addi $a0, $t1, 0 #Put t1 into a0, to be used in is_digit, valid_ops, and is_parenthesis
    jal is_digit #First check if the char is a digit. Then, jump to another function which keeps iterating over the rest of the string to check for double digit #s
    move $t5, $v0 #Put the result of is_digit into t5: to be used first in extractor, and then stackPushorPop
    jal valid_ops #Then check if the char is a operator
    move $t7, $v0 #Put the result of valid_ops into t7: in stackPushOrPop
    jal is_parenthesis #Then check if the char is a parenthesis
    move $t6, $v0 #Put the result of is_parenthesis into t6: to be used in stackPushOrPop
    addi $s2, $t0, 0 #Put the argument string into s2
    addi $s3, $t1, 0 #Put the current char into s3
    jal extractor #If t5 is 1, extractor iterates over the remaining argument string until a operator or parenthesis or end is reached, after which the value is pushed into val stack. If not a digit, the function returns the string untouched
    jal stackPushorPop #When the string is returned either because the end was reached or because op was found, jump to opStack Extractor to perform all necessary push/pop ops
    j evaLoop
  popLastOps: #popLastOps runs a loop that runs until there are no operators left in the op stack. It then jumps to a final loop
    blt $t9, $0, finalEvalLoop #If the opstack is empty, check if there is only one value left in val
    popLastOpsLoop: #popLastOpsLoop keeps running functon valuePop until either error (not enough values left), or until the op stack is empty
      blt $t9, $0, finalEvalLoop
      jal valuePop
      j popLastOpsLoop
  finalEvalLoop: #Checks if there is only one value left in the val stack and restores and jrs if so. If not, then error
    blt $t8, $0, printIllandTerminate #If empty, then error
    addi $t7, 4
    bgt $t8, $t7, printIllandTerminate #If there are more than 2 elements in the stack (ie, tp is at least 8), then error
    lw $v0, 0($s0) #Store the final value in v0
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    lw $s3, 16($sp)
    addi $sp, $sp, 20
    jr $ra
extractor: #extractor will iterate over the remaining arg string until an operator or parenthesis is reached-- will give out error if unknown char reached
  addi $sp $sp, -12
  sw $ra, 0($sp)
  sw $s2, 4($sp) #Save the argument string: only numberExtractor should alter the address of the string
  sw $s3, 8($sp) #Save the char: only numberExtractor should alter the char
  addi $t3, $t3, 0 #Reset the t3 register
  beqz $t5, jrExtractor #If the char is not a digit, jr back to the loop from the label jrExtractor
  extractorLoop: #extractorLoop goes through the current string (though not actually modifying it) and gets the full number of digits
    beqz $v0, jalExtractor #Once the full number of digits is captured, jump to a label that sends the number of digits along with t1 and t0 to numberExtractor, and then restores and jrs back to caller
    addi $t3, $t3, 1 #Increment the register containing number of digits by 1, to represent that first char
    addi $s2, $s2, 1 #Increment the argument string by 1
    lw $s3, 0($s2) #Get the new current char
    addi $a0, $s3, 0 #Pass the current char to a0
    jal is_digit
    j extractorLoop
  jalExtractor: #jalExtractor will pass the register containing the number of digits along with the argument string and char (to be modified) to numberExtractor. It will then restore all regs, and jr back. 
    jal numberExtractor #numberExtractor will use the t0, t1, and t3 registers to extract the full value, and pass it back in v0
  jrExtractor: #Restore all values and jr back to the loop
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    lw $s3, 8($sp)
    addi $sp, $sp, 12
    jr $ra
stackPushorPop: #Checks for and runs al necessary push and pop operations
  addi $sp. $sp, -8 #Open up two spots: one for ra, one for a s register containing 1
  sw $ra, 0($sp)
  sw $s2, 4($sp)
  addi $s2, $0, 1
  beq $t6, $s2, openPush #If the char is a parenthesis, jump to openPush
  beq $t7, $s2, operatorPushPop #If the char is a operator, jump to operatorPush
  beq $t5, $s2, valuePush #If the 'char' is a number, jump to valuePush
  j printBadandTerminate #If the char is none of the 3 above, print out the bad token error and terminate the program
  openPush: #openPush should call stack_push, increment s1, t0, and load into t1 accordingly. It should then jump back to evaLoop with new t1 and t0
    li $s2, 41 #Load ascii value for a closed parenthesis
    beq $t1, $s2, closedPop #If the operator is a right parenthesis, jump to closedPop
    blt $t9, $0, openPushNegative #If the op stack tracker is negative, then jump to another label that does the same thing as openPush but adds 4 to tp first
    addi $a0, $t1, 0 #Pass in the current char to a0
    addi $a1, $t9, 0 #Pass in tp to a1
    addi $a2, $s1, 0 #Pass in the base address of the op stack to a2
    jal stack_push
    move $t9, $v0 #Update the value of tp
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    addi $sp, $sp, 8
    addi $t0, $t0, 1 #Advance the argument string forward one
    lw $t1, 0($t1) #Get the next char, if there is one
    jr $ra
  openPushNegative: #If the current tp is negative (ie, the stack is empty), pass tp in as tp+4, update tp after, and jump back to evaLoop
    addi $a0, $t1, 0 #Pass in the current char
    addi $a1, $t9, 4 #Pass in tp as tp+4
    addi $a2, $s1, 0 #Pass in the base address
    jal stack_push
    move $t9, $v0 #Update tp
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    addi $sp, $sp, 8
    addi $t0, $t0, 1 #Advance the argument string forward one
    lw $t1, 0($t1) #Get the next char, if there is one
    jr $ra
  closedPop: #First checks if the stack is empty, and error if so. Then, runs a loop until a ( in the stack is reached. When ( is reached, pop it and move on to the next character.
    blt $t9, $0, printIllandTerminate #If the current stack is empty when a right parenthesis was reached, print error and terminate
    addi $a0, $t9, -4 #Pass tp-4 to a0
    addi $a1, $s1, 0 #Pass the base address to a1
    jal stack_peek #Find out what the top of the list contains
    j closedPopLoop
    closedPopLoop:
      blt $t9, $0, printIllandTerminate #If there is no matching left parenthesis found, then go to error label
      blt $v0, $s2, openPop #Once/if the left parenthesis is reached, jump to a label where it gets popped
      jal valuePop #Jump to the function where operators get popped and 2 from val stack get popped: This can be generalized to be used by another function that checks if a current op is >= to top
      j closedPopLoop
  openPop: #openPop only pops once and updates the top of the stack. It then updates the pointer of the argument string before restoring and jr'ing back to the evalLoop
    addi $a0, $t9, -4 #Passing tp-4 
    addi $a1, $s1, 0 #Passing the base address
    jal stack_pop
    beqz $v0, openPopNegative #If the new tp is 0, jump to a label where tp is correctly updated to be -4, and then update, restore, and jr
    move $t9, $a0 #Update the value of t9 to reflect the new top
    addi $t0, $t0, 1 #Advance the argument string forward one
    lw $t1, 0($t1) #Get the next char, if there is one
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    addi $sp, $sp, 8
    jr $ra
  openPopNegative: #Since the top is at base address, it can be set to -4 to indicate that the stack is empty 
    addi $t9, $t9, -8 #Have to sub -8: -4 to get to the real top of the stack, and -4 to indicate emptiness
    addi $t0, $t0, 1 #Advance the argument string forward one
    lw $t1, 0($t1) #Get the next char, if there is one
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    addi $sp, $sp, 8
    jr $ra
  valuePush: #Same as openPush, but for numbers-- uses v0 as the element to be pushed in rather than the char in the current string
    blt $t8, $0, valPushNegative #If the val stack tracker is negative, then jump to another label that does the same thing as valPush but adds 4 to tp first
    addi $a0, $v0, 0 #Pass in the current char to a0
    addi $a1, $t8, 0 #Pass in tp to a1
    addi $a2, $s0, 0 #Pass in the base address of the val stack to a2
    jal stack_push
    move $t8, $v0 #Update the value of tp
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    addi $sp, $sp, 8
    addi $t0, $t0, 1 #Advance the argument string forward one
    lw $t1, 0($t1) #Get the next char, if there is one
    jr $ra
  valPushNegative: #If the current tp is negative (ie, the stack is empty), pass tp in as tp+4, update tp after, and jump back to evaLoop
    addi $a0, $v0, 0 #Pass in the current char
    addi $a1, $t8, 4 #Pass in tp as tp+4
    addi $a2, $s0, 0 #Pass in the base address
    jal stack_push
    move $t8, $v0 #Update tp
    lw $ra, 0($sp)
    lw $s2, 4($sp)
    addi $sp, $sp, 8
    addi $t0, $t0, 1 #Advance the argument string forward one
    lw $t1, 0($t1) #Get the next char, if there is one
    jr $ra
  operatorPushPop: #operatorPush compares the current char against the elements currently in the op stack. If it has a greater or equal precedence, then the top(s) are popped 
    blt $t9, $0, openPushNegative #If the current valstack is empty, jump to openPushNegative 
    addi $a0, $t1, 0 #Pass in the current char into op_precedence
    jal op_precedence
    li $t7, '(' #First check if the top is equal to a ( before getting the prec of top: if it is,then immediately jump to openPush
    move $s2, $v0 #Put the op precedence of the current char into s2
    addi $a0, $t9, -4 #Pass the tp of the real top of val stack to a0
    addi $a1, $s1, 0 #Pass base address of op stack
    jal stack_peek
    beq $v1, $t7, openPush #If the initial top is (, then immediately jump to openPush
    move $a0, $v0 #Pass the top of the stack to a0
    jal op_precedence
    operatorPopLoop: #When either the list becomes empty or a operator of lower precedence than + is reached, jump to a label that will push the operator into the stack
      blt $t9, $0, openPushNegative
      blt $s2, $v0, openPush #When a operator that is less than the current operator is reached, jump to openPush
      addi $a0, $t9, -4 #Pass the tp of the real top of val stack to a0
      addi $a1, $s1, 0 #Pass base address of op stack
      jal stack_pop
      beq $v1, $t7, openPush
      jal valuePop #If the top of the stack is NOT a (, then jump to valuePop
      addi $a0, $t9, -4 #Pass the tp of the real top of val stack to a0
      addi $a1, $s1, 0 #Pass base address of op stack
      jal stack_peek
      move $a0, $v0 #Pass the top of the stack to a0
      jal op_precedence
      j operatorPopLoop
valuePop: #The valuePop function pops the top of op_stack and checks if there are 2 values available to be popped from val_stack. If so, it pops the two operators, applies the op, and pushes it back into val_stack.
  addi $sp, $sp, -12 #Make space for ra, and 2 s registers used to save the values popped from value_stack
  sw $ra, 0($sp)
  sw $s2, 4($sp) #Used to store the second top of the value stack
  sw $s3, 8($sp) #Used to store the initial top of the value stack
  sw $s4, 12($sp) #Used to store the operator initially at the top of the op stack
  li $t3, 8
  blt $t8, $t3, printIllandTerminate #If tp is less than 8, then error
  addi $a0, $t9, -4 #Passing tp-4 
  addi $a1, $s1, 0 #Passing the base address
  jal stack_pop
  move $s4, $v1 #Store the operator in s4
  beqz $a0, valuePopNegative #If the new tp of op is 0, jump to a label where tp is correctly updated to be -4, and then go to valstackpop
  move $t9, $v0 #Update the value of t9 to reflect the new top
  j valstackPop
  valuePopNegative: 
    addi $t9, $t9, -8 #Have to sub -8: -4 to get to the real top of the stack, and -4 to indicate emptiness
  valstackPop: #valstackPop pops two elements from the stack, and sends them along with the operator to be used in applybop and pushed back in val stack thereafter
    beqz $t3, gotoApplyBop #If both operators have been popped and aren't the only 2 in val_stack, jump directly to the label where apply_bop is called from
    addi $a0, $t8, -4 #passing tp-4
    addi $a1, $s0, $0 #Passing base address of the val_stack
    jal stack_pop
    addi $t3, $t3, -4 #Decrement t3 accordingly
    move $t8, $v0 #Update t8
    beq $t3, 4, firstValue #If the loop is currently on the initial top, then jump to firstValue to store the element into s3
    move $s2, $v1 #Move the second value in the stack to s2
    j valstackPop
    firstValue: #firstValue moves the initial top into s3
      move $s3, $v1
      j valstackPop
  gotoApplyBop: #gotoApplyBop passes in the proper values to arguments, jals to apply_bop, and pushes the result into the val_stack
    addi $a0, $s2, 0 #Pass the first value into a0
    addi $a2, $s3, 0 #Pass the second value into a2
    addi $a1, $s4, 0 #Pass the operator into a1
    jal apply_bop
    addi $a0, $v0, $0 #Pass in the result of apply_bop
    addi $a1, $t8, 0 #Pass in the updated tp
    addi $a2, $s0, 0 #Pass in the base address of the val stack
    jal stack_push 
    move $t8, $v0 #Update tp
    lw $ra, 0($sp)
    lw $s2, 4($sp) #Used to store the second top of the value stack
    lw $s3, 8($sp) #Used to store the initial top of the value stack
    lw $s4, 12($sp) #Used to store the operator initially at the top of the op stack
    addi $sp, $sp, 12
    jr $ra 
is_digit:
  addi $sp, $sp, -4 #Open two spots on stack
  sw $ra, 0($sp) #Save ra before jumping to helper function
  jal numberVerify #numberVerify will return either a 1 or a 0 in v0, which will indicate whether it is a digit or not
  beqz $v0, printErrMsg
  lw $ra, 0($sp)
  addi $sp, $sp, 4
  jr $ra 
is_parenthesis: #is_parenthesis checks if the inputted char is a open or closed parenthesis
  addi $sp, $sp, -12 #Use s0 and s1 for the ascii values of the left and right parenthesis symbols respectively
  sw $s0, 0($sp)
  sw $s1, 4($sp)
  sw $ra, 8($sp)
  li $s0, '('
  li $s1, ')'
  beq $t1, $s0, onePlace1
  beq $t1, $s1, onePlace1
  j zeroPlace1
  onePlace1: #onePlace1 is the same as onePlace but implemented specifically for the is_parenthesis function (in terms of what registers are restored)
    li $v0, 1
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    sw $ra, 8($sp)
    addi $sp, $sp, 12
    jr $ra
  zeroPlace1: #zeroPlace1 is the same as zeroPlace but implemented specifically for the is_parenthesis function (in terms of what registers are restored)
    li $v0, 0
    lw $s0, 0($sp)
    lw $s1, 4($sp)
    sw $ra, 8($sp)
    addi $sp, $sp, 12
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
stack_pop: #Pop takes in 2 arguments: the index representing the address OF top, and the base address
  blt $a0, $0, printandTerminate #If tp<0, then print any error and terminate
  addi $v0, $a0, 0 #Put tp-4 into v0
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
  sw $s0, 4($sp) #Save s0 before loading the argument into it
  move $s0, $a0 #Save the argument in s0 as a backup
  jal operatorVerify #operatorVerify will return a 1 or 0 in v0, which caller of valid_ops can then use to verify accordingly
  beqz $v0, printErrMsg
  lw $ra, 0($sp)
  lw $s0, 4($sp)
  addi $sp, $sp, 8
  jr $ra #For jr, only need to follow conventions for it WHEN CALLING ANOTHER FUNCTION (AKA THE JAL INSTRUCTION)
operatorVerify: 
  addi $sp, $sp, -20 #Open 6 spots on the stack for s registers containing the op values, the s register containing the arg, and ra
  sw $ra, 0($sp)
  sw $s1, 4($sp)
  sw $s2, 8($sp)
  sw $s3, 12($sp)
  sw $s4, 16($sp)
  li $s1, '*'
  li $s2, '/'
  li $s3, '-'
  li $s5, '+'
  beq $a0, $s1, onePlace
  beq $a0, $s2, onePlace
  beq $a0, $s3, onePlace
  beq $a0, $s5, onePlace
  zeroPlace:
    li $v0, 0
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    addi $sp, $sp, 20
    jr $ra
  onePlace:
    li $v0, 1
    lw $ra, 0($sp)
    lw $s1, 4($sp)
    lw $s2, 8($sp)
    lw $s3, 12($sp)
    lw $s4, 16($sp)
    addi $sp, $sp, 20
    jr $ra
  
op_precedence: #First checks if the given operator is valid using operatorVerify (REMEMBER TO SAVE AO IN S0 AND RA) then performs the given task
  addi $sp, $sp, -4 
  sw $ra, 0($sp)
  jal operatorVerify #Verify that the operator is valid first
  beq $v0, $0, printErrMsg
  jal precedenceHelper #precedenceHelper returns the precedence value in v0
  lw $ra, 0($sp) #Load back the ra of the original caller of op_precedence
  addi $sp, $sp, 4 #Close off the stack
  jr $ra
precedenceHelper: #helper function for finding op precedence-- meant to be used generaly in all applicable parts
  addi $sp, $sp, -12 #Open 6 spots on the stack for s registers containing the op values, the s register containing the arg, and ra
  sw $ra, 0($sp)
  sw $s1, 4($sp)
  sw $s2, 8($sp)
  li $s1, '*'
  li $s2, '/'
  beq $a0, $s1, multDivPrecedence
  beq $a0, $s2, multDivPrecedence
  j addSubPrecedence
  multDivPrecedence: #Puts a precedence value higher than that of + or / into v0, returns to caller with value in v0
    li $v0, 3 #Load in a specific value to be used in the original caller of precedence_helper
    lw $ra, 0($sp) #Load back the ra so that the program can return to the original caller of precedence_helper
    lw $s1, 4($sp) #Load back the s0 of the original caller of precedence_helper
    lw $s2, 8($sp)
    addi $sp, $sp, 12
    jr $ra
  addSubPrecedence:#Puts a precedence value lower than that of * or - into v0, returns to caller with value in v0
   li $v0, 2 #Load in a specific value to be used in the original caller of precedence_helper
   lw $ra, 0($sp) #Load back the ra so that the program can return to the original caller of precedence_helper
   lw $s1, 4($sp) #Load back the s0 of the original caller of precedence_helper
   lw $s2, 8($sp)
   addi $sp, $sp, 12
   jr $ra
printErrMsg: #printErrMsg prints out an error, and also makes sure that v0 contains 0 when returning to caller 
  la $a0, ApplyOpError
  li $v0, 4
  syscall
  li $v0, 0 #Put the 0 back into v0 before jr'ing
  lw $ra, 0($sp) #Restore the value of $ra which is that of the original caller
  lw $s0, 4($sp) #Restore the value of $s0 from the original caller, which was op_precedence
  addi $sp, $sp, 8
  jr $ra
apply_bop: #This function takes in 2 ints, and a char for the operator--WHICH MUST BE EXTRACTED (NOT VERIFICATION NEEDED, FUNCTION ASSUMED TO TAKE IN VERIFIED STUFF
  addi $sp, $sp, -16 #Save ra before jumping to expressionExtractor
  sw $ra, 0($sp)
  sw $s0, 4($sp)
  sw $s1, 8($sp)
  sw $s2, 12($sp)
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
  move $v0, $t6 #expressionExtractor returns the result in t6, so have to put into v0 to be returned
  lw $ra, 0($sp)
  lw $s0, 4($sp)
  lw $s1, 8($sp)
  lw $s2, 12($sp)
  addi $sp, $sp, 16 #Save ra before jumping to expressionExtractor
  jr $ra
expressionExtractor: #Helper function that stores the value of the expression into a specific register, which then can be added to a stack or printed out depending on the part
  addi $sp, $sp, -4 #Make space for the ra
  sw $ra, 0($sp)
  lbu $t0, 0($s0) #Load the operator into t0
  li $t1, '+'
  beq $t0, $t1, plus
  li $t1, '-'
  beq $t0, $t1, minus
  li $t1, '*'
  beq $t0, $t1, multiply
  beq $s2, $0, printBopMsg #If second int is 0, then floor dividing cannot be done: must print error
  j divide
  plus: #Add the values in s1 and s2 into a specific register, then restore values and ra to caller
    add $t6, $s1, $s2 
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4 
    jr $ra
  minus: #subtract the values in s1 and s2 into a specific register, then restore values and ra to caller
    sub	$t6, $s1, $s2 
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
  multiply: #multiply the values in s1 and s2 into a specific register, then restore values and ra to caller
    mul	$t6, $s1, $s2 
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4 
    jr $ra
  divide: #divide the values in s1 and s2 into a specific register, then restore values and ra to caller: REMEMBER, FLOOR DIV BY 0 IS ERROR
    beqz $s1, printErrMsg #If the first int is a 0, then print a error: floor division not possible w 0
    divu	$s1, $s2 
    mflo $t6 #Move the QUOTIENT (EXCUDES REMAINDER AS IT IS FLOOR DIVISION) into t6
    #lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
  printBopMsg: #Prints rhe ApplyBop error message and terminates the program
    la $a0, ApplyOpError
    li $v0, 4
    syscall
    li $v0, 10
    syscall
numberExtractor: #Extracts the number located in a argument string or char--meant to be used for single, double, triple, etc digits 
  addi $sp, $sp, -8#Open spot for ra and a s register that holds the value 10
  sw $ra, 0($sp) #Save ra
  sw $s0, 4($sp) 
  li $s0, 10
  addi $a0, $t3, 0 #Pass the digit counter to a0 for use in powerGetter
  jal powerGetter #Jal to powerGetter to get the power of the greatest digit: divide this val by 10 in the loop each time to get the next power
  j extractLoop
  extractLoop:
    beqz $t3, doneEx #Once done extracting, jump to a loop that restores all needed values and subsequently returns to the caller
    addi $t3, $t0, -48 #Get the int value of the given char
    mul $t4, $v1, $t1 #Multiply the int value by the given dec place
    add $v0, $v0, $t4 #Add the value into v0
    addi $t0, $t0, 1 #Advance string (if indeed it is a string)
    lbu $t1, 0($t0) #Put into t0
    addi $t3, $t3, -1 #Decrement the digit counter
    div $v1, $s0
    mflo $v1 #Put the result of current highest power/10 back into v1
    j extractLoop
  doneEx: #Restores all values used in the numberExtractor helper function, and jr back to original caller
    lw $ra, 0($sp) #Restore the ra of the original caller of op or numberVerify
    addi $sp, $sp, 4
    jr $ra
  powerGetter: #powerGetter should return the power of the current digit in the given number, which is done with a loop that mults 10 each time
    addi $sp, $sp, -8
    sw $s0, 0($sp) #Use s0 to store the value 10, which v1 gets multiplied by each time in the powerLoop
    sw $ra, 4($sp)
    li $s0, 10
    addi $a0, $a0, -1 #Decrement the digit counter by 1
    addi $v1, $0, 1 #Reset v1: this will contain the power of the current digit
    powerLoop:
     beqz $a0, powerReturner #Once the full power of the number has been extracted, jump to a label that restores and jrs
     mult $v1, $v1, $s0 #Multiply v1 by 10
     addi $a0, $a0, -1 #Decrement the digit counter
     j powerLoop
    powerReturner: #Restores and jrs back to the function
      lw $s0, 0($sp)
      lw $ra, 4($sp)
      addi $sp, $sp, 8
      jr $ra


numberVerify: #Helper function separate from is_digit--meant to be used generally in all applicable parts
  addi $sp, $sp, -4 
  sw $ra, 0($sp)
  li $t6, '0'
  li $t7, '9'
  blt $a0, $t6, zeroPlaceNum
  bgt $a0, $t7, onePlaceNum
  onePlaceNum: 
    li $v0, 1
    lw $ra, 0($sp) #Restore the ra to the original caller of numberVerify
    addi $sp, $sp, 4 #"Restore stack pointer to that of the original caller of numberVerify or opverify
    jr $ra
  zeroPlaceNum: 
    li $v0, 0
    lw $ra, 0($sp) #Restore the ra of the original caller of op or numberVerify
    addi $sp, $sp, 4
    jr $ra
printandTerminate: #Print any error message and terminate the program: same as printErrMsg but with termination added
  la $a0, ApplyOpError
  li $v0, 4
  syscall
  li $v0, 10
  syscall
printIllandTerminate: #Print out the ill formed error message and terminate the program: same as printandTerminate but for a specific label
  la $a0, ParseError
  li $v0, 4
  syscall
  li $v0, 10
  syscall
printBadandTerminate: #Print out the BadToken error message and terminate the program
  la $a0, BadToken
  li $v0, 4
  syscall
  li $v0, 10
  syscall
