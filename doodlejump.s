#####################################################################
#
# CSCB58 Fall 2020 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Haofeng Jiang  1004723962
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# - Milestone 5
#
# Which approved additional features have been implemented?
# 
# - 4a. Scoreboard / score count
# - 4c. Dynamic increase in difficulty (speed, obstacles, shapes etc.) as game progresses
# - 5a. Realistic physics
# - 5b. More platform types:
#	i. Moving blocks  (Colour = Blue)
#	ii. ¡°Fragile" blocks (Colour = Brown)
#	iii. Shrinking blocks (Shorten when rise / fall)   (Colour = Purple)
#	iv. Deadly blocks (Game over when hit)  (Colour = Black)
# - 5c. Boosting / power-ups:
#	i. Rocket suit  (Colour = Red)
#		Generate randomly on screen.
#		Doodler becomes invincible (Cannot die when screen scrolls), showing red
#	ii. Springs  (Colour = Grey)
#		Generate randomly on a platform.
# - 5g. Opponents / lethal creatures   (Colour = Black)
#		Generate randomly on screen.
#
# Link to video demonstration for final submission:
# - https://play.library.utoronto.ca/a8352a0e942a8622997717ee3db3eba3
#
# Any additional information that the TA needs to know:
# - Please refer to the below code information of each milestone
#	1a. Code location: Line 155
#	1b. Code location: Line 177, 170
#	2a. Code location: Line 1500
#	2b. Code location: Line 1704
#	3a. Code location: Line 839, 1111
#	3b. Code location: Line 1851
#	4a. Code location: Line 245, 1087
#	4c. Code location: Line 1269, 249, 861
#	5a. Code location: Line 1256
#	5b. Code location: Line 895
#	5c. Code location: Line 973, 985
#	5g. Code location: Line 1008
#
# - The details of attributes in 4c:
#	Score	SleepTime	PlatformLength	JumpHeight	PlatformTypes / Additional items
#	0 - 49             10			13				20		All Normal platforms
#	50 - 99            8			11				15		Add Shrinking platforms
#	100 - 199       6			9				13		Add Moving platforms
#	200 - 499       5			7				12		Add Fragile platforms, add lethal creatures
#	>500              4				5				11		Add Deadly platforms, reduce the appearence of Normal type
#
#
#
# - Additional attributes that makes the game more smooth:
#	1. If all platforms are unreachable and the Doodler is jumping back and forth in the last rows:
#		You can press "s" to add a spring in the middle of the last row to continue playing.
#
#	2. If the game is over and you do not want to restart:
#		You can press "a" to completely end the run and your score will print in the Mars Messages.
#
#####################################################################

# Register Usage

# $a0 -> temporary argument
# $a1 -> temporary argument
# $a2 -> temporary argument
# $a3 -> temporary argument
# $t0 -> temporary argument
# $t1 -> temporary argument
# $t2 -> temporary argument
# $t3 -> The "head" of Doodler
# $t4 -> The Length of the Platform
# $t5 -> The Jumping height of Doodler
# $t6 -> temporary argument
# $t7 -> temporary argument
# $t8 -> The base address for display
# $t9 -> The score of the game.
# $s0 -> Store background color code
# $s1 -> Store Doodler color code
# $s2 -> Store normal platform color code
# $s3 -> Store on-screen words color code
# $s4 -> Store Springs color code
# $s5 -> Store Rocket color code
# $s6 -> Store other types of platform color code
# $s7 -> Store temporary color code
# $k0 -> Indicate the motion of Doodler (0 = Rise, 1 = Fall, 2 = ScreenScroll, 3 = GameOver)
# $k1 -> Indicate the remaining times in screen scrolling


############################################################################




.data
displayAddress: .word 0x10008000
newline: .asciiz "\n"
space: .asciiz " "
PlatformColours: .space 20
MLPlatforms: .word -1:10  # Indices of Moving-Left platforms
MRPlatforms: .word -1:10  # Indices of Moving-Right platforms
SPlatforms: .word -1:10  # Indices of Shrinking platforms


.globl main
.text
main:

InitialDataSet:
	lw $t8, displayAddress # $t8 stores the base address for display
	li $s0, 0xffffcc		 # $s0 stores the light-yellow colour code
	li $s1, 0x0066ff	# $s1 stores the deep-blue colour code
	li $s2, 0x33cc33 	# $s2 stores the deep-green colour code
	li $s3, 0xffcc00       # $s3 stores the orange colour code
	li $s4, 0x5f5f5f      # $s4 stores the grey colour code
	li $s5, 0xff0066     # $s5 stores the red colour code
	la $s6, PlatformColours
	li $s7, 0x00ccff 
	sw $s7, ($s6)
	li $s7, 0x996600
	sw $s7, 4($s6)
	li $s7, 0x9900cc
	sw $s7, 8($s6)
	li $s7, 0x00ccfe
	sw $s7, 12($s6)
	li $s7, 0x000001
	sw $s7, 16($s6)
	
	li $t4, 13
	li $t5, 20
	li $t9, 0
	
	li $t0, 0
	li $t1, -1
	InitializeArrays:	
	bge $t0, 40, Background
	sw $t1, MLPlatforms($t0)
	sw $t1, MRPlatforms($t0)
	sw $t1, SPlatforms($t0)
	addi $t0, $t0, 4
	j InitializeArrays
	
Background:	
	la $t0, ($t8)   #Use $t0 to visit each pixel address
	li $t1, 0     #Use $t1 to record times of iteration
	
	
	BackgroundLoop:
	beq $t1, 2048, BackgroundDone  #We have 2048 pixels
	sw $s0, ($t0) # paint the unit.
	addi $t0, $t0, 4
	addi $t1, $t1, 1
	j BackgroundLoop
	
BackgroundDone:
	la $t2, 8064($t8) #There should be a platform in the last row when the game just starts.
	jal GeneratePlatform
	addi $t3, $t0, -400  # Now $t3 stores the address of the "head" of Doodler
	jal GenerateDoodler
	
	#Initialize the score
	li $t9, 0
	jal ShowScoreInitial
	
	#Generate more platforms
	# Ensure at least one platform is reachable at the beginning	
	li $v0, 42
	li $a0, 1
	move $a1, $t5
	syscall
	move $t7, $a0
	sub $t6, $t3, $t8
	srl $t6, $t6, 7
	sub $t7, $t6, $t7
	sll $t7, $t7, 7
	add $t2, $t7, $t8
	jal GeneratePlatform
	
	
	li $t7, 12
	li $a2, 0
	
	Platforms:
	beq $a2, $t7, PlatformsDone
	li $v0, 42
	li $a0, 0
	li $a1, 63
	syscall
	li $t6, 128
	mult $a0, $t6
	mflo $t2
	add $t2, $t2, $t8
	jal GeneratePlatform
	
	addi $a2, $a2, 1
	j Platforms
	PlatformsDone:
	
	j PlayGame
	





	
#######################################################################################	
ShowScoreInitial:
	addi $t2, $t8, 6376
	li $t1,0
	ShowScoreInitialLoop:
	bge $t1, 7, ShowScoreInitialLoopDone
	
	sw $s3, ($t2)
	sw $s3, 4($t2)
	sw $s3, 8($t2)
	sw $s3, 128($t2)
	sw $s3, 136($t2)
	sw $s3, 256($t2)
	sw $s3, 264($t2)
	sw $s3, 384($t2)
	sw $s3, 392($t2)
	sw $s3, 512($t2)
	sw $s3, 516($t2)
	sw $s3, 520($t2)
	
	addi $t1, $t1, 1
	addi $t2, $t2, -16
	j ShowScoreInitialLoop
	ShowScoreInitialLoopDone:
	jr $ra

ShowScore:
#Argument: $t9
	
	#Update Platform length and Jumping height
	blt $t9, 50, EasyMode
	blt $t9, 100, FairMode
	blt $t9, 200, MediumMode
	blt $t9, 500, HardMode
	bge $t9, 500, CrazyMode
		
	EasyMode:
	li $t4, 13
	li $t5, 20
	j UpdateModeDone
	
	FairMode:
	li $t4, 11
	li $t5, 15
	j UpdateModeDone
	
	MediumMode:
	li $t4, 9
	li $t5, 13
	j UpdateModeDone
	
	HardMode:
	li $t4, 7
	li $t5, 12
	j UpdateModeDone
	
	CrazyMode:
	li $t4, 5
	li $t5, 11
	j UpdateModeDone
	
	UpdateModeDone:
	move $t7, $t9
	addi $t2, $t8, 6376
	li $t0, 0
	ShowScoreLoop:
	bge $t0, 7, ShowScoreLoopDone
	li $t6, 10
	div $t7, $t6
	mflo $t7
	mfhi $a2
	j DisplayNumber
	DisplayNumberDone:
	addi $t2, $t2, -16
	addi $t0, $t0, 1
	j ShowScoreLoop
	ShowScoreLoopDone:
	beq $k0, 0, DoodlerRise
	beq $k0, 1, DoodlerFall 
	beq $k0, 3, GameOverMessage

DisplayNumber:
#Argument: $t2 = position ID; $a2 = the number to show

	beq $a2, 0, Number0
	beq $a2, 1, Number1
	beq $a2, 2, Number2
	beq $a2, 3, Number3
	beq $a2, 4, Number4
	beq $a2, 5, Number5
	beq $a2, 6, Number6
	beq $a2, 7, Number7
	beq $a2, 8, Number8
	beq $a2, 9, Number9
	
	Number0:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorHigh
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorLow
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorHigh
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number1:
	la $a2, ($t2)
	jal ScoreColorLow
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorLow
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorHigh
	la $a2, 136($t2)
	jal ScoreColorLow
	la $a2, 256($t2)
	jal ScoreColorLow
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorLow
	la $a2, 384($t2)
	jal ScoreColorLow
	la $a2, 388($t2)
	jal ScoreColorHigh
	la $a2, 392($t2)
	jal ScoreColorLow
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone

	Number2:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorLow
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorHigh
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorHigh
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorLow
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number3:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorLow
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorHigh
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorLow
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number4:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorLow
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorHigh
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorLow
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorLow
	la $a2, 516($t2)
	jal ScoreColorLow
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number5:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorLow
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorLow
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number6:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorLow
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorHigh
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number7:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorHigh
	la $a2, 256($t2)
	jal ScoreColorLow
	la $a2, 260($t2)
	jal ScoreColorLow
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorLow
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorLow
	la $a2, 516($t2)
	jal ScoreColorLow
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number8:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorHigh
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorHigh
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	Number9:
	la $a2, ($t2)
	jal ScoreColorHigh
	la $a2, 4($t2)
	jal ScoreColorHigh
	la $a2, 8($t2)
	jal ScoreColorHigh
	la $a2, 128($t2)
	jal ScoreColorHigh
	la $a2, 132($t2)
	jal ScoreColorLow
	la $a2, 136($t2)
	jal ScoreColorHigh
	la $a2, 256($t2)
	jal ScoreColorHigh
	la $a2, 260($t2)
	jal ScoreColorHigh
	la $a2, 264($t2)
	jal ScoreColorHigh
	la $a2, 384($t2)
	jal ScoreColorLow
	la $a2, 388($t2)
	jal ScoreColorLow
	la $a2, 392($t2)
	jal ScoreColorHigh
	la $a2, 512($t2)
	jal ScoreColorHigh
	la $a2, 516($t2)
	jal ScoreColorHigh
	la $a2, 520($t2)
	jal ScoreColorHigh
	j DisplayNumberDone
	
	ScoreColorHigh:
	bne $k0, 3, NormalShowHigh
	li $s7, 0xff0000
	sw $s7, ($a2)
	jr $ra
	
	NormalShowHigh:
	lw $s7, ($a2)
	beq $s7, $s1, NoColorChange_ScoreHigh
	beq $s7, $s2, NoColorChange_ScoreHigh
	beq $s7, $s4, NoColorChange_ScoreHigh
	beq $s7, $s5, NoColorChange_ScoreHigh
	lw $a0, ($s6)
	beq $s7, $a0, NoColorChange_ScoreHigh
	lw $a0, 4($s6)
	beq $s7, $a0, NoColorChange_ScoreHigh
	lw $a0, 8($s6)
	beq $s7, $a0, NoColorChange_ScoreHigh
	lw $a0, 12($s6)
	beq $s7, $a0, NoColorChange_ScoreHigh
	sw $s3, ($a2)
	NoColorChange_ScoreHigh:
	jr $ra
	
	ScoreColorLow:

	lw $s7, ($a2)
	beq $s7, $s1, NoColorChange_ScoreLow
	beq $s7, $s2, NoColorChange_ScoreLow
	beq $s7, $s4, NoColorChange_ScoreLow
	beq $s7, $s5, NoColorChange_ScoreLow
	lw $a0, ($s6)
	beq $s7, $a0, NoColorChange_ScoreLow
	lw $a0, 4($s6)
	beq $s7, $a0, NoColorChange_ScoreLow
	lw $a0, 8($s6)
	beq $s7, $a0, NoColorChange_ScoreLow
	lw $a0, 12($s6)
	beq $s7, $a0, NoColorChange_ScoreLow
	sw $s0, ($a2)
	NoColorChange_ScoreLow:
	jr $ra

GenerateDoodler:
#Argument: $t3
 
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	la $a2, ($t3)
	jal GenerateDoodlerColor
	
	#Justify if Doodler is in left-most position or right-most position
	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 0, GenerateLeftMost
	beq $a2, 124, GenerateRightMost 
	
	#Doodler is in the middle
	la $a2, 124($t3)
	jal GenerateDoodlerColor
	la $a2, 128($t3)
	jal GenerateDoodlerColor
	la $a2, 132($t3)
	jal GenerateDoodlerColor
	la $a2, 252($t3)
	jal GenerateDoodlerColor
	la $a2, 260($t3)
	jal GenerateDoodlerColor
	j GenerateDoodlerDone
	
	#Doodler is in left-most position
	GenerateLeftMost:
	la $a2, 252($t3)
	jal GenerateDoodlerColor
	la $a2, 128($t3)
	jal GenerateDoodlerColor
	la $a2, 132($t3)
	jal GenerateDoodlerColor
	la $a2, 380($t3)
	jal GenerateDoodlerColor
	la $a2, 260($t3)
	jal GenerateDoodlerColor
	j GenerateDoodlerDone
	
	#Doodler is in right-most position
	GenerateRightMost:
	la $a2, 124($t3)
	jal GenerateDoodlerColor
	la $a2, 128($t3)
	jal GenerateDoodlerColor
	la $a2, 4($t3)
	jal GenerateDoodlerColor
	la $a2, 252($t3)
	jal GenerateDoodlerColor
	la $a2, 132($t3)
	jal GenerateDoodlerColor
	j GenerateDoodlerDone
	
	GenerateDoodlerDone:
	lw $ra, ($sp)
	jr $ra

	GenerateDoodlerColor:
	lw $s7, ($a2)
	beq $s7, $s3, ColorChanged_Generate
	beq $s7, $s5, TouchRocket
	beq $s1, 0xff5050, Continue
	beq $s7, 0x000001, GameOver
	Continue:
	bne $s7, $s0, NoColorChange_Generate
	ColorChanged_Generate:
	sw $s1, ($a2)
	NoColorChange_Generate:
	jr $ra



DeleteDoodler:
# Argument: $t3

	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	la $a2, ($t3)
	jal DeleteDoodlerColor
	
	#Justify if Doodler is in left-most position or right-most position
	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 0, DeleteLeftMost
	beq $a2, 124, DeleteRightMost 
	
	#Doodler is in the middle
	la $a2, 124($t3)
	jal DeleteDoodlerColor
	la $a2, 128($t3)
	jal DeleteDoodlerColor
	la $a2, 132($t3)
	jal DeleteDoodlerColor
	la $a2, 252($t3)
	jal DeleteDoodlerColor
	la $a2, 260($t3)
	jal DeleteDoodlerColor
	j DeleteDoodlerDone
	
	#Doodler is in left-most position
	DeleteLeftMost:
	la $a2, 252($t3)
	jal DeleteDoodlerColor
	la $a2, 128($t3)
	jal DeleteDoodlerColor
	la $a2, 132($t3)
	jal DeleteDoodlerColor
	la $a2, 380($t3)
	jal DeleteDoodlerColor
	la $a2, 260($t3)
	jal DeleteDoodlerColor
	j DeleteDoodlerDone
	
	#Doodler is in right-most position
	DeleteRightMost:
	la $a2, 124($t3)
	jal DeleteDoodlerColor
	la $a2, 128($t3)
	jal DeleteDoodlerColor
	la $a2, 4($t3)
	jal DeleteDoodlerColor
	la $a2, 252($t3)
	jal DeleteDoodlerColor
	la $a2, 132($t3)
	jal DeleteDoodlerColor
	j DeleteDoodlerDone
	
	DeleteDoodlerDone:
	lw $ra, ($sp)
	jr $ra

	DeleteDoodlerColor:
	lw $s7, ($a2)
	beq $s7, 0xff5050, ColorChanged_Delete
	bne $s7, $s1, NoColorChange_Delete
	ColorChanged_Delete:
	sw $s0, ($a2)
	NoColorChange_Delete:
	jr $ra





GeneratePlatform:
# Argument: $t2 = the row number to generate platform

	la $t0, ($t8)   #Use $t0 to visit each pixel address
	li $t1, 0     #Use $t1 to record times of iteration
	
	
	#The column of the platform to be generated.
	li $v0, 42
	li $a0, 0
	li $t6, 32
	sub $a1, $t6, $t4
	syscall
	li $t6,4
	mult $a0, $t6
	mflo $a0
	add $t0, $t2, $a0
	
	
	
	#Decide which platform to generate
	li $v0, 42
	blt $t9, 50, AllNormal
	blt $t9, 100, HaveFP
	blt $t9, 200, HaveMP
	blt $t9, 500, HaveSP
	bge $t9, 500, AllSpecial
		
	AllNormal:
	li $a0, 0
	li $a1, 1
	j StartGenerating
	
	HaveFP:
	li $a0, 0
	li $a1, 8
	j StartGenerating
	
	HaveMP:
	li $a0, 0
	li $a1, 9
	j StartGenerating
	
	HaveSP:
	li $a0, 0
	li $a1, 10
	j StartGenerating
	
	AllSpecial:
	li $a0, 0
	li $a1, 10
	syscall
	addi $a0, $a0, 7
	j AllSpecialGenerating
	
	
	StartGenerating:
	syscall
	AllSpecialGenerating:
	beq $a0, 8, GenerateMovingPlatform
	beq $a0, 11, GenerateMovingPlatform
	beq $a0, 12, GenerateMovingPlatform
	beq $a0, 9, GenerateFragilePlatform
	beq $a0, 7, GenerateShrinkingPlatform
	beq $a0, 13, GenerateShrinkingPlatform
	beq $a0, 14, GenerateShrinkingPlatform
	beq $a0, 10, GenerateDeadlyPlatform
	sw $s2, ($t0)
	move $s7, $s2  
	j PlatformLoop
	
	GenerateMovingPlatform:
	li $v0, 42
	li $a0, 0
	li $a1, 2
	syscall
	beq $a0, 1, GenerateMovingLeftPlatform
	beq $a0, 0, GenerateMovingRightPlatform
	
	GenerateMovingLeftPlatform:
	lw $s7, ($s6)
	sw $s7, ($t0)
	li $a0, 0
	StoreMLP:
	lw $t6, MLPlatforms($a0)
	beq $t6, -1, StoreMLPDone
	addi $a0, $a0, 4
	j StoreMLP
	StoreMLPDone:
	sw $t0, MLPlatforms($a0)
	j PlatformLoop
	
	GenerateMovingRightPlatform:
	lw $s7, 12($s6)
	sw $s7, ($t0)
	li $a0, 0
	StoreMRP:
	lw $t6, MRPlatforms($a0)
	beq $t6, -1, StoreMRPDone
	addi $a0, $a0, 4
	j StoreMRP
	StoreMRPDone:
	sw $t0, MRPlatforms($a0)
	j PlatformLoop
	
	GenerateFragilePlatform:
	lw $s7, 4($s6)
	sw $s7, ($t0)  
	
	j PlatformLoop
	
	GenerateShrinkingPlatform:
	lw $s7, 8($s6)
	sw $s7, ($t0)  
	li $a0, 0
	StoreSP:
	lw $t6, SPlatforms($a0)
	beq $t6, -1, StoreSPDone
	addi $a0, $a0, 4
	j StoreSP
	StoreSPDone:
	sw $t0, SPlatforms($a0)
	j PlatformLoop
	
	GenerateDeadlyPlatform:
	lw $s7, 16($s6)
	sw $s7, ($t0)  
	
	j PlatformLoop
	
	
	PlatformLoop:
	beq $t1, $t4, GenerateRocket  # Setting the length of the platform.
	sw $s7, ($t0) 
	# Generate the Spring with the probability 1/60 inside the PlatformLoop
	li $v0, 42
	li $a0, 0
	li $a1, 60
	syscall
	bne $a0, 0, NoSpring
	sw $s4, ($t0)
	NoSpring:
	addi $t0, $t0, 4
	addi $t1, $t1, 1
	j PlatformLoop
	
	GenerateRocket:
	# Generate the Rocket with the probability 1/50 with the row
	la $a0, 7936($t8)
	bge $t2, $a0, GenerateRocketDone
	li $v0, 42
	li $a0, 0
	li $a1, 50
	syscall
	bne $a0, 0, GenerateRocketDone
	li $v0, 42
	li $a0, 0
	li $a1, 30
	syscall
	addi $a0, $a0, 1
	sll $a0, $a0, 2
	add $a0, $t2, $a0
	sw $s5, ($a0)
	sw $s5, 124($a0)
	sw $s5, 128($a0)
	sw $s5, 132($a0)
	
	GenerateRocketDone:
	
	GenerateObstacle:
	# Generate the Rocket with the probability 1/50 with the row
	blt $t9, 200, GenerateObstacleDone
	li $v0, 42
	li $a0, 0
	li $a1, 50
	syscall
	bne $a0, 0, GenerateObstacleDone
	li $v0, 42
	li $a0, 0
	li $a1, 30
	syscall
	addi $a0, $a0, 1
	sll $a0, $a0, 2
	add $a0, $t2, $a0
	lw $s7, 16($s6)
	sw $s7, ($a0)
	sw $s7, 4($a0)
	sw $s7, 124($a0)
	sw $s7, 128($a0)
	sw $s7, 132($a0)
	sw $s7, 136($a0)
	sw $s7, 256($a0)
	sw $s7, 260($a0)
	
	GenerateObstacleDone:
	jr $ra	


TouchRocket:
	addi $t9, $t9, 100
	li $s1, 0xff5050
	li $k1, 150
	la $t7, 3968($t8)
	MoveToMiddle:
	blt $t3, $t7, ScrollScreen
	jal DeleteDoodler
	addi $t3, $t3, -128
	jal GenerateDoodler
	li $v0,32
	li $a0,5
	syscall
	j MoveToMiddle
	
	
	j ScrollScreen



Touchspring:
	addi $t9, $t9, 25
	la $t0, 256($t8)
	TouchspringLoop:		
		ble $t3, $t0, TouchspringLoopDone
		jal DeleteDoodler
		addi $t3, $t3, -128
		jal GenerateDoodler
		li $v0,32
		li $a0,5
		syscall
		j TouchspringLoop
	TouchspringLoopDone:
	li $k1, 32
	j ScrollScreen




TouchPlatform:

	# Get the number of rows to be scrolled ($k1)
	sub $k1, $t3, $t8
	srl $k1, $k1, 7
	addi $k1, $k1, 4	
	li $t6, 64
	sub $k1, $t6, $k1
	blt $k1, 20, CalculateCondition
	li $k1, 20

	# Calculate the score got for this Touch	
	# Idea:
	# The new score added decreases as the falling distance increases.
	
	# Calculation logic:
	# If  (# of rows traveled during this fall) < jumpHeight: 
	# 	Added score = jumpHeight - # of rows traveled during this fall
	# Else if (This platform is in the last row. You cannot gain any score by just let it continally jump back and forth in the last row):
	#	Added score = 0
	# Else:  (i.e. This platform is high in the screen, still causing the screen to scroll )
	#	Added score = 1
	
	CalculateCondition:
	bgt $t1, 0, CalculateScore
	li $t1, 1
	bne $k1, 0, CalculateScore
	li $t1, 0
	CalculateScore:
	add $t9, $t9, $t1
	li $t1, 0
	li $k0, 0
	j ShowScore	


ScrollScreen:
#Argument: $t3, $k1
	li $k0, 2
	lw $t7, 0xffff0000
	beq $t7, 1 , Keyboard_Scroll
	
	#addi $sp, $sp, -4
	#sw $ra, ($sp)
	
	
	
	ble $k1, 0, DoodlerRise
	la $t0, 6280($t8)
	la $t6, 6896($t8)
	TempDeleteScore:
		bgt $t0, $t6, TempDeleteScoreDone
		lw $s7, ($t0)
		bne $s7, $s3, SkipDelete
		sw $s0, ($t0)
		SkipDelete:
		addi $t0, $t0, 4
		j TempDeleteScore
	TempDeleteScoreDone:
	li $t6, 8188
		CopyLoop:
		blt $t6, 0, CopyLoopDone
		add $t0, $t8, $t6
		lw $s7, ($t0)
		beq $s7, $s4, CopyTheColour
		beq $s7, $s2, CopyTheColour
		beq $s7, $s5, CopyTheColour
		lw $a2, ($s6)
		beq $s7, $a2, CopyTheColour
		lw $a2, 16($s6)
		beq $s7, $a2, CopyTheColour
		lw $a2, 12($s6)
		beq $s7, $a2, CopyTheColour
		lw $a2, 4($s6)
		beq $s7, $a2, CopyTheColour
		lw $a2, 8($s6)
		beq $s7, $a2, CopyTheColour
		

		
		j CopyDone
	
	

	
		CopyTheColour:

		lw $s7, ($t0)			
		sw $s7, 128($t0)
		sw $s0, ($t0)
		
		j CopyDone
		

		j CopyDone
		

		CopyDone:
		addi $t6, $t6, -4
		
		j CopyLoop
		CopyLoopDone:
	
	jal GenerateDoodler
	
	# Update the Platform Arrays
	li $a0, 0
	li $a1, 40
	
	UpdateMLP:
	beq $a0, $a1, UpdateMLPDone
	lw $t6, MLPlatforms($a0)
	beq $t6, -1, NextUpdateMLP
	addi $t6, $t6, 128
	la $t7, 8188($t8)
	ble $t6, $t7, UpdatingOneMLP
	li $t6, -1
	UpdatingOneMLP:
	sw $t6, MLPlatforms($a0)
	
	NextUpdateMLP:
	addi $a0, $a0, 4
	j UpdateMLP
	UpdateMLPDone:
	
	
	li $a0, 0
	li $a1, 40
	
	UpdateMRP:
	beq $a0, $a1, UpdateMRPDone
	lw $t6, MRPlatforms($a0)
	beq $t6, -1, NextUpdateMRP
	addi $t6, $t6, 128
	la $t7, 8188($t8)
	ble $t6, $t7, UpdatingOneMRP
	li $t6, -1
	UpdatingOneMRP:
	sw $t6, MRPlatforms($a0)
	
	NextUpdateMRP:
	addi $a0, $a0, 4
	j UpdateMRP
	UpdateMRPDone:
	
	li $a0, 0
	li $a1, 40
	UpdateSP:
	beq $a0, $a1, UpdateSPDone
	lw $t6, SPlatforms($a0)
	beq $t6, -1, NextUpdateSP
	addi $t6, $t6, 128
	la $t7, 8188($t8)
	ble $t6, $t7, UpdatingOneSP
	li $t6, -1
	UpdatingOneSP:
	sw $t6, SPlatforms($a0)
	
	NextUpdateSP:
	addi $a0, $a0, 4
	j UpdateSP
	UpdateSPDone:
	
	#SupplementPlatforms:
	li $v0, 42
	li $a0, 0
	li $a1, 5
	syscall
	move $t7, $a0
		
	bne $t7, 0, SupplementDone
	la $t2, ($t8)
	jal GeneratePlatform
	

	SupplementDone:
	addi $k1, $k1, -1

	j ScrollScreen


GetSleepTime:
#Input: $t1 --> from the loop in PlayGame
#Output: $t7 = sleep time

	# Idea:
	# Sleep time increases as the Doodler's height increases. (Applicable for both rise and fall)
	# This motion is uniformly accelerated, so Sleep time growth should be geometric.
	
	# Sleep time logic:
	# H = Doodler's current height respect to the previous platform
	# Sleep time = [Constant number] * 1.25^H
		
	li $t0, 0
	blt $t9, 50, SpeedA
	blt $t9, 100, SpeedB
	blt $t9, 200, SpeedC
	blt $t9, 500, SpeedD
	bge $t9, 500, SpeedE
	
	SpeedA:
	li $t7, 10
	j GetSleepTimeLoop
	
	SpeedB:
	li $t7, 8
	j GetSleepTimeLoop
	
	SpeedC:
	li $t7, 6
	j GetSleepTimeLoop
	
	SpeedD:
	li $t7, 5
	j GetSleepTimeLoop
	
	SpeedE:
	li $t7, 4
	j GetSleepTimeLoop
	
	GetSleepTimeLoop:
	bge $t0, $t1, GetSleepTimeLoopDone
	
	# Let $t7 * 1.25 for each loop
	srl $t6, $t7, 2
	add $t7, $t7, $t6
	
	addi $t0, $t0, 1
	j GetSleepTimeLoop
	GetSleepTimeLoopDone:
	jr $ra


	
MoveMLPLeft:
#Argument: $t0 = 0
	bge $t0, 40, MoveMLPLeftDone
	lw $t6, MLPlatforms($t0)
	beq $t6, -1, NextMLPLeft

	sub $t7, $t6, $t8
	li $a2, 128
	div $t7, $a2
	mfhi $t7
	beq $t7,0, MoveMLPLeftMost
	move $t2, $t4
	sll $t2, $t2, 2
	sub $t2, $a2, $t2
	bgt $t7, $t2, MoveMLPLeftSplit
	
	
	addi $t6, $t6, -4
	lw $t2, ($s6)
	sw $t2, ($t6)
	move $t2, $t4
	sll $t2, $t2, 2
	add $t7, $t6, $t2
	sw $s0, ($t7)
	sw $t6, MLPlatforms($t0)
	j NextMLPLeft
	
	MoveMLPLeftMost:
	addi $t6, $t6, 124
	lw $t2, ($s6)
	sw $t2, ($t6)
	move $t2, $t4
	sll $t2, $t2, 2
	add $t7, $t6, $t2
	addi $t7, $t7, -128
	sw $s0, ($t7)
	sw $t6, MLPlatforms($t0)
	j NextMLPLeft
	
	MoveMLPLeftSplit:
	addi $t6, $t6, -4
	lw $t2, ($s6)
	sw $t2, ($t6)
	move $t2, $t4
	sll $t2, $t2, 2
	add $t7, $t6, $t2
	addi $t7, $t7, -128
	sw $s0, ($t7)
	sw $t6, MLPlatforms($t0)
	j NextMLPLeft
	
	
	
	NextMLPLeft:
	addi $t0, $t0, 4
	j MoveMLPLeft
	MoveMLPLeftDone:
	jr $ra	
	

MoveMRPRight:
#Argument: $a3 = 0
	bge $a3, 40, MoveMRPRightDone
	lw $t6, MRPlatforms($a3)
	beq $t6, -1, NextMRPRight

	sub $t7, $t6, $t8
	li $a2, 128
	div $t7, $a2
	mfhi $t7
	beq $t7,124, MoveMRPRightMost
	move $t2, $t4
	sll $t2, $t2, 2
	sub $t2, $a2, $t2
	bge $t7, $t2, MoveMRPRightSplit
	
	
	sw $s0, ($t6)	
	move $t2, $t4
	sll $t2, $t2, 2
	add $t7, $t6, $t2
	lw $t2, 12($s6)
	sw $t2, ($t7)
	addi $t6, $t6, 4
	
	
	sw $t6, MRPlatforms($a3)
	j NextMRPRight
	
	MoveMRPRightMost:
	sw $s0, ($t6)	
	move $t2, $t4
	sll $t2, $t2, 2
	add $t7, $t6, $t2
	addi $t7, $t7, -128
	lw $t2, 12($s6)
	sw $t2, ($t7)
	addi $t6, $t6, -124
	sw $t6, MRPlatforms($a3)
	j NextMRPRight
	
	MoveMRPRightSplit:
	sw $s0, ($t6)	
	move $t2, $t4
	sll $t2, $t2, 2
	add $t7, $t6, $t2
	addi $t7, $t7, -128
	lw $t2, 12($s6)
	sw $t2, ($t7)
	addi $t6, $t6, 4
	sw $t6, MRPlatforms($a3)
	j NextMRPRight
	
	
	
	NextMRPRight:
	addi $a3, $a3, 4
	j MoveMRPRight
	MoveMRPRightDone:
	jr $ra
							
						
BreakFP:
#Argument: $t3
	addi $t9, $t9, 5 
	sub $t2, $t3, $t8
	srl $t2, $t2, 7
	addi $t2, $t2, 3
	sll $t2, $t2, 7
	add $t2, $t2, $t8
	li $t6, 0
	DeleteFP:
	beq $t6, 128, DeleteFPDone
	add $t2, $t2, 4
	lw $s7, ($t2)
	lw $a2, 4($s6)
	bne $s7, $a2, NextDeleteFP
	sw $s0, ($t2)
	NextDeleteFP:
	addi $t6, $t6, 4
	j DeleteFP
	DeleteFPDone:
	j ShowScore
	
	
ShrinkSP:
#Argument: $t7 = 0
	bge $t7, 40, ShrinkSPDone
	lw $t6, SPlatforms($t7)
	beq $t6, -1, NextSP

	lw $s7, 4($t6)
	beq $s7, $s0, NewFullSP
	sw $s0, ($t6)
	addi $t6, $t6, 4
	j RecoverSPLoopDone
	
	NewFullSP:
	
	move $t2, $t4
	addi $t2, $t2, -1
	sll $t2, $t2, 2
	
	RecoverSPLoop:
	beq $t2, 0, RecoverSPLoopDone
	addi $t6, $t6, -4
	lw $s7, 8($s6)
	sw $s7, ($t6)
	addi $t2, $t2, -4
	j RecoverSPLoop
	RecoverSPLoopDone:
	sw $t6, SPlatforms($t7)
	j NextSP

	NextSP:
	addi $t7, $t7, 4
	j ShrinkSP
	ShrinkSPDone:
	jr $ra	
	
	
	
	
	
	
	
	
	
##############################################################################
# The essense of the game flow applies here. (PlayGame label)
##############################################################################												
PlayGame:
	
	li $t1, 0
	
	DoodlerRise:
	li $k0,0
	li $s1, 0x0066ff

	bge $t1, $t5, DoodlerFall
	
	
	
	lw $t7, 0xffff0000
	beq $t7, 1 , Keyboard_Rise
	
	la $t0, 128($t8)
	ble $t3, $t0, DoodlerFall
	
	# Move the whole Doodler up for 1 unit
	jal DeleteDoodler
	addi $t3, $t3, -128
	jal GenerateDoodler
	
	# Milestone 5a implements here
	jal GetSleepTime
	Sleep:
	li $v0,32
	move $a0, $t7
	syscall
	
	li $t0, 0
	jal MoveMLPLeft
	li $a3, 0
	jal MoveMRPRight
	li $t7, 0
	jal ShrinkSP
	
	
	
	
	
	addi $t1, $t1, 1
	
	j ShowScore
	j DoodlerRise

	DoodlerFall:
	
	li $k0, 1
	li $s1, 0x0066ff
	lw $t7, 0xffff0000
	beq $t7, 1 , Keyboard_Fall
	
	beq $k1, 0, StartFall
	jal ScrollScreen
	
	StartFall:
	jal DeleteDoodler
	addi $t3, $t3, 128
	jal GenerateDoodler
	
	# Milestone 5a implements here
	jal GetSleepTime
	li $v0,32
	move $a0, $t7
	syscall

	li $t0, 0
	jal MoveMLPLeft
	li $a3, 0
	jal MoveMRPRight
	li $t7, 0
	jal ShrinkSP
	
	la $t0, 7808($t8)
	bge $t3, $t0, GameOver
	
	
	#Justify if Doodler is in left-most position or right-most position
	addi $t1, $t1, -1
	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 0, TouchLeftMost
	beq $a2, 124, TouchRightMost 
	
	
	lw $t0, 380($t3)	
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	lw $t0, 384($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	lw $t0, 388($t3)
	la $a2, 388($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	beq $t0, $s2, TouchPlatform
	lw $s7, ($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 12($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 8($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 4($s6)
	beq $t0, $s7, BreakFP
	
	lw $t0, 380($t3)
	la $a2, 380($t3)
	beq $t0, $s2, TouchPlatform
	lw $s7, ($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 12($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 8($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 4($s6)
	beq $t0, $s7, BreakFP
	
	j ShowScore
	j DoodlerFall
	
	TouchLeftMost:
	lw $t0, 508($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	
	lw $t0, 384($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	lw $t0, 388($t3)
	la $a2, 388($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	beq $t0, $s2, TouchPlatform
	lw $s7, ($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 12($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 8($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 4($s6)
	beq $t0, $s7, BreakFP
	
	lw $t0, 508($t3)
	la $a2, 508($t3)
	beq $t0, $s2, TouchPlatform	
	lw $s7, ($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 12($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 8($s6)
	beq $t0, $s7, TouchPlatform
	
	lw $s7, 4($s6)
	beq $t0, $s7, BreakFP
	
	j ShowScore
	j DoodlerFall
	
	TouchRightMost:
	lw $t0, 380($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	
	lw $t0, 384($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	lw $t0, 260($t3)
	la $a2, 260($t3)
	beq $t0, $s4, Touchspring
	beq $t0, 0x5f5f5e, Touchspring
	beq $t0, $s2, TouchPlatform
	lw $s7, ($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 12($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 8($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 4($s6)
	beq $t0, $s7, BreakFP
	
	lw $t0, 380($t3)
	la $a2, 380($t3)
	beq $t0, $s2, TouchPlatform
	lw $s7, ($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 12($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 8($s6)
	beq $t0, $s7, TouchPlatform
	lw $s7, 4($s6)
	beq $t0, $s7, BreakFP	
	
	j ShowScore
	j DoodlerFall






##############################################################################
# Keyboard inputs
##############################################################################		

Keyboard_Scroll:
	lw $t6, 0xffff0004
	beq $t6, 0x6a, MoveLeft_Scroll
	beq $t6, 0x6b, MoveRight_Scroll
	j MoveDone_Scroll

	MoveLeft_Scroll:
		
	jal DeleteDoodler

	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 0, MoveLeftMost_Scroll
		
	addi $t3, $t3, -4
	j MoveDone_Scroll
	
	MoveLeftMost_Scroll:
	addi $t3, $t3, 124
	j MoveDone_Scroll
	
	MoveRight_Scroll:
	
	jal DeleteDoodler

	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 124, MoveRightMost_Scroll
		
	addi $t3, $t3, 4
	j MoveDone_Scroll
	
	MoveRightMost_Scroll:
	addi $t3, $t3, -124
	j MoveDone_Scroll
	
	MoveDone_Scroll:

	jal GenerateDoodler
	add $t7, $zero, $zero
	j ScrollScreen


		
Keyboard_Fall:
	lw $t6, 0xffff0004
	beq $t6, 0x6a, MoveLeft_Fall
	beq $t6, 0x6b, MoveRight_Fall
	beq $t6, 0x73, GenerateHelperSpring_Fall
	j MoveDone_Fall

	MoveLeft_Fall:
	jal DeleteDoodler
	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 0, MoveLeftMost_Fall
		
	addi $t3, $t3, -4
	j MoveDone_Fall
	
	MoveLeftMost_Fall:
	addi $t3, $t3, 124
	j MoveDone_Fall
	
	MoveRight_Fall:
	jal DeleteDoodler
	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 124, MoveRightMost_Fall
		
	addi $t3, $t3, 4
	j MoveDone_Fall
	
	MoveRightMost_Fall:
	addi $t3, $t3, -124
	j MoveDone_Fall
	
	MoveDone_Fall:
	jal GenerateDoodler
	add $t7, $zero, $zero
	j DoodlerFall
	
	GenerateHelperSpring_Fall:
	sw $s4, 8124($t8)
	j DoodlerFall
	
Keyboard_Rise:
	lw $t6, 0xffff0004
	beq $t6, 0x6a, MoveLeft_Rise
	beq $t6, 0x6b, MoveRight_Rise
	beq $t6, 0x73, GenerateHelperSpring_Rise
	j MoveDone_Rise

	MoveLeft_Rise:
	jal DeleteDoodler
	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 0, MoveLeftMost_Rise
		
	addi $t3, $t3, -4
	j MoveDone_Rise
	
	MoveLeftMost_Rise:
	addi $t3, $t3, 124
	j MoveDone_Rise
	
	MoveRight_Rise:
	jal DeleteDoodler
	sub $a2, $t3, $t8
	li $t6, 128
	div $a2, $t6
	mfhi $a2
	beq $a2, 124, MoveRightMost_Rise
		
	addi $t3, $t3, 4
	j MoveDone_Rise
	
	MoveRightMost_Rise:
	addi $t3, $t3, -124
	j MoveDone_Rise
	
	MoveDone_Rise:
	jal GenerateDoodler
	add $t7, $zero, $zero
	j DoodlerRise
	
	GenerateHelperSpring_Rise:
	sw $s4, 8124($t8)
	j DoodlerRise
	

Keyboard_Restart:
	lw $t6, 0xffff0004
	beq $t6, 0x61, NoRestart  #Press a to completely end the game
	bne $t6, 0x73, GameOver #Press s to restart the game
	j InitialDataSet

	
GameOver:
	li $k0, 3
	j ShowScore
	GameOverMessage:
	li $s7, 0xff0000
	sw $s7, 2328($t8)
sw $s7, 2332($t8)
sw $s7, 2336($t8)
sw $s7, 2340($t8)
sw $s7, 2352($t8)
sw $s7, 2356($t8)
sw $s7, 2368($t8)
sw $s7, 2372($t8)
sw $s7, 2380($t8)
sw $s7, 2384($t8)
sw $s7, 2392($t8)
sw $s7, 2396($t8)
sw $s7, 2400($t8)
sw $s7, 2404($t8)
sw $s7, 2456($t8)
sw $s7, 2476($t8)
sw $s7, 2488($t8)
sw $s7, 2496($t8)
sw $s7, 2504($t8)
sw $s7, 2512($t8)
sw $s7, 2520($t8)
sw $s7, 2584($t8)
sw $s7, 2604($t8)
sw $s7, 2616($t8)
sw $s7, 2624($t8)
sw $s7, 2632($t8)
sw $s7, 2640($t8)
sw $s7, 2648($t8)
sw $s7, 2652($t8)
sw $s7, 2656($t8)
sw $s7, 2660($t8)
sw $s7, 2712($t8)
sw $s7, 2720($t8)
sw $s7, 2724($t8)
sw $s7, 2732($t8)
sw $s7, 2736($t8)
sw $s7, 2740($t8)
sw $s7, 2744($t8)
sw $s7, 2752($t8)
sw $s7, 2760($t8)
sw $s7, 2768($t8)
sw $s7, 2776($t8)
sw $s7, 2840($t8)
sw $s7, 2852($t8)
sw $s7, 2860($t8)
sw $s7, 2872($t8)
sw $s7, 2880($t8)
sw $s7, 2888($t8)
sw $s7, 2896($t8)
sw $s7, 2904($t8)
sw $s7, 2968($t8)
sw $s7, 2972($t8)
sw $s7, 2976($t8)
sw $s7, 2980($t8)
sw $s7, 2988($t8)
sw $s7, 3000($t8)
sw $s7, 3008($t8)
sw $s7, 3016($t8)
sw $s7, 3024($t8)
sw $s7, 3032($t8)
sw $s7, 3036($t8)
sw $s7, 3040($t8)
sw $s7, 3044($t8)
sw $s7, 3224($t8)
sw $s7, 3228($t8)
sw $s7, 3232($t8)
sw $s7, 3236($t8)
sw $s7, 3244($t8)
sw $s7, 3256($t8)
sw $s7, 3264($t8)
sw $s7, 3268($t8)
sw $s7, 3272($t8)
sw $s7, 3276($t8)
sw $s7, 3284($t8)
sw $s7, 3288($t8)
sw $s7, 3292($t8)
sw $s7, 3296($t8)
sw $s7, 3352($t8)
sw $s7, 3364($t8)
sw $s7, 3372($t8)
sw $s7, 3384($t8)
sw $s7, 3392($t8)
sw $s7, 3412($t8)
sw $s7, 3424($t8)
sw $s7, 3480($t8)
sw $s7, 3492($t8)
sw $s7, 3500($t8)
sw $s7, 3512($t8)
sw $s7, 3520($t8)
sw $s7, 3524($t8)
sw $s7, 3528($t8)
sw $s7, 3532($t8)
sw $s7, 3540($t8)
sw $s7, 3552($t8)
sw $s7, 3608($t8)
sw $s7, 3620($t8)
sw $s7, 3628($t8)
sw $s7, 3640($t8)
sw $s7, 3648($t8)
sw $s7, 3668($t8)
sw $s7, 3672($t8)
sw $s7, 3676($t8)
sw $s7, 3736($t8)
sw $s7, 3748($t8)
sw $s7, 3756($t8)
sw $s7, 3768($t8)
sw $s7, 3776($t8)
sw $s7, 3796($t8)
sw $s7, 3808($t8)
sw $s7, 3864($t8)
sw $s7, 3868($t8)
sw $s7, 3872($t8)
sw $s7, 3876($t8)
sw $s7, 3888($t8)
sw $s7, 3892($t8)
sw $s7, 3904($t8)
sw $s7, 3908($t8)
sw $s7, 3912($t8)
sw $s7, 3916($t8)
sw $s7, 3924($t8)
sw $s7, 3936($t8)



	
	lw $t7, 0xffff0000
	beq $t7, 1 , Keyboard_Restart
	j GameOver
	
	NoRestart:
	move $a0, $t9
	li $v0, 1
	syscall
	
	li $v0, 4 	                
	la $a0, newline      
	syscall
	

	# Terminate the program gracefully
	li $v0, 10 
	syscall
