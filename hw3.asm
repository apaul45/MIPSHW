# Ayon Paul
# aypaul
# 113318933

############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################

.text

load_game: #load_game should parse through a inputted text file, and set up the game from values in that txt file
	addi $sp, $sp, -16
	sw $ra, 0($sp) #Store jr before jal'ing to the first helper function
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp) #s2 should contain the pointer to the state struct in a0
	addi $s2, $a0, 0 #Save the state pointer in s2, for use in helper functions
	li $v0, 13
	move $a0, $a1 #Move the name of the filename string to a0, to be used to open the given file
	li $a1, 0 #Load in the "read-only" flag into a1
	li $a2, 0
	syscall #Perform the syscall operation that will open the inputted file
	blt $v0, $0, negativeLGReturn #If the read-only operation couldn't be performed, jump to a label that will return -1 in v0 and v1
	move $s1, $v0 #Move the file descriptor to t9--each time the helper functions below are called, a0 should be initialized as s1
	li $s0, 1 #Flag that indicates that the following helper should store the resulting value (if valid) into the top mancala
	jal topBotMancalaStones #If the operation was successful, then jump to a helper function that checks and updates the byte used for the top mancala accordingly
	li $s0, 2 #Flag that indicates that the helper should store the resulting value (if valid) into the byte for bottom mancala
	jal topBotMancalaStones
	li $s0, 3 #Flag that indicates that the helper should store the resulting value (if valid) into the byte representing the number of pockets in each row
	jal topBotMancalaStones
	li $s0, 0 #Flag that indicates that the following helper should use i=0 for the row 
	jal topBotPockets #Jump to the helper function that parses the last 2 lines and stores them in the game board if no error is found
	li $s0, 2 #Flag that indicates that the following helper should use i=1 for the row 
	jal topBotPockets
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	topBotMancalaStones: #This helper should read and convert the first 3 lines of the txt file 
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		addi $t0, $0, 0 #Reset the t0 register-- this will be the counter 
		addi $t2, $sp, -12 #Open a spot for the char read by syscall 14: Can keep actual pointer of the stack at the caller of this helper--this is the input buffer
		li $t4, 13 #Load the ascii value for a open r slash into t4
		addi $t5, $t2, 0 #Save the t2 pointer: This will be used to extract the dec value of each digit starting from the one iwth the highest power
		tmsLoop:
			add $a0, $0, $s1 #Load the file descriptor into a0
			add $a1, $t2, $0 #Set the input buffer to t2
			li $a2, 1 #Set the max chars to read as 1 
			li $v0, 14 
			syscall
			lbu $t6, 0($t2) #Load the newly read char into t6
			ble $t6, $t4, parseInt #When a '/' is reached, take the value in t6 and parse it to get the actual int value, then store in byte 0
			addi $t2, $t2, -4 #Decrement t2 down to the next spot on the stack
			addi $t0, $t0, 1 #Increment the current counter
			j tmsLoop
		parseInt: #parseInt should parse through the given string in t5
			add $a0, $0, $t0 #Pass the counter to a0, to be used in powerGetter
			jal powerGetter #powerGetter will return the max power in v1
  	jal extractor
			li $t0, 1
			beq $s0, $t0, storeTopManc #If the flag is 1, then store this extracted value into the .byte 1 and bytes 6 and 7 of the gameboard (as ascii)
			li $t0, 2
			beq $s0, $t0, storeBottomManc #If the flag is 2, then store into .byte 0 and as bytes 22 and 23 of the gameboard (as ascii)
			li $t0, 3
			beq $s0, $t0, storePocketStones #If the flag is 3, then store in 2 places: byte .2, and byte .3
			storeBottomManc: #First, load the address stored in the top mancala first and check the sum, then store v0 if check is good
				addi $t4, $s2, 0 #Load the base address of the state struct into t0
			 # addi $t0, $t0, 1 #Advance to the effective address of the top_mancala byte
				# lbu $t1, 0($t0) #Load the byte containing the number of stones in the top mancala
				# addi $t4, $t1, $v0 #Put the sum of the top and bottom mancala stones into t3
				# li $t7, 99 #Load in the max number of stones in the entire board
				# bge $t4, $t7, part1v0Zero #If the sum of the top and bottom mancalas is >= 99, put 0 in t3 (v0 storer)
				# addi $t0, $t0, -1 #Go back to the base address
				sb $v0, 0($t4) #Store the extracted number from the second line into byte 0 of the state struct
				li $t0, 10
				jal getPocketNumber
				sll $t3, $t3, 2 #Multiply the pocket number by 4
				addi $t4, $s2, 6 #Move to the beginning of the gameboard
				add $t4, $t4, $t3 #Move to 4(pocketnum) + 6
				addi $t4, $t4, 2 #Move to byte 6+4(pocketnum) + 2 of the gameboard-- this is the beginning of 2 indexes where the bottom mancala is stored
				blt $v0, $t0, storeBottomManc2 #If the extracted value is less than 10, jump to a different label that will store 0 in the first byte of the bott mancala
				lbu $t3, 0($t5) #Load in the first ascii read 
				sb $t3, 0($t4) #Store at the given byte in the state struct
				addi $t4, $t4, 1 #Move to byte 4(pocketcount)-1
				addi $t5, $t5, -4 #Move to the next ascii
				lbu $t3, 0($t5) #Load in the second ascii read 
				sb $t3, 0($t4) #Store at the given byte in the state struct				
				j lineAdvancer #Jump to a label that will check what the next line in the file is (r or n), and advance the file 
			storeBottomManc2:
				addi $t3, $0, 48 #Put the ascii value of 0 into t3
				sb $t3, 0($t4) #Store at the given byte in the state struct
				addi $t4, $t4, 1 #Move to byte 4(pocketcount)-1
				lbu $t3, 0($t5) #Load in the first ascii read 
				sb $t3, 0($t4) #Store at the given byte in the state struct				
				j lineAdvancer #Jump to a label that will check what the next line in the file is (r or n), and advance the file 
			storeTopManc: #Store the extracted int into byte 1 of the state struct and bytes 6 and 7 of the state struct (gameboard)
				addi $t0, $s2, 0
				addi $t0, $t0, 1
				sb $v0, 0($t0) #Store the extracted value in byte 1 of the state struct
				li $t0, 10
				addi $t4, $s2, 6 #Move to the first byte in the gameboard struct
				blt $v0, $t0, storeTopManc2 #If the extracted value is less than 10, jump to a different label that will put a 0 in the first char of the gameboard
				lbu $t3, 0($t5) #Load in the first ascii read 
				sb $t3, 0($t4) #Store at the given byte in the state struct
				addi $t4, $t4, 1 #Move to byte 7
				addi $t5, $t5, -4 #Move to the next ascii
				lbu $t3, 0($t5) #Get the second ascii read 
				sb $t3, 0($t4) #Store the second ascii into byte 7
				j lineAdvancer
			storeTopManc2:
				addi $t3, $0, 48 #Put the ascii value of 0 into t3
				sb $t3, 0($t4) #Store at the given byte in the state struct
				addi $t4, $t4, 1 #Move to byte 7
				lbu $t3, 0($t5) #Get the actual ascii read 
				sb $t3, 0($t4) #Store the second ascii into byte 7
				j lineAdvancer
			storePocketStones: #Stores the extracted value in 2 places in the state struct
				addi $t0, $s2,0
				addi $t0, $t0, 2 #Advance to .byte 2, where the number of pockets is stored as the number of pockets in the top row
				sb $v0, 0($t0)
				addi $t0, $t0, 1 #Advance to byte .3, where the number of pockets is stored as the number of pockets in the bottom row
				sb $v0, 0($t0)
				j lineAdvancer
	topBotPockets: #This helper should read and convert the last 2 lines of the txt file. In doing so, it should check for error and return accordingly
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		jal getPocketNumber #Jump to a function that will get the number of pockets in one row
		beqz $s0, mancalasStonesSum #If the flag is a 0, jump to a label that will initialize t1 to be the sum of the two mancalas (then the sum of the two mancalas + pockets in one row)
		addi $t0, $0, 0 #Reset the t0 register-- this wil be the pocket counter 
		addi $t2, $sp, -4 #Create a input buffer for the char reading
		li $t4, 13 #Load the ascii value for a carruage return into t4
		j tbpLoop
		mancalasStonesSum:
			addi $t0, $0, 0 #Reset the t0 register-- this will be pocket counter
			jal mancalasSum #Jump to a function that will add the sum of the stones in the top+bot mancalas to t1--may also add 
			addi $t2, $sp, -4 #Open a spot for the char read by syscall 14: Can keep actual pointer of the stack at the caller of this helper--this is the input buffer
			li $t4, 13 #Load the ascii value for a slash r into t4
			j tbpLoop
		tbpLoop: #This loop should check 2 chars at a time (since every two chars is one pocket) and increment the pocket counter accordingly after parsing through the 2 given chars
			addi $t5, $t2, -4 #Set t5 as the spot on the stack right after t2
			add $a0, $0, $s1 #Set a0 to the file descriptor from the original syscall 13
			add $a1, $t2, $0 #Set the input buffer to t2
			li $a2, 1 #Set the max chars to read as 1
			li $v0, 14 
			syscall
			beqz $v0, tbpReturn1num #If the end of the file is reached, jump to tbpReturn1num
			lbu $t6, 0($t2)
			ble $t6, $t4, tbpReturn1num #If a slash is met and neither the pocket limit nor the stone limit has been exceeded, jump to the tbpReturn1num label
			sb $t6, 0($t5) #Store the char into t5
			add $a0, $0, $s1 #Set a0 to the file descriptor from the original syscall 13
			add $a1, $t2, $0 #Set the input buffer to t2
			li $a2, 1 #Set the max chars to read as 1
			li $v0, 14 
			syscall
			beqz $v0, tbpReturn1num #If the end of the file is reached, jump to tbpReturn1num
			lbu $t6, 0($t2)
			ble $t6, $t4, tbpReturn1num #If a slash is met and neither the pocket limit nor the stone limit has been exceeded, jump to the tbpReturn1num label
			sb $t6, 1($t5) #Put the second char into 1($t5), so that the full 2 char string is in t5 to be used in tbpParse
			move $a0, $t5 #Put the string into a0 to be used in tbpParse
			jal tbpParse
			add $t1, $t1, $v0 #Update the total number of stones in the game board+both mancalas
			li $t5, 99
			bgt $t1, $t5, pocketCheck #If the total of stones is over the limit, jump to a label that will iterate over the remaining chars to see if the pocket limit is passed
			addi $t5, $t0, 1 #Advance the pocket counter by 1
			li $t8, 49
			bgt $t5, $t8, stoneCheck #If the pocket limit has been reached, jump to a label that will check if the stone limit was reached-- ie, it will parse through the end of the line and get the total number of stones
			addi $t5, $s2, 8 #Move to the gameboard portion of the state struct, specifically the byte number where the pokcets begin to be stored
			move $a1, $a0 #Move the address where the 2 char string is stored into a1
			li $a0, 2 #Load the column size into a0
			jal gameboardStorer #Jump to a function that will store each digit (as ascii) into gameboard
			addi $t0, $t0, 1 #(Actually) increment the loop counter-- indexes should start at 0
			j tbpLoop
		stoneCheck: #stoneCheck should iterate over the remaining line to gather the total number of stones in the gameboard+mancalas-- if stone limit isn't reached, then label jumpts to tbpReturn10, else tbpReturn00
				addi $t5, $t2, -4
				add $a0, $0, $s1 #Set the file descriptor input as 0-- reading from standard input
				add $a1, $t2, $0 #Set the input buffer to t2
				li $a2, 1 #Set the max chars to read as 1
				li $v0, 14 
				syscall
				lbu $t6, 0($t2) #Get the first char that was read by the syscall
			 ble $t6, $t4, tbpReturn10 #If a carriage return or new line slash is met, jump to a function that will return v0 as 1 and v1 as 0
				beqz $v0, tbpReturn10 #If the end of the file is reached the stone limit wasn't exceeded, jump to tbpReturn0num
				sb $t6, 0($t5)
				add $a0, $0, $s1 #Set the file descriptor input as 0-- reading from standard input
				add $a1, $t2, $0 #Set the input buffer to t2
				li $a2, 1 #Set the max chars to read as 1
				li $v0, 14 
				syscall
				lbu $t6, 0($t2) #Get the second char that was read by the syscall
			 ble $t6, $t4, tbpReturn10 #If a carriage return or new line slash is met, jump to a function that will return v0 as 1 and v1 as 0
				beqz $v0, tbpReturn10 #If the end of the file is reached the stone limit wasn't exceeded, jump to tbpReturn0num
				sb $t6, 1($t5) #Store the second char into t5, to be used in the parse helper
				move $a0, $t5
				jal tbpParse
				add $t1, $t1, $v0 #Update the stone count
				li $t5, 99
				bgt $t1, $t5, tbpReturn00 #If the stone limit is exceeded at any time during this loop, jump to tbpReturn00
				j stoneCheck
		pocketCheck: #pocketCheck should iterate over the remaining line to see if the pocket limit is exceeded, and then jump to a tbpReturn0 label (either 00 or 0num)
				addi $t0, $t0, 1 #Increment the pocket counter by 1 to represent the pocket where the stone limit was exceeded
				li $t5, 49
				bgt $t0, $t5, tbpReturn00 #If the pocket limit is exceeded when the pocket that went over the stone limit is accounted for, jump right to tbp00
				pcLoop1:
					addi $t5, $t2, -4
					add $a0, $0, $s1 #Set the file descriptor input as 0-- reading from standard input
					add $a1, $t2, $0 #Set the input buffer to t2
					li $a2, 1 #Set the max chars to read as 1
					li $v0, 14 
					syscall
			 	lbu $t6, 0($t2) #Get the first char that was read by the syscall
				 ble $t6, $t4, tbpReturn0num #If a carriage return or new line slash is met, jump to a function that will retrn v0 as 0 and v1 as the number of pockets total
					beqz $v0, tbpReturn0num #If the end of the file has been reached and the pocket limit wasn't exceeded, jump to a function that will return v0 as 0 and v1 as number of pockets total
					add $a0, $0, $s1 #Set the file descriptor input as 0-- reading from standard input
					add $a1, $t2, $0 #Set the input buffer to t2
					li $a2, 1 #Set the max chars to read as 1
					li $v0, 14 
					syscall
			 	lbu $t6, 0($t2) #Get the second char 
				 ble $t6, $t4, tbpReturn0num #If a carriage return or new line slash is met, jump to a function that will retrn v0 as 0 and v1 as the number of pockets total
					beqz $v0, tbpReturn0num 
					addi $t0, $t0, 1 #Advance the pocket counter
					li $t8, 49
			 	bgt $t0, $t8, tbpReturn00 #If the pocket counter is indeed over the limit, then jump to the 00 return to return v0 and v1 as 0 
					j pcLoop1
		tbpReturn10: #This label should specifically return v0 as 1 and v1 as 0
			beqz $s0, lineAdvancer #If the flag is 0 (meaning the file is on the second to last line), then advance the line accordingly to the last line in the file
			addi $v0, $0, 1
			addi $v1, $0, 0
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra
		tbpReturn1num: #This label should specifically return v0 as 0 and v1 as the total number of pockets
			beqz $s0, lineAdvancer #If the flag is 0 (meaning the file is on the second to last line), then advance the line accordingly to the last line in the file
			addi $v0, $0, 1
			sll $t3, $t3, 1
			add $v1, $0, $t3
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra
		tbpReturn0num: #This label should specifically return v0 as 0 and v1 as 1
			beqz $s0, lineAdvancer #If the flag is 0 (meaning the file is on the second to last line), then advance the line accordingly to the last line in the file
			addi $v0, $0, 0
			sll $t3, $t3, 1
			add $v1, $0, $t3
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra
		tbpReturn00: #This label should specifically return both v0 and v1 as 0
		 beqz $s0, lineAdvancer #If the flag is 0 (meaning the file is on the second to last line), then advance the line accordingly to the last line in the file
			addi $v0, $0, 0
			addi $v1, $0, 0
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra
getPocketNumber: #getPocket number should load the number of pockets in one row
	add $t0, $0, $s2
	addi $t0, $t0, 2 #Get the efective address of byte 2 in the state struct-- this is where the pocket num is stored
	lbu $t3, 0($t0) #Put the number of pockets in one row into t3
	jr $ra
gameboardStorer: #gameboardStorer should convert store each of the chars from the input buffer in their respective positions in the 2d gameboard array
		mul $t8, $s0, $t3 #Put the result of flag(aka the i)*pocket number into t8
		mul $t9, $t0, $a0 #Put the result of the column index * num columns into t9
		add $t7, $t8, $t9 #Get i*num rows + j*num columns-- where j is the col index for the first char out of the 2
		add $t5, $t5, $t7 #Get to the effective address of the first char in the gameboard
		lbu $t6, 0($a1) #Get the first char 
		sb $t6, 0($t5) #Store the first char at its effective address
		addi $t5, $t5, 1 #Get to the effective address of the second char-- ie, same i, but j+1
		lbu $t6, 1($a1) #Get the second char 
		sb $t6, 0($t5) #Store the second char at its effective address
		jr $ra
mancalasSum: #Mancalas sum should load the respective numbers from the state struct, and add them to t1
	addi $t4, $s2, 0 #Load the base address (the pointer to the state struct) into t4
	lbu $t1, 0($t4) 
	addi $t4, $t4, 1
	lbu $t6, 0($t4)
	add $t1, $t1, $t6
	jr $ra
tbpParse: #tbpParse should take the value in the first argument and convert it to a parse-- a0 is either a 1 or 2 digit number
	li $t5, 10 #Put the value of 10 into t5-- which the first (greatest power) char should be multiplied by 
	lbu $t8, 0($a0) #Load the first char into t8
	addi $t8, $t8, -48 #Get the dec value of the char
	mult	$t8, $t5	#Multiply the greatest power (2) by 10
	mflo	$v0				# copy Lo to $v0
	lbu $t8, 1($a0) #Load the second digit (the last digit) into t8
	addi $t8, $t8, -48
	add $v0, $v0, $t8 #Add the dec values of the two chars together to get the full extracted number in v0
	jr $ra
lineAdvancer: #lineAdvancer should check what the next char in the line is, and advance the file accordingly based on that line
	li $t0, 13 
	beq $t6, $t0, rAdvance #If the char is a slash r, then jump to a label that will advance the file to the next available line
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	rAdvance: #rAdvance should put max chars to read as 2 into syscall 14
			li $v0, 14
			add $a0, $0, $s1
			add $a1, $t2, $0
			li $a2, 1 #Max chars to read should be 1-- a carriage return or nl line is only 1 char
			syscall
			# li $t7, 2 #What the loop counter is compared against
			# addi $t0, $0, 0 #Reset t0--counter for this loop
			# rAdvanceLoop:
			# 	beq $t0, $t7, rAdvanceReturn #Once the loop is done, jump to a label that will restore all values and jr
			# 	li $a0, 0
			# 	add $a1, $t2, $0
			# 	li $a2, 1
			# 	li $v0, 14
			# 	syscall
			# 	addi $t0, $t0, 1
			# 	j rAdvanceLoop
		rAdvanceReturn:
			lw $ra, 0($sp)
			addi $sp, $sp, 4
			jr $ra
extractor:
		addi $sp, $sp, -8
		sw $s0, 0($sp)
		sw $s1, 4($sp)
		addi $s1, $t5, 0 #Put the pointer of the initial input buffer t5 into t6 for use in the extractor loop
		addi $v0, $0, 0 #Reset v0-- the extracted number is returned in this 
		li $s0, 10 #Use this to lower the power that the current digit in the loop is multiplied by
		extractorLoop:
  	beqz $t0, doneEx #Once done extracting, jump to a loop that restores all needed values and subsequently returns to the caller
			lbu $t1, 0($s1) #Put into t1
  	addi $t1, $t1, -48 #Get the int value of the given char
  	mul $t4, $v1, $t1 #Multiply the int value by the given dec place
  	add $v0, $v0, $t4 #Add the value into v0
			addi $s1, $s1, -4 #Move to the next char stored in the runtime stack
 		addi $t0, $t0, -1 #Decrement the digit counter
  	div $v1, $s0
 		mflo $v1 #Lower the power for the next digit
  	j extractorLoop
 	doneEx: 
			lw $s0, 0($sp)
			lw $s1, 4($sp)
			addi $sp, $sp, 8
   jr $ra
powerGetter: #powerGetter should return the power of the current digit in the given number, which is done with a loop that mults 10 each time
  	addi $sp, $sp, -8
  	sw $s0, 0($sp) #Use s0 to store the value 10, which v1 gets multiplied by each time in the powerLoop
			sw $ra, 4($sp)
  	li $s0, 10
  	addi $a0, $a0, -1 #Decrement the digit counter by 1
  	addi $v1, $0, 1 #Reset v1: this will contain the power of the current digit: starts at 1 and works up
  	powerLoop:
    	beqz $a0, powerReturner #Once the full power of the number has been extracted, jump to a label that restores and jrs
    	mult $v1, $s0 #Multiply v1 by 10
    	mflo $v1 #Put the result into v1
    	addi $a0, $a0, -1 #Decrement the digit counter
    	j powerLoop
  	powerReturner: #Restores and jrs back to the function
    	lw $s0, 0($sp)
    	lw $ra, 4($sp)
    	addi $sp, $sp, 8
    	jr $ra
negativeLGReturn: #This label should return v0 and v1 both as -1
	addi $v0, $0, -1
	addi $v1, $0, -1
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra
part1v0Zero: #part1v0Zero should put the return value for v0 (in this case, 0) into the t3 register
	addi $t3, $0, 0 
	lw $ra, 0 ($sp)
	addi $sp, $sp, 4
	jr $ra
get_pocket: #get_pocket should return the number of pockets in the specified distance for the specified player (B or T)
	blt $a2, $0, part2NegReturn #If the distance is not a valid number return -1 in v0
	li $t0, 'B'
	beq $a1, $t0, part2BottomReturn #If the player is 'B', jump to a label that will handle finding the pocket specified by distance
	li $t0, 'T'
	beq $a1, $t0, part2TopReturn #If the player is 'T', jump to a label that will handle finding the pocket specified by distance
	part2NegReturn:
		li $v0, -1
		jr $ra
	part2BottomReturn: #The bottom return should start at the last pocket of the gameboard struct(ie, pocketnumber*4-2), and use the distance to get to the specified pocket
		addi $sp, $sp, -8
		sw $ra, 0($sp)
		sw $s2, 4($sp)
		addi $s2, $a0, 0 #Put the base address of the state struct into s2, to be used in the getPocketNumber helper function
		addi $a0, $a0, 6 #Move to the gameboard portion of the state struct
		jal getPocketNumber
		sll $t3, $t3, 2 #Multiply the pocket number by 4
		sll $a2, $a2, 1 #Multiply the distance by 2, to get to the first char in the pocket
		add $a0, $a0, $t3 #Move to the pocket using the state pointer
		sub $a0, $a0, $a2 #Move back to the specified pocket
		jal tbpParse
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
	part2TopReturn: #The top return should start at the start of the gameboard (since  the top mancala appears to be on the left from perspective of a B player) and use the distance to get to the specified pocket
		addi $sp, $sp, -4
		sw $ra, 0($sp)
		addi $a0, $a0, 8 #Move to the gameboard portion of the state struct-- specifically the part where pockets begin to be stored
		sll $a2, $a2, 1 #Multiply the distance by 2
		add $a0, $a0, $a2 #Move to the desired pocket
		jal tbpParse
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
set_pocket: #set_pocket should set and return the number of pockets in the specified dist of the specified player, using magnitude of the dist and player
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s2, 4($sp)
	blt $a3, $0, wrongSizeReturn #If the inputted size is negative, return v0 as -2
	li $t0, 100
	bge $a3, $t0, wrongSizeReturn #If the inputted size is negative, return v0 as -2
	addi $s2, $a0, 0 
	jal getPocketNumber
	move $t1, $t3 #Move the number of pockets into t1
	jal twosCompExtractor #This helper will check and extract the magnitude of distance if it is a negative value
	move $t8, $v0 #Put the new distance into t0
	bge $t8, $t1, wrongPDReturn #If the distance is not valid for this current gameboard, then return v0 as -1
	move $a2, $a1 #Put the player byte into a2, for use in the extractor helper
	jal twosCompExtractor
	move $t2, $v0 #Put the player byte into t2
	li $t3, 'B'
	beq $t2, $t3, setInBottom #If the player is a B, then jump to a label that will store the digits in size as char bytes in the desired pocket given by distance
	li $t3, 'T'
	beq $t2, $t3, setInTop #If the player is a T, then jump to a label that will store the digits in size as char bytes in the desired pocket given by distance
	wrongPDReturn:
		li $v0, -1
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
	wrongSizeReturn:
		li $v0, -2
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
	setInTop: #setInTop does the same thing as setInBotton but in fewer steps
		addi $a0, $a0, 8
		sll $t8, $t8, 1 #Multiply the distance by 2
		add $a0, $a0, $t8 #Move to the desired pocket
		addi $v0, $a3, 0 #Put the value of size into v0, to be returned 
		jal storeChar
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra		
	setInBottom: #setInBottom should be like part2BottomReturn, but for storing bytes rather than loading them
		addi $a0, $a0, 8 #Move to the gameboard portion of the state struct-- specifically the pocket portion
		sll $t1, $t1, 2 #Multiply the pocket number by 4
		sll $t8, $t8, 1 #Multiply the distance by 2, to get to the first char in the pocket
		addi $t1, $t1, -2 #Move to the last pocket (the one right next to the bottom mancala)
		sub $t1, $t1, $t8 #Move to the pocket specified by distance
		add $a0, $a0, $t1 #Move to the pocket using the state pointer
		addi $v0, $a3, 0 #Put the value of the size into v0, to be returned 
		jal storeChar
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
storeChar: #storeChar should take the int value and convert each byte to ascii
	li $t1, 10
	blt $a3, $t1, storeChar2 #If the size is a single digit, jump to a separate label that takes care of single digit numbers
	div $a3, $t1		#Divide the size by 10
	mflo $t2 #Put the quotient--ie, the greater digit--into t2
	mfhi $t3 #Put the remainder--ie, the smaller digit--into t2
	addi $t2, $t2, 48 #Convert the char to a ascii value
	addi $t3, $t3, 48 #Convert the char to a ascii value
	sb $t2, 0($a0) #Store the greater digit as the first char in the pocket
	sb $t3, 1($a0) #Store the smaller digit as the second char in the pocket
	jr $ra
	storeChar2: #storeChar2 stores a '0' in the first char of the pocket, then the size value converted to ascii in the second
		addi $t2, $0, 48 
		addi $t3, $a3, 48
		sb $t2, 0($a0) #Store the greater digit as the first char in the pocket
		sb $t3, 1($a0) #Store the smaller digit as the second char in the pocket
		jr $ra

twosCompExtractor: #twosCompExtractor should check for the msb, then convert the inputted distance as needed
	srl $t0, $a2, 7 #Get the msb of the inputted distance: if it is 1 (twos comp val), get the magnitude of the distance to use.
	bgt $t0, $0, deLabel #Jump to a label that will extract the magnitude of the distance arg, and then compare it against the pocket count accordingly
	move $v0, $a2
	jr $ra
	deLabel: #Extract the value in a2 from twos complement, and return it in v0
		addi $a2, $a2, -1 #Subtract 1 from a2
		xori $a2, $a2, 0xFF #Flip each of the 8 bits in a2 with the use of xori with 0xFF, which will toggle the bits in the a2 byte
		move $v0, $a2
		jr $ra
collect_stones: #collect_stones should add the number of stones located in the specified players mancala
	ble $a2, $0, collectNeg2 #If the number of stones in <=0, then return v0=-2
	li $t0, 'B'
	beq $a1, $t0, bottomCollect #If the player byte is B, jump to a label that will increment the bottom players mancala accordingly
	li $t0, 'T'
	beq $a1, $t0, topCollect #If the player byte is T, jump to a label that will increment the top players mancala accordingly 
	li $v0, -1 #If he byte given to specify the player is invalid, return v0=-1
	jr $ra
	topCollect: #Get to the top players mancala in the state struct with the use of the pointer, and update it accordingly. Return num stones in v0
		addi $a0, $a0, 1 #Get to byte 1: the byte containing the top players mancala
		lbu $t3, 0($a0)
		add $t3, $t3, $a2 #Add the number of stones passed in to the current number
		sb $t3, 0($a0) #Store into byte 1 of the state struct
		li $t0, 10
		div $t3, $t0
		mflo $t1 #Put the quotient (the first char) into t1
		mfhi $t0 #Put the remainder into t0
		addi $a0, $a0, 5 #Move to byte 6-- bytes 6 and 7 represent the top mancala
		sb $t1, 0($a0) #Store the quotient into t2
		addi $a0, $a0, 1
		sb $t0, 0($a0) #Store the remainder (the second digit) into byte 7 
		add $v0, $0, $a2
	 jr $ra
	bottomCollect: #Increment the number of stones in the bottom players mancala accordingly. Return num stones in v0
		lbu $t3, 0($a0)
		add $t3, $t3, $a2 #Add the number of stones passed in to the current number
		sb $t3, 0($a0) #Store into byte 0 of the state struct
		li $t0, 10
		div $t3, $t0
		mflo $t1 #Put the quotient (the first char) into t1
		mfhi $t0 #Put the remainder into t0
		addi $a0, $a0, 2 
		lbu $t3, 0($a0) #Get the pocket number
		sll $t3, $t3,2 #Multiply pocket number by 4
		addi $a0, $a0, 6 #Move to byte 8 of the state struct, where the pockets start being stored
		add $a0, $t3, $a0 #Move to the start of the bottom mancala
		sb $t1, 0($a0) #Store the quotient (the first char) 
		sb $t0, 1($a0) #Store the remainder (the second char)
		add $v0, $a2, $0
	 jr $ra
	collectNeg2: #Should return v0=-2 as the number of stones is <=0
		addi $v0, $0, -2
		jr $ra
verify_move: #verify_move checks if the distance argument is equal to the number of stones in the origin pocket, and returns the appropriate value
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s2, 4($sp)
	addi $s2, $a0, 0
	jal getPocketNumber
	bgt $a1, $t3, verifyReturnNeg1 #If origin_pocket is invalid for the row size, then return v0=-1
	beqz $a2, verifyReturnNeg2 #If the distance is equal to 0, then return v0=-2
	li $t0, 99
	beq $a2, $t0, verifyReturnTwo #If the distance is equal to 99, then change the turn in the state struct to the other player and return v0=2
	addi $t1, $a2, 0 #Put the distance into t1, for use after returning from the get_pocket function
	addi $a2, $a1, 0 #Put the origin_pocket into a2 for use in the get_pocket function
	addi $t2, $a0, 5 #Get to the player byte
	lbu $a1, 0($t2) #Put the player byte into a1, for use in the get_pocket function
	jal get_pocket
	beqz $v0, verifyReturn0 #If the number of stones in the origin pocket is 0, then return v0=1
	bne $v0, $t1 verifyReturnNeg2 #If the distance is not equal to the number of stones in the origin pocket, then return v0=-2
	li $v0, 1 #If the move is legal, then return v0=1
	lw $ra, 0($sp)
	lw $s2, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	verifyReturn0:
		li $v0, 0
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
	verifyReturnNeg1:
		li $v0, -1
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra	
	verifyReturnNeg2:
		li $v0, -2
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
	verifyReturnTwo: #verifyReturnTwo should change the turn in the state struct, then return v0 as 2
		sub $a0, $a0, $a1 #Move back to the beginning of the state pointer
		jal changeTurn
		li $v0, 2
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
changeTurn: #The changeTurn function should access the player byte in the inputted state struct, and change it from B to T or from T to B as appropriate
	addi $a0, $a0, 5
	lbu $t0, 0($a0)
	li $t1, 'B'
	beq $t0, $t1, changeToTop #If the current player is B, change it to T
	j changeToBottom #IF the current player is a T, change it to a B
	changeToTop:
		li $t1, 'T'
		sb $t1, 0($a0)
		jr $ra
	changeToBottom:
		sb $t1, 0($a0)
		jr $ra
execute_move: #execute_move should execute one move, while checking where the last deposit of the move is and updating the state struct accordingly
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s2, 4($sp) #Save the state pointer in s2
	sw $s3, 8($sp) #Save the origin pocket in s3
	sw $s4, 12($sp)#Save the pointer to the top mancala in s4
	sw $s5, 16($sp)#Save te pointer to the bottom mancala in s5
	addi $s2, $a0, 0 #Save the state pointer 
	addi $s3, $a1, 0 #Save the origin pocket
	addi $s4, $s2, 6 #Save the pointer to the top mancala in s4
	jal getBottomManc #Go to a helper function that will get the starting address of the bottom mancala in the state struct
	addi $s5, $v0, 0 #Save the address to the bottom mancala in s5, for use in loops
	addi $t0, $s2, 5
	lbu $a1, 0($t0) #Load the player byte as a1
	addi $a2, $s3, 0 #Put the origin pocket into a2-- this will be the distance in get pocket
	jal get_pocket
	addi $t4, $v0, 0 #Move the number of stones in the origin pocket into t4, for use in the following loop
	# addi $a3, $0, 0 
	# jal storeChar #Store a 0 in the origin_pocket before incrementing each pocket by the initial amount of stones in origin_pocet (located in v0)
	li $t3, 0 #Set t3 to 0: this will be the counter for the number of stones put into the mancala
	# beq $t4, $s3, lastDepositMancala #If the distance (number of stones in origin pocket) is equal to origin pocket (the number of pockets away from the players manc), then jump to a label that will return v1=2 after executing the move
	bgt $t4, $s3, lastDepositOpp #If the distance>origin_pocket, jump to a label that will execut the move according to rules regarding the opponents mancala
	li $t0, 'B'
	beq $t0, $a1, bottomMove #If the player is B, jump to a label that will execute the move for a bottom player
	topMove: #(change the player byte to B before starting the loop)
		# addi $t9, $a0, 0 #Save the pointer to the origin pocket in t9
		# addi $a0, $s2, 0 #Move to the player byte 
		# jal changeTurn
		# addi $a0, $t9, 0 #Restore the origin_pointer that was saved in t9
		topMoveLoop:
			beqz $t4, returnCheck #Once the loop is done depositing in each of the pockets, jump to a label that will check if the last pocket was initially empty
			addi $a0, $a0, -2 #Move to the next pocket
			jal tbpParse
			addi $a3, $v0, 1 #Move the newly incremented pocket into a3
			addi $t9, $t3, 0 #"Save" the mancala counter before jumping to the storechar helper
			jal storeChar #Jump to the storeChar helper to store the newly incremented string into the specified pocket
			move $t3, $t9 #"Restore" the mancala counter after returning from storechar
			addi $t4, $t4, -1 #Decrement the number of stones left to deposit
			j topMoveLoop
	bottomMove: #(Change the player byte to T before starting the loop)
		# addi $t9, $a0, 0 #Save the pointer to the origin pocket in t9
		# addi $a0, $s2, 0 #Move to the player byte 
		# jal changeTurn
		# addi $a0, $t9, 0 #Restore the origin_pointer that was saved in t9
		bottomMoveLoop:		
			beqz $t4, returnCheck #Once the loop is done depositing in each of the pockets, jump to a label that will check if the last pocket was initially empty
			addi $a0, $a0, 2 #Move to the next pocket
			jal tbpParse
			addi $t9, $t3, 0 #"Save" the mancala counter before jumping to the storechar helper
			addi $a3, $v0, 1 #Move the newly incremented pocket into a3
			jal storeChar #Jump to the storeChar helper to store the newly incremented string into the specified pocket
			move $t3, $t9 #"Restore" the mancala counter after returning from storechar
			addi $t4, $t4, -1 #Decrement the number of stones left to deposit
			j bottomMoveLoop
	returnCheck: #returnCheck should check if the last pocket in the loop was initially empty (by parsing and subtracting the stones in the given pocket by 1)
		jal tbpParse
		addi $v0, $v0, -1 #Decrement the number of stones in the pocket by 1
		beqz $v0, return1 #If the last pocket was empty before the deposit, then jump to a label that wil return v1=1 and v0=0
		li $v1, 0
		move $v0, $t3
		addi $a0, $s2, 0
		jal changeTurn #Change the turn before returning
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		lw $s3, 8($sp)
		lw $s4, 12($sp)
		lw $s5, 16($sp)
		addi $sp, $sp, 20
		jr $ra
return1:
	li $v1, 1
	move $v0, $t3 #Move the mancala stone counter to v0
	addi $a0, $s2, 0
	jal changeTurn #Change the turn before returning
	lw $ra, 0($sp)
	lw $s2, 4($sp)
	lw $s3, 8($sp)
	lw $s4, 12($sp)
	lw $s5, 16($sp)
	addi $sp, $sp, 20
	jr $ra
# lastDepositMancala: #lastDepositMancala should do the same thing as topMove and bottomMove, but with a separate label that handles depositing into the mancala
# 	li $t0, 'B'
# 	li $t3, 1 
# 	beq $a1, $t0, bottomDepositMancala #If the player is B, jump to a label that handles the move (with last being mancala) for bottom
# 	topDepositMancala: 
# 		tdmLoop:
# 			beq $a0, $s4, depositMancala #If the loop reaches the top mancala, jump to a label that will handle depositing into the top mancala and returns
# 			beqz 
# 			addi $a0, $a0, -2 #Move to the next pocket
# 			jal tbpParse
# 			addi $t9, $t3, 0
# 			addi $a3, $v0, 1 #Move the newly incremented pocket into a3
# 			jal storeChar #Jump to the storeChar helper to store the newly incremented string into the specified pocket
# 			move $t3, $t9
# 			addi $t4, $t4, -1 #Decrement the number of stones left to deposit
# 			j tdmLoop
# 	depositMancala:
# 		addi $a0, $s2, 0 #Put the state pointer into a0
# 		addi $a2, $0, 1 #Make the number of stones to add equal to 1
# 		addi $t9, $t3, 0
# 		jal collect_stones #Increment the specified players mancala by 1
# 		move $t3, $t9
# 		addi $a0, $s2, 5 #Move to the player byte
# 		jal changeTurn
# 		move $v0, $t3 #Put the number of stones added to specific players mancala into v0
# 		li $v1, 2
# 		lw $ra, 0($sp)
# 		lw $s2, 4($sp)
# 		lw $s3, 8($sp)
# 		lw $s4, 12($sp)
# 		lw $s5, 16($sp)
# 		addi $sp, $sp, 20
# 		jr $ra		
# 	bottomDepositMancala: 
# 		bdmLoop:
# 			beq $a0, $s5, depositMancala #Once the loop reaches the bottom pocket, jump to a different label that iwll handle depositing into the bottom mancala and returning
# 			beqz 
# 			addi $a0, $a0, 2 #Move to the next pocket
# 			jal tbpParse
# 			addi $t9, $t3, 0
# 			addi $a3, $v0, 1 #Move the newly incremented pocket into a3
# 			jal storeChar #Jump to the storeChar helper to store the newly incremented string into the specified pocket
# 			move $t3, $t9
# 			addi $t4, $t4, -1 #Decrement the number of stones left to deposit
# 			j bdmLoop
lastDepositOpp: #lastDepositOpp should act like lastDepositMancala, but once the mancala is reached, it should increment the opposite players pockets--if their mancala is reached, ignore and transfer control back to current player
	li $t0, 'B'
	li $t3, 0 #Reset t3--this will hold the number of stones added to this players mancala
	beq $a1, $t0, ldoBottom #If the player is B, jump to a label that handles the move (with last being mancala) for bottom
	ldoTop:
		li $t0, 'T' #Change t0 to the player that this loop increments for: to be used in a check in ldoChangePlayer
		addi $a0, $a0, -2 #Move to the first pocket 
		ldotLoop:
			beq $a0, $s4, ldoChangePlayer #Once this player's mancala is reached, jump to a label that will increment this players mancala before looping through the opposing players pockets
			beqz $t4, returnCheck #If there are no stones left to increment, jump to a label that will return t3 in v0 and v1=0
			jal tbpParse
			addi $a3, $v0, 1 #Move the newly incremented pocket into a3
			addi $t9, $t3, 0
			jal storeChar #Jump to the storeChar helper to store the newly incremented string into the specified pocket
			move $t3, $t9
			addi $t4, $t4, -1 #Decrement the number of stones left to deposit
			addi $a0, $a0, -2 #Move ot the next pocket to be incremented
			j ldotLoop
	ldoBottom:
	 li $t0, 'B' #Change t0 to the player that this loop increments for: to be used in a check in ldoChangePlayer
		addi $a0, $a0, 2 #Move to the first pocket to be checked
		ldobLoop: #Loop should continue until either distance (the number of stones in origin_pocket) is 0 or the address of the next pocket is equal to a mancala
			beq $a0, $s5, ldoChangePlayer #Once this player's mancala is reached, jump to a label that will increment this players mancala before looping through the opposing players pockets
			beqz $t4, returnCheck #If there are no stones left to increment, jump to a label that will return t3 in v0 and v1=0
			jal tbpParse
			addi $a3, $v0, 1 #Move the newly incremented pocket into a3
			addi $t9, $t3, 0 #Save the value of t3 in t9
			jal storeChar #Jump to the storeChar helper to store the newly incremented string into the specified pocket
			move $t3, $t9 #"Restore" the value of t3
			addi $t4, $t4, -1 #Decrement the number of stones left to deposit
			addi $a0, $a0, 2 #Move to the next pocket
			j ldobLoop
	ldoChangePlayer:
		beq $a1, $t0, ldoMancala #If the mancala reached is the mancala of this specific player, then increment using collect stones and transfer to the other players loop
		blt $a1, $t0, ldoBottomTransfer #If the player byte is less than that stored in t0, jump to a label that will place the origin pocket at the pocket right before the beginning of bottom pockets
		j ldoTopTransfer
		ldoMancala: #ldoMancala should increment the number of stones in the specified players mancala before jumping to the other players row to continue executing the move
			beqz $t4, returnCheck #If the loop reached the mancala and there are no stones left to deposit, jump to the part6return0 label
			addi $a0, $s2, 0 #Put the state pointer into a0
			addi $a2, $0, 1 #Make the number of stones to add equal to 1
			addi $t9, $t3, 0 #Save the value in t3  in t9 before jumping to the collect stones loop
			jal collect_stones #Increment the specified players mancala by 1
			move $t3, $t9 #Put the actual value of t3 back into t3
			addi $t3, $t3, 1 #Increment the mancala stone counter
			addi $t4, $t4, -1 #Decrement the number of stones left to deposit
			beqz $t4, part6return2 #If the last deposit was in the mancala, jump to the part6return2 label
			li $t0, 'B'
			beq $a1, $t0, ldoTopTransfer #If the current player byte is B, then transfer to T
			j ldoBottomTransfer #If the current player byte is T, then transfer to B
			ldoTopTransfer: #ldoTopTransfer should update both the origin_pocket and the address of the origin_pocket, for use in the ldot loop
				addi $a0, $s2, 2
				lbu $t0, 0($a0)
				add $a0, $a0, $t0 #Get to the last column in the first row of top
				addi $a0, $a0, 6
				j ldoTop
			ldoBottomTransfer:
				addi $a0, $s2, 2
				lbu $t0, 0($a0)
				addi $a0, $t0, 8 #Get to the first pocket in the second row
				j ldoBottom
part6return2: #part6return0 should return t4 in v0 and 2 in v1
	move $v0, $t3
	li $v1, 2
	addi $a0, $s2, 0
	jal changeTurn #Change the turn before returning
	lw $ra, 0($sp)
	lw $s2, 4($sp)
	lw $s3, 8($sp)
	lw $s4, 12($sp)
	lw $s5, 16($sp)
	addi $sp, $sp, 20
	jr $ra
getBottomManc: #getBottomManc is a helper that gets the address/index of the bottom mancala in the gameboard
		addi $t0, $a0, 2 
		lbu $t3, 0($t0)
		sll $t3, $t3,2 #Multiply pocket number by 4
		addi $t0, $t0, 6 #Move to byte 8 of the state struct, where the pockets start being stored
		add $t0, $t0, $t3 #Move to the start of the bottom mancala
		move $v0, $t0
		jr $ra
# changeTurn:
# 	li $t0, 'B'
# 	lb $t4, 0($a0)
# 	beq $t0, $t4, changeToTop
# 	sb $t0, 0($a0)
# 	jr $ra
# 	changeToTop:
# 		li $t0, 'T'
# 		sb $t0, 0($a0)
# 		jr $ra


steal: #steal should check if v1 is 1, and increment the specified players mancala by the amount in the pocket across from the last pocket incremented
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $s2, 4($sp)
	addi $s2, $a0, 0 #Save the state pointer in s2
	addi $t0, $a0, 5
	lbu $t4, 0($t0)
	li $t3, 'B'
	beq $t4, $t3, stealForTop #If the new turn is B, then perform the steal execute for T--ie, put the number of stones in the pocket across in the top mancala
	stealForBottom: #Get to the pocket across from the dest_pocket,  
		move $a2, $a1 #Move the origin pocket to a2, for use in the get_pocket function
		li $a1, 'B'
		jal get_pocket
		jal getPocketNumber
		sll $t3, $t3, 1 #Multiply the number of pockets by 2
		sub $a0, $a0, $t3 #Get to the pocket for which the steal should be executed on
		jal tbpParse
		addi $a3, $0, 0 #Put 0 into a0, for use in the storeChar function-- setting the stolen pocket to 9
		addi $v0, $v0, 1 #Add 1 to the number of stones in the pocket across from the dest pocket--dest pocket has 2 stone in it
		jal storeChar
		add $a0, $a0, $t3 #Move back to the dest pocket
		jal storeChar #Place a 0 in the dest pocket
		move $t9, $v0 #Put the number of stones in the pocket that it to be stolen into t9
		lbu $t4, 0($s2) #Load in the current amount of stones in the bottom mancala
		add $t4, $t4, $t9 #Increment the number of stones in the bottom mancala
		sb $t4, 0($s2)
		addi $a0, $s2, 0 #Get back to the base address, for use in the getBottomManc helper function
		jal getBottomManc
		move $a0, $v0 #Put the address of the bottom manc back into a0
		move $a3, $t4 #Move the new amount of stones in  a3, for use in the storeChar helper
		jal storeChar
		move $v0, $t9 #Move the number of stones to be added to the bottom mancala into v0
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
	stealForTop: #Get to the top mancala, then get to the origin pocket, and finally to the pocket whose stones should be used to perform the steal
		move $a2, $a1 #Move the origin pocket to a2, for use in get_pocket
		li $a1, 'T'
		jal get_pocket
		jal getPocketNumber
		sll $t3, $t3, 1 #Multiply the number of pockets by 2
		add $a0, $a0, $t3 #Get to the pocket to be stolen
		jal tbpParse
		addi $v0, $v0, 1 #Increment the number of stones to be stolen by 1, since dest_pocket was initially empty before execute_move
		addi $a3, $0, 0 
		jal storeChar
		sub $a0, $a0, $t3 #Move back to the dest pocket
		jal storeChar
		move $t9, $v0 #Put the number of stones in the pocket that it to be stolen into t9
		addi $s2, $s2, 1
		lbu $t4, 0($s2)
		add $t4, $t4, $t9
		sb $t4, 0($s2)
		addi $a0, $s2, 6 #Move to the top mancala
		move $a3, $t4 #Move the new amount of stones in the top mancala to a3, for use in the store char helper function
		jal storeChar
		move $v0, $t9
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		addi $sp, $sp, 8
		jr $ra
check_row: #check_row should check if either rows are empty. If one row is empty, then the number of stones in that players row should go in their mancala)
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s2, 4($sp)
	sw $s3, 8($sp) 
	sw $s4, 12($sp) #s4 should hold the number of stones in the top row
	sw $s5, 16($sp) #s5 should hold the number of stones in the bottom row
	addi $s4, $0, 0 #Reset the top row counter
	addi $s5, $0, 0 #Reset the bottom row counter
	addi $s2, $a0, 0 #Hold the pointer to the state struct in s2
	jal getPocketNumber
	move $t9, $t3, #Put the pocket number in t9 for now
	sll $t9, $t9, 1 
 jal getBottomManc
	addi $s3, $v0, 0 #Put the address to the bottom mancala into s3
	addi $a0, $a0, 8 #Get to the first pocket in the top row)
	addi $t4, $a0, $t9 #t4 will be the end of the first row
	j checkTop
	checkTop: #checkTop should iterate through the top row until the beginning of the bottom row is reached
		bgt $a0, $t4, checkBottom #Once this loop is done, jump to a label that does the exact same thing as this one but for the bottom row
		jal tbpParse #Send the pocket to be parsed
		addi $s4, $s4, $v0 #Increment the top row counter
		addi $a0, $a0, 2 #Move to the next pocket to be checked
		j checkTop
	checkBottom: #checkBottom should iterate through ottom row until the bottom mancala is reached
		bgt $a0, $s3, checkTopBottom #Once this loop is done, jump to a label that checks which row was empty, and increments the non-empty one accordingly befoe returning the desired values 
		jal tbpParse #Send the pocket to be parsed
		addi $s5, $s5, $v0 #Increment the top row counter
		addi $a0, $a0, 2 #Move to the next pocket to be checked
		j checkBottom
	checkTopBottom: #checkTopBottom should check which of the two rows are empty using the row counters s4 and s5, and increment the non empty one accordinglt before returning the desired values
		beqz $s4, incrementBottom #If the top row is empty, increment the bottom mancala
		beqz $s5, incrementTop #If the bottom row is empty, increment the top mancala
		j part8return0 #If neither of the rows are empty, then return v0=0
	incrementBottom: #incrementBottom should increment the bottom mancala by the number specified in the bottom row counter 
		beqz $s5, part8return0 #Check if the bottom row is also empty
		addi $a0, $s2, 0 #Move to the byte containing the number of stones in the bottom mancala
		lbu $a3, 0($a0)
		addi $a3, $a3, $s5 #Increment the number of stones 
		sb $a3, 0($a0)
		addi $a0, $s3, 0 #Put the address of the bottom mancala into a0
		jal storeChar
		j part8return1 #Jump to a label that will return v0=1 (Signaling that the game is over if the program managed to reach this point)
	incrementTop: #incrementTop should do the same thing as incrementBottom but for the top row instead
		addi $a0, $s2, 1 #Move to the byte containing the number of stones in the top mancala
		lbu $a3, 0($a0)
		addi $a3, $a3, $s4 #Increment the number of stones
		sb $a3, 0($a0)
		addi $a0, $s2, 6 #Move to the address of the top mancala
		jal storeChar
		j part8return1 #Jump to a label that will return v0=1 (Signaling that the game is over if the program managed to reach this point)
	part8return0:
		lbu $t3, 0($s2) #Get the number of stones in the bottom mancala
		addi $s2, $s2, 1
		lbu $t4, 0($s2) #Get the number of stones in the top mancala
		li $v0, 0
		bgt $t3, $t4, part8returnv11 #If the bottom mancala is greater, jump to a label that will return v1=1 (since bottom is player 1)
		bgt $t4. $t3, part8return2 #If the top mancala is greater, jump to a label that will return v1=2 (since top is player 2)
		li $v1, 0 #If the two players are tied, return v1=1
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		lw $s3, 8($sp) 
		lw $s4, 12($sp) 
		lw $s5, 16($sp)
		addi $sp, $sp, 20
		jr $ra
	part8return1: #This should do the same thing as part8return0, but with a change in the value that v0 returns
		lbu $t3, 0($s2) #Get the number of stones in the bottom mancala
		addi $s2, $s2, 1
		lbu $t4, 0($s2) #Get the number of stones in the top mancala
		li $v0, 1
		bgt $t3, $t4, part8returnv11 #If the bottom mancala is greater, jump to a label that will return v1=1 (since bottom is player 1)
		bgt $t4. $t3, part8return2 #If the top mancala is greater, jump to a label that will return v1=2 (since top is player 2)
		li $v1, 0 #If the two players are tied, return v1=1
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		lw $s3, 8($sp) 
		lw $s4, 12($sp) 
		lw $s5, 16($sp)
		addi $sp, $sp, 20
		jr $ra
	part8returnv11: #Return v1=1 along with whatever value was "returned" into v0
		li $v1, 1
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		lw $s3, 8($sp) 
		lw $s4, 12($sp) 
		lw $s5, 16($sp)
		addi $sp, $sp, 20
		jr $ra
	part8return2: #Return v1=2 along with whatever value was "returned" into v0
		li $v1, 2
		lw $ra, 0($sp)
		lw $s2, 4($sp)
		lw $s3, 8($sp) 
		lw $s4, 12($sp) 
		lw $s5, 16($sp)
		addi $sp, $sp, 20
		jr $ra
	jr $ra
load_moves:
	jr $ra
play_game:
	jr  $ra
print_board:
	jr $ra
write_board:
	jr $ra
	
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
