# Computer Architecture Homework 3
# 06/20/2020
# Author: Garrett Strealy
#-------------------------------------------
# This program reads ints from a .txt file, puts them into an array, and prints the array.
# Then it selection sorts the array and prints the array again. Then it computes the mean, 
# median and standard deviation of the numbers within the array, and prints those.
#-------------------------------------------

		.data 

fin:		.asciiz	"input.txt"
		.align	2
buffer:		.space	80
intArray:	.space	80
arraySize:	.word	20
errorMsg:	.asciiz "error"
beforeMsg:	.asciiz "The array before: " 
afterMsg:	.asciiz "The array after: "
newline:	.asciiz "\n"
meanMsg:	.asciiz "The mean is: "
medianMsg:	.asciiz "The median is: "
stnDevMsg:	.asciiz "The standard deviation is: "
zero:		.float 0.0
two:		.float 2.0

		.globl main
		.text
		
main:

.macro print_string (%string)
	la $a0, %string
	li $v0, 4
	syscall
.end_macro 

.macro print_float (%float)
	li $v0, 2
	mov.s $f12, %float
	syscall
.end_macro 

	# read .txt file
	la $a0, fin	# file to be read in $a0
	la $a1, buffer	# buffer to store string in $a1
	jal readFile

	# if $v0 <= 0, go to errorExit
	ble $v0, $zero, errorExit
	# else, parse ints from buffer and store them in intArray
	jal extractInts

	# print array before sorting
	print_string (beforeMsg)	
	jal printArray
	print_string (newline)

	# sort array
	la $a0, intArray
	lw $a1, arraySize
	jal sortArray

	# print array after sorting
	print_string (afterMsg)
	jal printArray
	print_string (newline)

	# calculate and print mean
	la $a0, intArray
	lw $a1, arraySize
	jal calcMean

	print_string (meanMsg)
	print_float ($f7)
	print_string (newline)

	# calculate and print median
	la $a0, intArray
	lw $a1, arraySize
	jal calcMedian

	print_string (medianMsg)
	bgt $v1, $zero, printFloat # if $v1 > 0, print float median
	li $v0, 1		   # else, print int median
	move $a0, $s0
	syscall
	printFloat: print_float($f0)
	print_string (newline)

	# calculate and print standard deviation
	la $a0, intArray
	lw $a1, arraySize
	jal calcStnDev
	print_string (stnDevMsg)
	print_float ($f0)

	# exit
	li $v0, 10
	syscall

readFile:
	# open file
	li $v0, 13	# system call for open file
	la $a0, fin	# input file name == "fin"
	li $a1, 0	# open for reading
	li $a2, 0	# mode irrelevant
	syscall		# open file, returned in $v0
	move $s0, $v0	# save the file descriptor

	# read file
	li $v0, 14       # system call for read from file
	move $a0, $s0    # file descriptor 
	la $a1, buffer   # address of buffer to which to read
	li $a2, 80       # hardcoded buffer length
	syscall          # read from file

	# close file 
	li $v0, 16       # system call for close file
	move $a0, $s0    # file descriptor to close
	syscall

	jr $ra		 # return to main

errorExit:
# print error message, then quit
	li $v0, 4
	la $a0, errorMsg
	syscall
	# exit
	li $v0, 10
	syscall

extractInts:
# create array of ints in intArray from string of ints in buffer
	la $s0, buffer		# $s0 points to buffer
	la $s1, intArray	# $s1 points to intArray
	li $t0, 0		# i = 0
	li $t1, 0		# word accumulator
	li $t3, 10		# constant for multTen

	# loop to place each int within its own word boundary in intArray
	parseWord:
		lb $t2, ($s0)		   # $t2 = buffer[]
		beq $t2, '\0', exitExtract # exit if byte = '\0'
		beq $t2, 10, nextWord	   # if byte = '\n' go to next word
		blt $t2, 48, nextChar	   # if $t2 is not a digit, go to nextChar
		bgt $t2, 57, nextChar	   # same as above
		beq $t0, 1, multTen	   # if on second digit (i = 1), multiply current total by 10
		j convert
		
	multTen:
		multu $t1, $t3		
		mflo $t1		# $t6 = $t6 * 10
		j convert
		
	convert:
		addi $t2, $t2, -48	# convert ASCII to decimal
		add $t1, $t1, $t2	# $t6 = $t6 + $t2
		addi $t0, $t0, 1	# i++
		addi $s0, $s0, 1	# increment buffer
		j parseWord		#loop
		
	nextWord: 
	# skip to next word	
		sw $t1, ($s1)		# save accumulated int to intArray
		li $t1, 0		# reset accumulator
		li $t0, 0		# reset i
		beq $s1, 80, exitExtract# if 80 bytes have been processed, go to exitLoop
		addi $s0, $s0, 1	# increment buffer
		addi $s1, $s1, 4 	# increase intArray by 4	
		j parseWord
		
	nextChar:
	# skip to next byte
		addi $s0, $s0, 1	# increment buffer
		j parseWord

	exitExtract:
		sw $t1, ($s1)		# save last int
		jr $ra			# return to main

printArray: 
	li $t0, 0		# i = 0
		
	while:
		beq $t0, 80, exitPrint	# exit if i = end of intArray (80)
			
		lw $t1, intArray($t0)	# $t1 = intArray[$t0]
			
		addi $t0, $t0, 4	# move to next word
			
		# print current int
		li $v0, 1
		move $a0, $t1
		syscall	
		
		space:
		# print space
		li $v0, 11 
		li $a0, 32
		syscall
		
		j while
		
	exitPrint:
		jr $ra # return to main

sortArray:
# selection sort of intArray
	move $a2, $a1   # $a2 = n (count)
	sub $a1, $a1, 1 # $a1 = n - 1 (count - 1)
	li $t0, 0       # i = 0

	forLoop1:
	# if i == n - 1, exit loop
		beq $t0, $a1, exitSort
		move $s0, $t0 	 # argmin = i
		move $t1, $t0 	 # j = i
	forLoop2:
		addi $t1, $t1, 1 # j = i + 1
		bne $t1, $a2, compare
		j swap
		
	compare:
		li $t2, 4
		mul $t3, $t2, $t1
		add $t3, $t3, $a0
		mul $t4, $t2, $s0
		add $t4, $t4, $a0
		lw $t5, 0($t3) # $t5 = unsorted[j]
		lw $t6, 0($t4) # $t6 = unsorted[argmin]
		slt $t7, $t5, $t6 # if $t5 < $t6, set $t7 = 1
		bne $t7, 1, forLoop2 # if $t7 != 1, go to forLoop2
		
		move $s0, $t1  # else, set argmin = j
		j forLoop2
	
	# swap unsorted[i] and unsorted[argmin]
	swap:
		li $t2, 4
                mul $t3, $t2, $t0
                add $t3, $t3, $a0
                lw $t5, 0($t3) # $t5 = unsorted[i]
                mul $t4, $t2, $s0
                add $t4, $t4, $a0
                lw $t6, 0($t4) # $t6 = unsorted[argmin]
                sw $t5, ($t4)
                sw $t6, ($t3)
                add $t0, $t0, 1
                j forLoop1
	
	exitSort:
		jr $ra # return to main

calcMean:
# calculate mean of ints in intArray 
	mtc1 $a1, $f2
	cvt.s.w $f2, $f2 # $f2 = arraySize converted to float
	l.s $f0, zero    # sum accumulator
	li $t0, 4        # intArray traversal constant
	li $t3, 0        # i = 0
	
	 calcSum:
	 # loop to accumulate sum
	 	 beq $t3, 20, divBySum # at end of intArray go to divBySum
	 	 
	 	 lw $t2, ($a0)
	 	 mtc1 $t2, $f1       
	 	 cvt.s.w $f1, $f1      # $f1 = intArray[] converted to float
	 	 
	 	 add.s $f0, $f0, $f1   # sum += $f3
	 	 
	 	 add $a0, $a0, $t0     # intArray += 4
	 	 addi $t3, $t3, 1      # i++
	 	 
	 	 j calcSum

	 divBySum:
	 	div.s $f7, $f0, $f2  # $f7 = sum / arraySize
	 	
	 exitMean:
	 	jr $ra # return to main, $f0 == mean
	 
calcMedian:
	l.s $f2, two			# $f2 = 2.0
	li $t6, 2			# $t6 = 2
	li $t7, 4			# $t7 = 4
	div $a1, $t6			# arraySize / 2
	mflo $t0			# $t0 = quotient of arraySize / 2
	addi $t1, $t0, -1		# $t1 = half of quotient of arraySize - 1
	mfhi $t2			# $t2 = remainder of arraySize / 2
	
	# if remainder > 0, median is middle int, so go to calcInt
		bgt $t2, $zero, calcInt
	
	# else, calculate float median with two middle ints of intArray
		multu $t0, $t7		# $t0 * 4
		mflo $t0		# $t0 = middle index 1
		lw $t0, intArray($t0)   # $t0 = middle int 1
		mtc1 $t0, $f0 
		cvt.s.w $f0, $f0	# convert to float
	
		multu $t1, $t7		# $t1 * 4
		mflo $t1		# $t1 = middle index 2
		lw $t1, intArray($t1)   # $t1 = middle int 2
		mtc1 $t1, $f1 
		cvt.s.w $f1, $f1	# convert to float
	
		add.s $f0, $f0, $f1     # add the two middle ints
		div.s $f0, $f0, $f2     # $f0 = $f0 / 2.0
	
		li $v1, 1		# indicates even arraySize
		j exitMedian		# $f0 == median
	
	calcInt:
	# find and return middle int of intArray
		multu $t0, $t7		# $t0 * 4
		mflo $t0		# $t0 = middle index of intArray
		lw $s0, intArray($t0)	# $t0 = middle int of intArray
		li $v1, 0		# indicates odd arraySize
		j exitMedian		# $s0 == median
	 	
	exitMedian: 
		jr $ra # return to main
	 
calcStnDev:
# calculate standard deviation of intArray
	li $t0, 0 # i = 0
	l.s $f0, zero # sum holder
	addi $t2, $a1, -1 # $t2 = arraySize (n) - 1
	mtc1 $t2, $f2 
	cvt.s.w $f2, $f2 # $f2 = $t2 converted to float
	# $f7 already holds mean
	
	sumLoop:
	# calculate numerator of standard deviation formula
		beq $t0, 80, divSum # at end of array, go to square sum
		
		lw $t1, intArray($t0)	# $t1 = intArray[] current int
		mtc1 $t1, $f1 
		cvt.s.w $f1, $f1	# $f1 = current int converted to float
		sub.s $f1, $f1, $f7	# $f1 = current int - mean
		mul.s $f1, $f1, $f1	# square $f1
		add.s $f0, $f0, $f1 	# add $f1 to sum
		
		addi $t0, $t0, 4
		j sumLoop
	
	divSum:
	# divide sum by (n - 1)
		div.s $f0, $f0, $f2
		
	sqrtTotal:
	# calculate root of quotient
		sqrt.s $f0, $f0 	# $f0 = standard deviation
	
	exitStnDev:
		jr $ra # return to main

#-------------------------------------------
# The array before: 	18 9 27 5 48 16 2 53 64 98 49 82 7 17 53 38 65 71 24 31 
# The array after: 	2 5 7 9 16 17 18 24 27 31 38 48 49 53 53 64 65 71 82 98 
# The mean is: 38.85
# The median is: 34.5
# The standard deviation is: 27.686735
# -- program is finished running --
#-------------------------------------------

