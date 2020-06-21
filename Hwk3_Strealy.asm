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
errorMsg:	.asciiz "error"
beforeMsg:	.asciiz "The array before: " 
afterMsg:	.asciiz "The array after: "

		.globl main
		.text
		
main:

la $a0, fin	# file to be read in $a0
la $a1, buffer	# buffer in $a1
jal readFile

# if $v0 <= 0, go to errorExit
ble $v0, $zero, errorExit
# else, go to extractInts
jal extractInts

jal printBeforeArray

li $v0, 10
syscall

readFile:

	# open file
	li $v0, 13	# system call for open file
	la $a0, fin	# input file name "fin"
	li $a1, 0	# open for reading
	li $a2, 0	# mode irrelevant
	syscall		# open file, returned in $v0
	move $s0, $v0	# save the file descriptor

	# read from file
	li $v0, 14       	# system call for read from file
	move $a0, $s0      	# file descriptor 
	la $a1, buffer   	# address of buffer to which to read
	li $a2, 80       	# hardcoded buffer length
	syscall            	# read from file

	# close the file 
	li $v0, 16       	# system call for close file
	move $a0, $s0      	# file descriptor to close
	syscall

	jr $ra

errorExit:

	# print error message
	li $v0, 4
	la $a0, errorMsg
	syscall
	# exit
	li $v0, 10
	syscall

extractInts:

la $s0, buffer		# $s0 points to buffer
la $s1, intArray	# $s1 points to intArray
li $t0, 0		# i = 0
li $t1, 3		# intLoop max = 3
li $t3, 4		# nextWord max = 4

	# loop to place each int within its own word boundary in intArray
	intLoop:
	beq $t0, $t1, exitLoop	# exit loop if i = end of word
	lb $t2, ($s0)		# $t2 = intArray[]
	beq $t2, '\n', nextWord	# if $t2 = \n, go to nextWord
	beq $t2, '\0', exitLoop	# if $t2 = \0, go to exitLoop
	sb $t2, ($s1)		# save byte in $t2 to intArray[]
	addi $t0, $t0, 1	# i++
	addi $s0, $s0, 1	# increment buffer
	addi $s1, $s1, 1 	# increment intArray
	j intLoop
	
		# skip to next word
		nextWord:
		sub $t4, $t3, $t0	# $t4 = 4 - i	 
		add $s1, $s1, $t4	# increment intArray by $t4
		li $t0, 0		# restore i to 0		
		addi $s0, $s0, 1	# increment buffer
		j intLoop

		exitLoop:
		jr	$ra

printBeforeArray:

	# print before message
	la $a0, beforeMsg
	li $v0, 4
	syscall

	# print array 
	la $s0, intArray
	li $t0, 0		# i = 0
		
	while:
		beq $t0, 80, exit	# exit if i = end of array
			
		lw $t1, intArray($t0)	# $t1 = intArray[$t0]
			
		addi $t0, $t0, 4	# move to next word in intArray
			
		# print current int
		li $v0, 1
		move $a0, $t1
		syscall	
		
		# print space
		li $v0, 11 
		li $a0, 32
		syscall
		
		j while
		
	exit:
	jr $ra

printAfterArray:

	# print after message
	la $a0, afterMsg
	li $v0, 4
	syscall

	# print array
	la	$s0, intArray
	
	jr $ra
		
# Current output:
# The array before: 14385 57 14130 53 14388 13873 50 13109 13366 14393 14644 12856 55 14129 13109 14387 13622 12599 13362 12595
