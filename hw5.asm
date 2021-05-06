############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
.text:

create_term: #create_term should allocate 12 bytes on the system heap, and store the inputted coeff, exp, and next term (0) into that storage space
	addi $t0, $a0, 0 #Put the coefficient into t0
	beqz $t0, part1ReturnNeg #If coeff=0, return v0=-1
	blt $a1, $0, part1ReturnNeg #If exp<0, return v0=-1
	li $a0, 12
	li $v0, 9
	syscall
	sw $t0, 0($v0) #Store the coefficient in the first 4 bytes of the heap
	sw $a1, 4($v0)  #Store the exponent in the second 4 bytes of the heap
	sw $0, 8($v0) #Store the next term (0 currently) in the third 4 bytes 
	jr $ra
	part1ReturnNeg:
		addi $v0, $0, -1
		jr $ra
init_polynomial: #init should send p[0] and p[1] as args to part 1, and store the mem buffer in the provided Polynomial pointer
	addi $sp, $sp, 8
	sw $ra, 0($sp)
	sw $s0, 4($sp) #Use s0 to hold the address of the Polynomial pointer
	addi $s0, $a0, 0 
	lw $a0, 0($a1) #Put p[0] into a0
	lw $a1, 4($a1) #Put p[1] into a1
	jal create_term
	blt $v0, $0, part2ReturnNeg #If one of or both the coeff and exp are invalid, return v0=-1
	sw $v0, 8($s0) #Store this term as the next link to the head node p
	li $v0, 1
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	addi $sp, $sp, 8
	jr $ra
	part2ReturnNeg:
		addi $v0, $0, -1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		addi $sp, $sp, 8
		jr $ra
add_N_terms_to_polynomial: #addNterms should create terms based off pairs given in the terms array, check for duplicates, and insert the term properly sorted
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $s0, 4($sp) #s0 stores the base address of the Polynomial (which is in a0)
	sw $s1, 8($sp) #s1 saves the base address of the duplicates array
	sw $s2, 12($sp) #s2 saves the base address of the spot in a heap allocated to a newly created term
	sw $s3, 16($sp) #s3 saves base address of a1 (base add of terms[])
	addi $t2, $0, 0 #Loop counter-- ie, the thing that gets returned in v0 when the following loop is finished
	ble $a2, $0, part3Return #If N<=0, return v0=0
	move $s0, $a0
	move $s3, $a1
	addi $a0, $a1, 0 #Put the base address of terms[] into a0, to be used in a helper 
	jal getTermSize #Go to a helper that will get the size of terms, to be used to create a spot in the heap for duplicates[]
	sll $a0, $v0, 2 #Get 4*terms_size, and put it in a0
	li $v0, 9
	syscall
	move $s1, $v0
	addi $t3, $0, -1
	sw $t3, 0($s1) #Store a negative number in the first part of duplicates array, as a way to indicate the end of the array
	part3Loop: #This loop should do 4 things: 1)Create the term in the array 2)Check for duplicates w/helper 3)Check for sorted position w/helper 4)Insert
		beq $t2, $a2, part3Return #If N is reached, return v0=N
		lw $t3, 0($s3) #Get the coefficient in the current pair in terms[]
		lw $t4, 4($s3) #Get the exponent in the current pair in terms[]
		bgt $t3, $0, part3Insert
		bge $t4, $0, part3Insert
		j part3Return #If the end of terms was reached (pair 0,-1), then jump to a label that will return v0=t2
		part3Insert:
			move $a0, $t3
			move $a1, $t4
			jal create_term
			blt $v0, $0, part3Skip #If the given term is not valid (but is not 0,-1), skip and go to next term
			lw $a0, 4($v0) #Load the exponent portion of the new term in a0
			addi $a1, $s1, 0 #Load the base address of duplicates[] into a1
			move $s2, $v0
			jal duplicateCheck #Jump to a helper that will check if the exp of the new term is a duplicate
			beq $v0, $0, part3Skip #If the new term is a duplicate, then skip to the next pair in terms[]
			addi $t2, $t2, 1 #Add 1 to the loop counter
			lw $a0, 8($s0) #Put the base address of the first non-head node into a0
			addi $a1, $s2, 0 #Put the base address of the newly created term into a1
			addi $t6, $s0, 0 #Save the head node in t6-- if this Polynomial is empty, then this will allow for this new term to be added as a tail
			jal sorter #Jump to a helper that will insert the new term into the Polynomial as according to a greatest-least sorting
		part3Skip:
			addi $s3, $s3, 8 #Go to the next pair in terms[]
			j part3Loop
	part3Return: #return v0=t2 (ie the loop counter) 
		move $v0, $t2
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		addi $sp, $sp, 20
		jr $ra
duplicateCheck: #duplicateCheck should check if the inputted exp matches any of the number in the current duplicates array
	lw $t3, 0($a1) #Get the initial number in duplicates[]
	dpLoop:
		blt $t3, $0, dpReturn1 #If the end of duplicates has been reached and no duplicate was found, add the inputted exp to duplicates along with a new -1, and return v0=1
		beq $a0, $t3, dpReturn0 #If a duplicate is found, return v0=0
		addi $a1, $a1, 4 #Move to the next element in duplicates[]
		lw $t3, 0($a1) 
		j dpLoop
	dpReturn0: #return 0 should return v0=0 without altering the size of duplicates[]
		addi $v0, $0, 0 
		jr $ra 
	dpReturn1: #return1 should return v0=1 after adding the inputted exp to the end of the current duplicates[] along with -1 in the spot after to indicate the new size of duplicates[]
		sw $a0, 0($a1)
		addi $a0, $0, -1
		addi $a1, $a1, 4
		sw $a0, 0($a1)
		addi $v0, $0, 1
		jr $ra
getTermSize: #getTermSize should iterate through the terms array until 0,-1 is reached, and return the size of terms[]
	addi $v0, $0, 0 #Initialize loop counter
	termLoop:
		lw $t3, 0($a1)
		lw $t4, 4($a1)
		bgt $t3, $0, nextTerm #If coeff>0, then update counter and go to the next term
		bge $t4, $0, nextTerm #If exp>=0, then update counter and go to the next term
		addi $v0, $v0, 2 #if 0,-1 has been reached, return counter (after adding 2 for the 0,-1 spot)
		jr $ra
		nextTerm: 
			addi $v0, $v0, 2
			addi $a1, $a1, 8 #Move to the next pair
			j termLoop
sorter: #sorter should compare the coeff and exp of existing terms in the Polynomial to 1)Find the position to place the new term into and 2)Actually insert that term into the Polynomial
	lw $t4, 4($a1) #Get exp of the new term
	beqz $a0, sorterInsert2 #If it is found that the currrent Polynomial is empty, jump to a label that will make this new term a tail
	sorterLoop:
		lw $t3, 4($a0) #get exp of term in Polynomial
		blt $t3, $t4, sorterInsert1 #If a spot is found where exp_newterm>exp_existingterm, insert this new term in that position in polynomial
		beq $t3, $t4, sorterReturn #If it is found that a this new term has a exp already present in the Polynomial, subtract one from the loop counter and return
		addi $t6, $a0, 0 #Save the address of this existing term before going to the next term
		#lw $a0, 8($t5)
		lw $a0, 8($a0) #get the next term
		beqz $a0, sorterInsert2 #If the end of the polynomial is reached, jump to a label that will insert the new term at the end of the Polynomial
		#beqz $a0, sorterInsert2
		j sorterLoop
	sorterInsert1: #sorterInsert1 should handle the case where the new term has to be inserted somewhere in between the ends of the current Polynomial linked list
		lw $t4, 8($t6) #Load the link part of the previous term into t4
		sw $t4, 8($a1) #Set the link of the new term to the term that was previously in its spot
		sw $a1, 8($t6) #Set the link of the previous term to the newly added term
		jr $ra
	sorterInsert2:
		sw $a1, 8($t6) #Set the link of the now old tail to the address of the new term
		jr $ra
	sorterReturn:
		addi $t2, $t2, -1 #Subtract one from the loop counter
		jr $ra
update_N_terms_in_polynomial: #update is a lot like addNterms, but a little simpler and with reversed ops
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) #s0 saves base address of Polynomial p
	sw $s1, 8($sp) #s1 saves base address of duplicates[]
	sw $s2, 12($sp) #s2 saves base address of terms[]
	addi $t2, $0, 0 #Loop counter
	ble $a2, $0, part4Return #If N<=0, return v0=0
	move $s0, $a0
	move $s2, $a1
	addi $a0, $a1, 0 #Put the base address of terms[] into a0, to be used in a helper 
	jal getTermSize #Go to a helper that will get the size of terms, to be used to create a spot in the heap for duplicates[]
	sll $a0, $v0, 2 #Get 4*terms_size, and put it in a0
	li $v0, 9
	syscall
	move $s1, $v0
	addi $t3, $0, -1
	sw $t3, 0($s1) #Store a negative number in the first part of duplicates array, as a way to indicate the end of the array
	part4Loop:
		beq $t2, $a2, part4Return #If N is reached, return v0=N
		lw $a1, 0($s2) #Get the coefficient in the current pair in terms[]
		lw $a2, 4($s2) #Get the exponent in the current pair in terms[]
		bgt $a1, $0, part4Insert
		bge $a2, $0, part4Insert
		j part4Return #If the end of terms was reached (pair 0,-1), then jump to a label that will return v0=t2
		part4Insert:
			beqz $a1, part4Skip #If the coefficient = 0 (invalid term), then skip and move to the next term
			lw $a0, 8($s0) #Put the base address of the first non-head node into a0
			jal matcher #Jump to a helper function that will check if the exp in this pair matches any exp in polynomial, and updates coefficients accordingly
			blt $v0, $0, part4Skip #If the given term is not valid (but is not 0,-1)/no such term with the exp was found, immediately go to next term
			lw $a0, 4($s2) #Load the exponent portion of the current term pair in a0
			addi $a1, $s1, 0 #Load the base addresss of duplicates[] into a1
			jal duplicateCheck #Jump to a helper that will check if the exp of the new term is a duplicate (and if not, insert it into dupkicates[])
			beq $v0, $0, part4Skip #If the same term was updated more than once, then skip to the next pair in terms[]
			addi $t2, $t2, 1 #Add 1 to the loop counter
		part4Skip:
			addi $s2, $s2, 8 #Go to the next pair in terms[]
			j part4Loop
	part4Return:
		move $v0, $t2
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
matcher: #matcher is similar to sorter, but only searches for a term with the same exp as arg 2, and updates the coeff of said term with arg 1
	matcherLoop:
		beqz $a0, matcherReturn0 #if no term w/the inputted exp was founc once the end of Polynomial is reached, return v0=0 (for the case where Polynomial is empty)
		lw $t3, 4($a0) #get exp of term in Polynomial
		beq $a2, $t3, matcherUpdate #If the inputted exp is found as a term in polynomial, update the coeff of said term before returning v0=1
		lw $a0, 8($a0) #get the next term
		beqz $a0, matcherReturn0 #if no term with the inputted exp was found once the end of the Polynomial is reached, return v0=0
		j matcherLoop
	matcherUpdate: #matcherUpdate should update the coeff of the current term in polynomial with the inputted coeff and returns v0=1
		sw $a1, 0($a0)
		li $v0, 1
		jr $ra 
	matcherReturn0:
		addi $v0, $0, 0 
		jr $ra
get_Nth_term: #getNthterm should use a loop to find the Nth highest term, and return the coeff and exp of that term
	ble $a1, $0, part5ReturnN0 #If N is not >0, return v0=-1 and v1=0
	addi $t2, $0, 1 #Loop counter
	lw $a0, 8($a0) #Get the first non-head node in the Polynomial
	part5Loop:
		beqz $a0, part5ReturnN0 #If the end of this polynomial is reached and the Nth highest has not been reached/found, return v0=-1 and v1=0
		beq $t2, $a1, part5Return #If the Nth highest term is reached, jump to a label that will return v0=exp and v1=coeff
		addi $t6, $a0, 0
		lw $a0, 8($a0)
		addi $t2, $t2, 1 #Advance loop counter
		j part5Loop
	part5Return: #part5Return should return v0=exp and v1=coeff of this current term
		lw $v0, 4($a0)
		lw $v1, 0($a0)
		jr $ra 
	part5ReturnN0: #part5ReturnN0 should return v0=-1 and v1=0
		addi $v0, $0, -1
		addi $v1, $0, 0
		jr $ra
remove_Nth_term: #removeNth uses getNth to find the term to remove, and removes it by setting the link of that term as the link of the N-1 term
	addi $sp, $sp, -8
	sw $ra, 0 ($sp)
	sw $s0, 4($sp) #s0 saves the Base address of Polynomial p
	addi $s0, $a0, 0 
	jal get_Nth_term
	beq $v1, $0, part6ReturnN0 #Same as part5ReturnN0 but w/register conv
	addi $t0, $0, 1 
	beq $a1, $t0, setHead #If the Nth term is the first term in the Polynomial, remove 1st term by rewriting the link that head stores
	lw $t3, 8($a0) #Get the link of the Nth term
	sw $t3, 8($t6) #Store the link of the Nth term into the N-1 term, effectively removing the link to the Nth term
	part6ReturnN0:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		addi $sp, $sp, 8
		jr $ra
	setHead:
		lw $t3, 8($a0)
		sw $t3, 8($s0) #Store the link of the Nth term into the head node, effectively removing the link to the Nth term
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		addi $sp, $sp, 8
		jr $ra
add_poly:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) #Save the base address of the created terms[] array, to be sent to part 3
	sw $s1, 8($sp) #Saves the base address of Polynomial p
	sw $s2, 12($sp) #Saves the base address of Polynomal q 
	addi $s1, $a0, 0
	addi $s2, $a1, 0 
	lw $a0, 8($a0) #Get the link of the head node of Polynomial p 
	lw $a1, 8($a1) #get the link of the head node of Polynomial q
	jal getLongerPoly #Go to a helper that will find the longer of the two polynomials and return 
	addi $t0, $0, 0 #Number of terms counter
	sll $a0, $v0, 2 #Get 4*poly_size
	addi $a0, $a0, 8 #Add space for the pair (0,-1)
	li $v0, 9
	syscall
	move $s0, $v0 #Get the base address of terms[]
	lw $a0, 8($s1)
	lw $a1, 8($s2)
	addi $t5, $s0, 0 #Put the base address of terms[[ into t5
	beqz $a0, checkq #if p is empty, jump to a label that will check if q is empty-- if it is, return v0=0. If not, put only the terms in q into terms[] to send to part 3
	beqz $a1, addp #if q is empty (meaning p isn't), jump to a label thay will put only the terms of p into terms[] to send to part 3
	jal comparator #If neither p or q is empty, jump to a helper that will compare each term of p and q and add p and "add" p and q accordingly
	part7Add: 
		addi $a1, $s0, 0 #Move back to the start of the heap terms array
		sw $0, 8($a2) #Store a 0 in the head node of Polynomial r
		move $a0, $a2 #Put the Polynomial r into a0
		move $a2, $t0 #Move the number of terms added to terms[] to a2
		jal add_N_terms_to_polynomial
		beqz $v0, part7Return0 #If no terms were added to r, return v0=0
		li $v0, 1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
	part7Return0:
		li $v0, 0 
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
	checkq: #Checks if q is empty, and adds the rest of the terms in q if not
		beqz $a1, part7Return0 #If q ia also empty, return v0=0
		qLoop:
			beqz $a1, endTerms #if the end of q is reached, jump to a label that will put (0,-1) as the last pair in s0, and then jump to part7Add
			lw $t3, 0($a1)
			lw $t4, 4($a1)
			sw $t3, 0($t5)
			sw $t4, 4($t5)
			addi $t0, $t0, 1
			lw $a1, 8($a1) #move to the next term in q
			addi $t5, $t5, 8 #Move to the next spot in terms[]
			j qLoop
	addp: #Same as checkq2 but for p
		pLoop:
			beqz $a0, endTerms  #if the end of q is reached, jump to add
			lw $t3, 0($a0)
			lw $t4, 4($a0)
			sw $t3, 0($t5)
			sw $t4, 4($t5)
			addi $t0, $t0, 1
			lw $a0, 8($a0) #move to the next term in p
			addi $t5, $t5, 8 #Move to the next spot in terms[]
			j pLoop
	endTerms:
		addi $t5, $t5, 8
		sw $0, 0($t5)
		addi $t3, $0, -1
		sw $t3, 4($t5)
		j part7Add
getLongerPoly: #getLongerPoly should iterate through both polynomials, and return the size of the longer polynomial
	addi $t3, $0, 0 #p counter
	addi $t4, $0, 0 #q counter
	length_p:
		beqz $a0, length_q
		addi $t3, $t3, 2
		lw $a0, 8($a0)
		j length_p
	length_q:
		beqz $a1, returnSize  
		addi $t4, $t4, 2
		lw $a1, 8($a1)
		j length_q
	returnSize:
		bgt $t3, $t4, returnSizeP #If p_length>q_length, return p_length
		bgt $t4, $t3, returnSizeQ #If q_length>p_length, return q_length
		returnSizeP:
			move $v0, $t3
			jr $ra
		returnSizeQ:
			move $v0, $t4
			jr $ra
comparator: #comparator should compare the two inputted Polynomials, and "add" them together accordingly
	addi $sp, $sp, -4
	sw $s0, 0 ($sp)
	comparatorLoop:
		lw $t3, 4($a0) #get the exp of Polynomial p
		lw $t4, 4($a1) #get the exp of Polynomial q
		beq $t3, $t4, addCoeffs #If the exps of the current terms in p and q are equal, add the two coeffs and add it along with exp to terms[]
		bgt $t3, $t4, addPCoeff #if p_exp>q_exp, add the p term to terms[]
		j addqCoeff #If q_exp>p_exp, add the q term to terms[]
	addCoeffs:
		addi $t0, $t0, 1
		lw $t4, 0($a0) #Get the coeff of Polynomial p 
		lw $t5, 0($a1) #Get the coeff of Polynomial q
		add $t4, $t4, $t5 
		sw $t4, 0($s0) #Store this new coeff into s0
		sw $t3, 4($s0) #Store the exp into s0
		lw $a0, 8($a0)
		lw $a1, 8($a1)
		addi $s0, $s0, 8
		beqz $a0, checkq2 #If the end of p is reached, check if q is also empty before adding the remaining terms in q to terms[]
		beqz $a1, addp2 #If the end of q is reached (meaning p is not), add the rest of p to terms[]
		j comparatorLoop #If neither p or q are empty yet, go back to the loop 
	addPCoeff: #add the current term in Polynomial p to terms[], before checking if eithet the end of p or q is reached and j back to the comparator if not so
		addi $t0, $t0, 1
		lw $t4, 0($a0) #get the coeff of Polynomial p 
		sw $t4, 0($s0)
		sw $t3, 4($s0)
		lw $a0, 8($a1) #Only go to the next term in Polynomial p; stay on the current term in Polynomial q
		addi $s0, $s0, 8
		beqz $a0, addp2 #If the end of q is reached (meaning p is not), add the rest of p to terms[]
		j comparatorLoop #If neither p or q are empty yet, go back to the loop
	addqCoeff: #same as addpCoeff but for q 
		addi $t0, $t0, 1
		lw $t3, 0($a1) #get the coeff of Polynomial q
		sw $t3, 0($s0)
		sw $t4, 4($s0)
		lw $a1, 8($a1) #Only go to the next term in Polynomial q; stay on the current term in Polynomial p
		addi $s0, $s0, 8
		beqz $a1, checkq2 #If the end of p is reached, check if q is also empty before adding the remaining terms in q to terms[]
		j comparatorLoop #If neither p or q are empty yet, go back to the loop
	checkq2: #Checks if q is empty, and adds the rest of the terms in q if not
		qLoop2:
			beqz $a1, endTerms2 #if the end of q is reached, jump to a label that will add the pair (0,-1) to terms[]
			lw $t3, 0($a1)
			lw $t4, 4($a1)
			sw $t3, 0($s0)
			sw $t4, 4($s0)
			addi $s0, $s0, 8
			addi $t0, $t0, 1
			lw $a1, 8($a1) #move to the next term in q
			j qLoop2
	addp2: #Same as checkq2 but for p
		pLoop2:
			beqz $a0, endTerms2 #if the end of q is reached, jump to a label that will add the pair (0,-1) to terms[]
			lw $t3, 0($a0)
			lw $t4, 4($a0)
			sw $t3, 0($s0)
			sw $t4, 4($s0)
			addi $s0, $s0, 8
			addi $t0, $t0, 1
			lw $a0, 8($a0) #move to the next term in p 
			j pLoop2
	endTerms2: #endTerms should put (0,-1) as the last pair in terms[] and return
		sw $0, 0($s0)
		addi $t3, $0, -1
		sw $t3, 4($s0)
		lw $s0, 0($sp)
		addi $sp, $sp, 4
		jr $ra


mult_poly:
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) #Save base address of Polynomial q in s0
	sw $s1, 8($sp) #Save base address of Polynomial r in s1
	sw $s2, 12($sp) #Save base address of Polynomial p in s2
	lw $a0, 8($a0)
	lw $a1, 8($a1)
	addi $s0, $a1, 0 
	addi $s1, $a2, 0 
	addi $s2, $a0, 0 
	beqz $a0, checkq3 #If Polynomial p is empty, check if q is empty before adding its terms to r (same as part 7 but adjusted for part 8)
	beqz $a1, multp #If Polynomial q is empty (meaning p isn't), then add all of p's terms to r 
	part8Loop: #This nested loop should 1)Create the term based off coeff*coeff and exp+exp, 2)Send to a helper to insert/or update as needed and 3)Repeat for each term of p with all q terms
		beqz $s2, part8Return #If the end of Polynomial p has been reached, return v0=1
		lw $t3, 4($s2) #get the exp of the current term in Polynomial p 
		addi $t8, $s0, 0 #Put the first term of Polynomial q into t8 (loop tracker)
		part8NestedLoop:
			beqz $t8, part8LoopNext #Once all of Polynomial q has been appended/updated to r as needed, move to the next term in Polynomial p
			lw $a1, 4($t8) #get the exp of the current term in q
			add $a1, $t3, $a1 #exp+exp
			lw $t5, 0($s2) #Get coeff of current term in Polynomial p 
			lw $a0, 0($t8) #Get coeff of current term in Polynomial q
			mul $a0, $t5, $a0 #coeff*coeff
			jal create_term
			beqz $v0, part8nestedSkip #If this term is not valid, move to the next term
			lw $a0, 8($s1) #Put the base address of the first non-head node of r into a0
			addi $a1, $v0, 0 #Put the base address of the newly created term into a1
			addi $t6, $s1, 0 #Save the head node of r in t6-- if this Polynomial is empty, then this will allow for this new term to be added as a tail
			jal sorter2 #Jump to a helper that will insert the new term into the Polynomial as according to a greatest-least sorting (and if duplicate, then will do coeff+(coeff*coeff)
			part8nestedSkip:
				lw $t8, 8($t8) #Go to the next term in Polymonial q
				j part8NestedLoop
		part8LoopNext:
			lw $s2, 8($s2) #Move to the next term in Polynomial p
			j part8Loop
	part8Return:
		li $v0, 1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
	part8Return0:
		li $v0, 0
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
	checkq3: #Checks if q is empty, and adds the rest of the terms in q if not
		beqz $a1, part8Return0 #If q ia also empty, return v0=0
		qLoop3:
			beqz $s0, part8Return #If the end of q is reached, return v0=1
			addi $a1, $s0, 0 #Put the base address of the first non-head node of Polynomial q into a1
			lw $a0, 8($s1)
			addi $t6, $s1, 0
			jal sorter2
			lw $s0, 8($s0)
			j qLoop3
	multp: #Same as addp in part 7 but for part 8
		pLoop3:
			beqz $s2, part8Return  #if the end of p is reached, return v0=1
			addi $a1, $s2, 0 #Put the base address of the current term of Polynomial p into a1
			lw $a0, 8($s1) #Put the base address of the first non-head node of r into a0
			addi $t6, $s1, 0 #Save the head node of r in t6-- if this Polynomial is empty, then this will allow for this new term to be added as a tail
			jal sorter2 #Jump to a helper that will insert the new term into the Polynomial as according to a greatest-least sorting (and if duplicate, then will do coeff+(coeff*coeff)
			lw $s2, 8($s2) #move to the next term in p
			j pLoop3
sorter2: #sorter2 is very similar to sorter, but updates the coefficient of a existing term if a duplicate is found
	lw $t7, 4($a1) #Get exp of the new term
	beqz $a0, sorterInsert2 #If it is found that the currrent Polynomial is empty, jump to a label that will make this new term a tail
	sorter2Loop:
		lw $t9, 4($a0) #get exp of term in Polynomial
		blt $t9, $t7, sorterInsert3 #If a spot is found where exp_newterm>exp_existingterm, insert this new term in that position in polynomial
		beq $t9, $t7, sorterUpdate #If it is found that a this new term has a exp already present in the Polynomial, subtract one from the loop counter and return
		addi $t6, $a0, 0 #Save the address of this existing term before going to the next term
		#lw $a0, 8($t5)
		lw $a0, 8($a0) #get the next term
		beqz $a0, sorterInsert4 #If the end of the polynomial is reached, jump to a label that will insert the new term at the end of the Polynomial
		#beqz $a0, sorterInsert2
		j sorter2Loop
	sorterInsert3: #sorterInsert1 should handle the case where the new term has to be inserted somewhere in between the ends of the current Polynomial linked list
		lw $t4, 8($t6) #Load the link part of the previous term into t4
		sw $t4, 8($a1) #Set the link of the new term to the term that was previously in its spot
		sw $a1, 8($t6) #Set the link of the previous term to the newly added term
		jr $ra
	sorterInsert4:
		sw $a1, 8($t6) #Set the link of the now old tail to the address of the new term
		jr $ra
	sorterUpdate: #update the coeff of the current term in Polynomial r with: coeff+=newterm_coeff
		lw $t7, 0($a1) #Get the coefficient of new term 
		lw $t9, 0($a0) #Get coefficient of the term in Polynomial r
		add $t7, $t7, $t9
		sw $t7, 0($a0) #Store the new coefficient in the current term in Polynomial r 
		jr $ra
