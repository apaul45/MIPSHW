############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
############################ DO NOT CREATE A .data SECTION ############################
.text:

str_len: #str-len should get the length of a null terminated string-- 0 if only the null terminator itself
	li $t0, 0 #Loop/char counter
	lbu $t1, 0($a0) #Load the first char into t1-- once 0 is reached, the loop will terminate
	part1Loop:
		beq $t1, $0, part1Return #Once the null terminator is reached, jump to a label that will return the counter
		addi $t0, $t0, 1
		addi $a0, $a0, 1
		lbu $t1, 0($a0)
		j part1Loop
	part1Return:
		move $v0, $t0
		jr $ra
str_equals: #equals should iterate char by char through two strings to check if they are equal or not
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp)
	addi $s1, $a0, 0 #Save the base address of the first string in s1
	jal str_len
	move $t7, $v0 #Move the length of the first string into t7
	addi $s2, $a1, 0 #Save the base address of the second string in s2
	move $a0, $a1
	jal str_len
	bne $t7, $v0, part3Return0 #If the length of the strings aren't equal, jump to a loop that will return 0 (indicating that they aren't equal)
	lbu $t1, 0($s1) #t1 will be used to load the chars from the first string
	lbu $t2, 0($s2) #t2 will be used to load the chars from the second string
	equalsLoop:
		beq $t7, $0, part3Return1 #If the end of the string was reached and all chars are equal, jump to label that will restore and return 1
		bne $t1, $t2, part3Return0 #If one set of chars aren't equal, jump to a label that will immediately return 0
		addi $s1, $s1, 1
		addi $s2, $s2, 1
		lbu $t1, 0($s1)
		lbu $t2, 0($s2)
		addi $t7, $t7, -1
		j equalsLoop
	part3Return1:
		lw $ra, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		addi $sp, $sp, 12
		li $v0, 1
		jr $ra
	part3Return0:
		lw $ra, 0($sp)
		lw $s1, 4($sp)
		lw $s2, 8($sp)
		addi $sp, $sp, 12
		li $v0, 0
		jr $ra
str_cpy: #copy should take the string in the source and put it into the destination (and use part 1 to return the number of strings copied)
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal str_len #Get the number of chars in the source string before starting the copy loop
	sub $a0, $a0, $v0 #Move the source string back to its base address
	li $t0, 0 #Loop counter
	lbu $t1, 0($a0) #Load the first char in the source string into t1
	copyLoop: #this loop should continue until v0 is reached, at which point the function should restore ra and jr back to main
		bgt $t0, $v0, part2Return
		sb $t1, 0($a1)
		addi $a0, $a0, 1
		addi $a1, $a1, 1
		addi $t0, $t0, 1
		lbu $t1, 0($a0)
		j copyLoop
	part2Return:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
create_person: #create person should first check if total num nodes and current num are equal. If not, then function should return the address (base address of node set) + (curr num*size)
	lw $t0, 0($a0) #get the total number of nodes
	addi $t1, $a0, 16 #Get to the starting address of the 4 byte int containing the current number of nodes
	lw $t2, 0($t1) #Put the current number of nodes into t2
	beq $t0, $t2, part4ReturnNeg #If the capacity is reached, return v0=-1
	addi $t3, $t2, 1 #Increment the number of current nodes, before getting the starting address of the new node to return in v0
	sw $t3, 0($t1) #Store the new total number of current nodes
	addi $t1, $t1, -8 #Get to the starting address of the 4 byte int representing the size of a given node
	lw $t4, 0($t1) #Put the size of a node into t4
	addi $t1, $t1, 28 #Move to the starting address of the set of nodes in the network
	mul $t4, $t4, $t2 #Multiply the size of a node by the original current number of nodes 
	add $v0, $t4, $t1 #Put this new starting address of the newly added node into v0, to be returned
	jr $ra
	part4ReturnNeg:
		addi $v0, $0, -1
		jr $ra
is_person_exists:#is_person_exists should check if the specified node is in the Network through checking if a node exists at the address of the specified person
	addi $t7, $a0, 36 #get the start of nodes[]
	blt $a1, $t7, part5Return0 #If the address of the person is not valid (below nodes[]), return v0=0
	lw $t0, 0($a0) #Get the total number of nodes 
	lw $t4, 8($a0) #get the size of a node
	mul $t4, $t4, $t0 #Mutliply the size of a node*total number of nodes 
	addi $a0, $t7,$t4 #Get to the start of edges 
	bge $a1, $a0, part5Return0 #If the address of the person is not valid (above nodes[]), return v0=0
	lbu $t0, 0($a1) #Get the char stored at the address specified by this person node
	beq $t0, $0, part5Return0 #If there is no node at the specified address, return 0 to indicate that no person was found
	li $v0, 1
	jr $ra
	part5Return0:
		li $v0, 0
		jr $ra
is_person_name_exists: #is_person_name_exists should use str_equals to iterate through the current set of nodes in search of a node that matches the given string-- if it matches, then return v0=1 and the ref in v1
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp) #Save the size of the node in s0, to be used to advance through the nodes list 
	sw $s1, 8($sp) #Save the base address to the null terminated string to search for in the nodes list to 
	addi $t6, $a0, 8 #Get to the beginning address of the node size in Network (save Network address in t6)
	lw $s0, 0($t6) #Put the length of one node into s0
	addi $s1, $a1, 0 #Put the base address of the null terminated string into s1
	addi $t6, $t6, 28 #Move to the start of the Nodes list in the Network
	part6Loop:
		lbu $a0, 0($t6) #Load the word at the given node
		beq $a0, $0, part6Return0 #If the end of the current Nodes list has been reached, jump to a label that wil return v0=0 and v1=0
		addi $a0, $t6, 0 #Put the address of the current node into a0, to be used in str_equals
		addi $a1, $s1, 0 #Put the address of the null terminated string to compare into a1, to be used in str_equals
		jal str_equals
		bgt $v0, $0, part6Return #If there is a node with a name equal to the inputted one, immediately jump to a label that returns v0=1 and v1 as address
		add $t6, $t6, $s0 #Go to the next node 
		j part6Loop
	part6Return0: #part6Return0 should return v0=0 and jump to a label that returns nothing in v1
		li $v0, 0
		li $t6, 0
		part6Return:
			move $v1, $t6
			lw $ra, 0($sp)
			lw $s0, 4($sp)
			lw $s1, 8($sp)
			addi $sp, $sp, 12
			jr $ra
add_person_property:
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	jal is_person_exists #Check if this person exists in the Network, before checking in the inputted prop name is equal to the name of the person at the given node
	beq $v0, $0, part7Return0 #If the person does not exist, then return v0=0
	addi $s0, $a1, 0 #Put the address to Node* person into s0
	addi $s1, $a0, 0 #Put the base address of Network into s1
	addi $a0, $a2, 0 #Put the prop name into a0
	addi $a1, $s1, 24 #Move to the address containing the "NAME" string, to verify that prop_name="NAME"
	jal str_equals #Jal to a function that will check if prop_name = "NAME"
	beq $v0, $0, part7Return0 #If prop name != "NAME", return v0=0
	addi $a0, $a3, 0 #Put the address of prop_val into a0, of whose length will be checked using the str_len function
	jal str_len
	addi $a0, $s1, 8 
	lw $t0, 0($a0) #Put the number of nodes (located at byte 8 of the Network) into t0
	bgt $v0, $t0, part7ReturnNeg2 #If the prop_val is too large (ie, more chars than specified by node edge), then return vo=-2
	addi $a0, $s1, 0 
	addi $a1, $a3, 0 #Put the address of the prop_val string into a1, to be used to check if prop_val already exists as the name of a existing node in the Network
	jal is_person_name_exists
	bgt $v0, $0, part7ReturnNeg3 #If prop_val is the name of an existing node in the current Network, return v0=-3
	addi $a0, $a3, 0 #Put the address of prop_val into a0 to be used as the thing to copy over to the dest (Node* person) in str_copy
	addi $a1, $s0, 0 #Put the address to Node* person into a1, to be used as the dest address to store prop_val into 
	jal str_cpy
	li $v0, 1
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra
	part7Return0:
		li $v0, 0
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra
	part7ReturnNeg2:
		addi $v0, $0, -2
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra
	part7ReturnNeg3:
		addi $v0, $0, -3
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra
get_person: #get person should be the same as is_person_name_exists but with only one return value
	addi $sp, $sp, -4 
	sw $ra, 0($sp)
	jal is_person_name_exists
	move $v0, $v1 #Put the output of v1 into v0-- part 8 only returns the v1 of part 4 as opposed to both v0 and v1
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
is_relation_exists: #is_relation should use two loops/labels to check if an undirected edge exists between the two inputted node addresses
	lw $t4, 0($a0) #Put the total number of nodes into t4
	addi $a0, $a0, 8 #Move to the address containing the size of a node
	lw $t5, 0($a0) #Put the size of a node into t5
	lw $t7, 4($a0) #Put the size of a edge into t7
	mul $t4, $t4, $t5 #Multiply total nodes by size of a node to be used to get the effective base address of edges[]
	addi $a0, $a0, 28 #Move to the start of nodes[]
	add $a0, $a0, $t4 #Move to the start of edges[]
	part9Loop:
		lw $t0, 0($a0)
		beq $t0, $0, part9Return0 #If no edge exists, return v0=0
		beq $t0, $a1, part9Loop2 #If the first arg = first node, jump to a label that will check if the second node = second arg
		beq $t0, $a2, part9Loop1 #If the second arg = first node, jump to label that will check if first arg = second node 
		add $a0, $a0, $t7 #Move to the next edge
		j part9Loop #Iterate to the next edge
	part9Loop1: #This loop should load the second node in the given edge, and check if the first arg is equal to it
		lw $t0, 4($a0)
		beq $t0, $a1, part9Return1 #If this undirected edge exists, return v0=1
		add $a0, $a0, $t7 #Move to the next edge
		j part9Loop #Iterate to the next edge
	part9Loop2: #This loop should load the second node in the given edge, and check if the second arg is equal to it
		lw $t0, 4($a0)
		beq $t0, $a2, part9Return1 #If this undirected edge exists, return v0=1
		add $a0, $a0, $t7 #Move to the next edge
		j part9Loop #Iterate to the next edge
	part9Return0:
		li $v0, 0 
		jr $ra 
	part9Return1:
		li $v0, 1
		jr $ra
	jr $ra
add_relation: #add_rel should add a edge btwn the 2 args if 4 conditions are met: persons exist, edge not at capacity, person1!=person2, edge unique
	addi $sp, $sp, -16
	sw $ra, 0($sp)
	sw $s0, 4($sp) #Put the address to the first node into s0
	sw $s1, 8($sp) #Put the base address of Network into s1
	sw $s2, 12($sp) #Put the address to the second node into s2
	addi $s0, $a1, 0 #Put the address to the first node into s0
	addi $s1, $a0, 0 #Put the base address of Network into s1
	addi $s2, $a2, 0 #Put the address to the second node into s2
	jal is_person_exists
	beq $v0, $0, part10Return0 #If one of the people don't exist, return 0
	addi $a1, $a2, 0 #Put the address to the second person into a1
	jal is_person_exists
	beq $v0, $0, part10Return0 #If one of the people don't exist, return 0
	addi $s1, $a0, 0 #Put the base address of Network into s1
	lw $t0, 4($a0) #Get the total number of edges
	addi $a0, $a0, 20 #Get to the address containing the current number of edges
	lw $t9, 0($a0) #Get the current number of edges
	beq $t0, $t9, part10ReturnNeg1 #If the capacity of edges[] has been reached, then return v0=-1
	addi $a0, $a0, -20 #Move back to the base address of the Network, for use in a check for a edge containing the two inputted nodes
	addi $a1, $s0, 0 #Put the first node into a1, for use in a check for a edge
	jal is_relation_exists #Check if a edge containing the two inputted nodes already exists, before finally checking if the two nodes are equal
	bgt $v0, $0, part10ReturnNeg2 #If the edge already exits, jump to a label that returns v0=-2
	addi $a0, $s0, 0 
	addi $a1, $s2, 0 #Put the address to the two person nodes into a0 and a1, respectively 
	jal str_equals #Check if the same person was inputted twice
	bgt $v0, $0, part10ReturnNeg3 #If the two people are equal, return v0=-3
	addi $a0, $s1, 12 #Move to the address containing the size of a edge in the Network
	lw $t0, 0($a0) #Get the size of a edge in the Network
	lw $t4, 0($s1) #Put the total number of nodes into t4
	addi $a0, $s1, 8 #Move to the address containing the size of a node
	lw $t5, 0($a0) #Put the size of a node into t5
	lw $t7, 4($a0) #Put the size of a edge into t7
	mul $t4, $t4, $t5 #Multiply total nodes by size of a node to be used to get the effective base address of edges[]
	addi $a0, $a0, 28 #Move to the start of nodes[]
	add $a0, $a0, $t4 #Move to the start of edges[]
	mul $t9, $t0, $t9 #Multiply the current number of edges by the edges size, to get the offset 
	add $a0, $a0, $t9 #Move to the effective address of this new edge
	sw $s0, 0($a0) #Store the first node into the edge
	sw $s2, 4($a0) #Store the second node into the edge
	li $v0, 1
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16
	jr $ra
	part10Return0:
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
	part10ReturnNeg1:
		addi $v0, $0, -1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
	part10ReturnNeg2:
		addi $v0, $0, -2
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra			
	part10ReturnNeg3:
		addi $v0, $0, -3
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		addi $sp, $sp, 16
		jr $ra
	jr $ra
add_relation_property: #add_rel_prop should extend add_rel by adding the friendship property to a existing edge-- should use part 9 to verify the edge exists, along with 2 other checks
	lw $s1, 0($sp) #Load the prop_val from the runtime stack
	sw $ra, 0($sp) #Store ra in place of the prop_val
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	addi $s0, $a0, 0 #Save the base address of Network in s0, before verifying if the given relation exists
	jal is_relation_exists
	beq $v0, $0, part11Return0 #If the relation does not exist, jump to a label that will return v0=0
	move $t6, $a0 #Move the address of the existing edge into t6
	addi $a0, $s0, 29 #Move to the address that contains the "FRIEND" property
	addi $a1, $a3, 0 #Put the prop_name into a1, to be used in str_equals 
	jal str_equals #Check if prop_name = "FRIEND"
	beq $v0, $0, part11ReturnNeg1 #If propName!="FRIEND", jump to a label that will return v0=-1
	blt $s1, $0, part11ReturnNeg2 #If prop_val<0, jump to a label that will return v0=-2
	sw $s1, 8($t6) #If all checks are good, add the friendship property prop_val into the given edge--offset 8 of the edge
	li $v0, 1
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	lw $ra, 0($sp)
	jr $ra
	part11ReturnNeg1:
		addi $v0, $0, -1
		lw $s0, 0($sp)
		addi $sp, $sp, 4
		lw $ra, 0($sp)
		jr $ra
	part11Return0:
		addi $v0, $0, 0
		lw $s0, 0($sp)
		addi $sp, $sp, 4
		lw $ra, 0($sp)
		jr $ra	
	part11ReturnNeg2:
		addi $v0, $0, -2
		lw $s0, 0($sp)
		addi $sp, $sp, 4
		lw $ra, 0($sp)
		jr $ra		
is_friend_of_friend:#ifof should check if the first arg is related to the second arg that is related to a third arg which is to be found
	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	addi $s0, $a0, 0 #Save the base address of the Network into s0
	addi $s1, $a1, 0 #Save the first char into s1
	jal get_person #Check if this person name exists in the Network using part 8
	beq $v0, $0, part12ReturnNeg1 #If it is found that the first person doesn't exist, return v0=-1
	addi $t9, $v0, 0 #Save the address to the first person into t2
	addi $a0, $s0, 0
	addi $a1, $a2, 0 
	jal get_person #Check if the second node exists in the Network
	beq $v0, $0, part12ReturnNeg1 #If it is found that the second person doesn't exist, return v0=-1
	addi $t3, $v0, 0 #Save the address to the second person into t3
	addi $a0, $s0, 0
	addi $a1, $t9, 0 
	addi $a2, $t3, 0 
	jal second_relationHelper12 #Check if there's an edge between person 1 and person 2
	beq $v0, $0, part12Return0 #If a friendship between person 1 and person 2 doesn't exist, return v0=0
	addi $a0, $s0, 0
	addi $a1, $t9, 0 
	addi $a2, $t3, 0 
	jal relationHelper12 #Check if there exists an edge between person 2 and a person besides person 1 (or vice versa)
	beq $v0, $0, part12Return0
	beq $t8, $t9, friendOfFriend2 #If the person that shares a friendship with another person is person 1, jump to a label that checks if person 2 has a friendship with that person
	beq $t8, $t3, friendOfFriend1 #If the person that shares a friendship with another person is person 2, jump to a label that checks if person 1 has a friendship with that person

	friendOfFriend1: #This label should send person 1 and person 3 to be checked for a potential friendship-- if one exists, then jump to part12Return0
		addi $a0, $s0, 0
		addi $a1, $t9, 0 
		addi $a2, $v1, 0 #Check if a friendship between person 1 and the person that is friends with person 2 exists (or vice versa)
		jal second_relationHelper12
		bgt $v0, $0, part12Return0
		li $v0, 1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra
	friendOfFriend2: #Same thing as friendOfFriend1 but with person 2
		addi $a0, $s0, 0
		addi $a1, $t3, 0 
		addi $a2, $v1, 0 #Check if a friendship between person 1 and the person that is friends with person 2 exists (or vice versa)
		jal second_relationHelper12
		bgt $v0, $0, part12Return0
		li $v0, 1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra
	part12Return0:
		li $v0, 0
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra
	part12ReturnNeg1:
		addi $v0, $v0, -1
		lw $ra, 0($sp)
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		addi $sp, $sp, 12
		jr $ra
second_relationHelper12: #This helper is ghe exact same as is_relation_exists but returns if the two people are friends rather than just being related
	lw $t4, 0($a0) #Put the total number of nodes into t4
	addi $a0, $a0, 8 #Move to the address containing the size of a node
	lw $t5, 0($a0) #Put the size of a node into t5
	lw $t7, 4($a0) #Put the size of a edge into t7
	mul $t4, $t4, $t5 #Multiply total nodes by size of a node to be used to get the effective base address of edges[]
	addi $a0, $a0, 28 #Move to the start of nodes[]
	add $a0, $a0, $t4 #Move to the start of edges[]
	srhLoop:
		lw $t0, 0($a0)
		beq $t0, $0, srhReturn0 #If no edge exists, return v0=0
		beq $a1, $t0, srhLoop2 #If the first of two arguments is equal to the first node, jump to a label that will check if the second node = second arg
		beq $a2, $t0, srhLoop1 #If the second arg= first node, jump to label that will check if first arg = second node 
		add $a0, $a0, $t7 #Move to the next edge
		j srhLoop
	srhLoop1: #This loop should load the second node in the given edge, and check if the first arg is equal to it
		lw $t0, 4($a0)
		beq $a1, $t0, srhReturn1 #If this undirected edge exists and friendship val is 1, return v0= 1
		add $a0, $a0, $t7 #Move to the next edge
		j srhLoop #Iterate to the next edge
	srhLoop2: #This loop should load the second node in the given edge, and check if the second arg is equal to it
		lw $t0, 4($a0)
		beq $a2, $t0, srhReturn1 #If this undirected edge exists and friendship val is 1, return v0=1
		add $a0, $a0, $t7 #Move to the next edge
		j srhLoop #Iterate to the next edge
	srhReturn0:
		li $v0, 0 
		jr $ra 
	srhReturn1: #Check if friendship val is 1 before returning
		lw $t0, 8($a0)
		ble $t0, $0, srhReturn0
		li $v0, 1 #If the friendship val is 1, return v0=1
		jr $ra
relationHelper12: #This helper is a lot like is_relation_exists, but only checks if the first arg is in a edge with a different person than the second or vice versa
	lw $t4, 0($a0) #Put the total number of nodes into t4
	addi $a0, $a0, 8 #Move to the address containing the size of a node
	lw $t5, 0($a0) #Put the size of a node into t5
	lw $t7, 4($a0) #Put the size of a edge into t7
	mul $t4, $t4, $t5 #Multiply total nodes by size of a node to be used to get the effective base address of edges[]
	addi $a0, $a0, 28 #Move to the start of nodes[]
	add $a0, $a0, $t4 #Move to the start of edges[]
	loop:
		lw $t0, 0($a0)
		beq $t0, $0, return0 #If no edge exists, return v0=0
		beq $a1, $t0, loop2 #If the first arg=first node, jump to a label that will check if the second arg!=second node
		beq $a2, $t0, loop1 #If the second arg=first node, jump to label that will check if first arg != second node 
		lw $t1, 4($a0)
		addi $t8, $a1, 0 
		beq $a1, $t1, returnAddress #If the first arg = the second node, return the address of this edge 
		addi $t8, $a2, 0
		beq $a2, $t1, returnAddress #If the second arg = the second node, return the address of this edge
	advanceloop:
		add $a0, $a0, $t7 #Move to the next edge
		j loop #Iterate to the next edge
	loop1: #This loop should load the second node in the given edge, and check if the first arg is equal to it
		addi $t8, $a2 0 #Put the address of person 2 into t8
		lw $t0, 4($a0)
		bne $a1, $t0, returnAddress #If an undirected edge between person 2 and another person besides person 1 exists, return the address of the edge along with the person that person 2 shares the edge with
		add $a0, $a0, $t7 #Move to the next edge
		j loop #Iterate to the next edge
	loop2:
		addi $t8, $a1, 0 #Put the address of person 1 into t8
		lw $t0, 4($a0)
		bne $a2, $t0, returnAddress #If second node != second arg, return the address of this edge along with the person that person 1 shares the edge with
		add $a0, $a0, $t7
		j loop
	return0:
		li $v0, 0 
		jr $ra 
	returnAddress: #Return the address of this edge along with the address of the person related to person 2 in this edge
		lw $t6, 8($a0) #Check if the friendship property of this edge is 1
		ble $t6, $0, return0 #If the friendship property is <=0, return v0=0
		move $v0, $a0 #Return address of this edge in v0
		move $v1, $t0 #Return address of the person sharing this edge with 
		jr $ra
