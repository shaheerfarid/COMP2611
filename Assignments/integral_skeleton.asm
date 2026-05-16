.data
msgEnterN:    .asciiz "Enter the number of rows N: "
msgEnterM:    .asciiz "Enter the number of columns M: "
msgEnterA:    .asciiz "Enter the input image A in row-major order:\n"

InputMsg1:    .asciiz "A["
InputMsg2:    .asciiz "]["
InputMsg3:    .asciiz "]: "

OutMsgInit:   .asciiz "The initial matrix is \n"
msgOut:       .asciiz "Here is the integral image S:\n"

space1:       .asciiz " "
newline:      .asciiz "\n"

A: .word 0:100
S: .word 0:121

.text
.globl main

main:
    la   $s0, A              # base A
    la   $s3, S              # base S

    # Read N
    la   $a0, msgEnterN
    li   $v0, 4
    syscall
    li   $v0, 5
    syscall
    move $s1, $v0            # N

    # Read M
    la   $a0, msgEnterM
    li   $v0, 4
    syscall
    li   $v0, 5
    syscall
    move $s2, $v0            # M

    # Prompt for A
    la   $a0, msgEnterA
    li   $v0, 4
    syscall

    # Input A[i][j] with 1-based display indices
    li   $t0, 0              # i (0-based internal)
read_i:
    beq  $t0, $s1, read_done
    li   $t1, 0              # j (0-based internal)
read_j:
    beq  $t1, $s2, next_i

    # print "A[" << (i+1) << "][" << (j+1) << "]: "
    la   $a0, InputMsg1
    li   $v0, 4
    syscall

    addi $a0, $t0, 1         # i+1
    li   $v0, 1
    syscall

    la   $a0, InputMsg2
    li   $v0, 4
    syscall

    addi $a0, $t1, 1         # j+1
    li   $v0, 1
    syscall

    la   $a0, InputMsg3
    li   $v0, 4
    syscall

    # read value
    li   $v0, 5
    syscall
    move $t2, $v0

    # idx = multiply(i, M) + j   (0-based storage)
    move $a0, $t0
    move $a1, $s2
    jal  multiply             # v0 = i*M
    addu $t3, $v0, $t1        # idx
    sll  $t3, $t3, 2
    addu $t3, $t3, $s0
    sw   $t2, 0($t3)

    addi $t1, $t1, 1
    j    read_j

next_i:
    addi $t0, $t0, 1
    j    read_i

read_done:
    # Print initial matrix
    la   $a0, OutMsgInit
    li   $v0, 4
    syscall

    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    jal  print2DMatrix

    # Build integral image
    move $a0, $s0
    move $a1, $s3
    move $a2, $s1
    move $a3, $s2
    jal  integral

    # Print integral image
    la   $a0, msgOut
    li   $v0, 4
    syscall

    move $a0, $s3
    addi $a1, $s1, 1
    addi $a2, $s2, 1
    jal  print2DMatrix

    li   $v0, 10
    syscall

############################################################
# int multiply(int a, int b)
# inputs: $a0=a, $a1=b
# output: $v0=a*b by repeated addition
# uses only $t9 as temp to avoid clobbering callers
# assumption: a, b both non-negative
############################################################
multiply:
    li   $t9, 0
    li   $v0, 0
mul_loop:
    beq  $t9, $a1, mul_done
    addu $v0, $v0, $a0
    addi $t9, $t9, 1
    j    mul_loop
mul_done:
    jr   $ra


############################################################
# void print2DMatrix(const int X[], int R, int C)
# $a0=base, $a1=R, $a2=C
# Format: single spaces between numbers, no trailing spaces, newline per row
############################################################
print2DMatrix:
    addi $sp, $sp, -24
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)

    move $s0, $a0       # base
    move $s1, $a1       # R
    move $s2, $a2       # C

    li   $s3, 0         # i
p_i:
    beq  $s3, $s1, p_end
    li   $s4, 0         # j
p_j:
    beq  $s4, $s2, p_nl

    beq  $s4, $zero, p_no_sp
    la   $a0, space1
    li   $v0, 4
    syscall
p_no_sp:

    # idx = multiply(i, C) + j
    move $a0, $s3
    move $a1, $s2
    jal  multiply
    addu $t0, $v0, $s4
    sll  $t0, $t0, 2
    addu $t0, $t0, $s0
    lw   $a0, 0($t0)
    li   $v0, 1
    syscall

    addi $s4, $s4, 1
    j    p_j

p_nl:
    la   $a0, newline
    li   $v0, 4
    syscall
    addi $s3, $s3, 1
    j    p_i

p_end:
    lw   $ra, 0($sp)
    lw   $s0, 4($sp)
    lw   $s1, 8($sp)
    lw   $s2, 12($sp)
    lw   $s3, 16($sp)
    lw   $s4, 20($sp)
    addi $sp, $sp, 24
    jr   $ra


# ------------------------------------------------------------
# This function does the same thing as the function integral() in the C++ program
# void integral(const int A[], int S[], int N, int M)
# $a0 = A[] base addr, $a1 = S[] base addr, $a2 = N, $a3 = M
#
# preserve registers as needed according to slide 76 of the ISA note set
# add labels as you wish
# ------------------------------------------------------------
integral:
#TODO BELOW

    # Frame size = 28 bytes (7 words): ra, s0, s1, s2, s3, s4, s5
    addi $sp, $sp, -28
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)
    sw   $s5, 24($sp)

# save important inputs into callee-saved registers
    move $s3, $a0        # $s3 = base of A
    move $s4, $a1        # $s4 = base of S

    addi $s0, $a3, 1     # $s0 = SM = M+1

    addi $t0, $zero, 0 # t0/j = 0
Loop0:
    slt $t1, $t0, $s0 # t2 = 1 if j < (M+1)
    beq $t1, $zero, Endloop0 # if t2 == 0 exit

    sll $t2, $t0, 2 # $t3 = j * 4
    add $t3, $s4, $t2 # $t4 = &S[j]

    sw $zero, 0($t3) # Set S[j] = 0

    addi $t0, $t0, 1 # increment j
    j Loop0

Endloop0: 

    li $s1, 0 # i = 0
    addi $s2, $a2, 1 # s2 = N + 1

Loop1:
    slt $t0, $s1, $s2 # t0 = 1 if i < N+1
    beq $t0, $zero, Endloop1

    move $a0, $s1
    move $a1, $s0

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal multiply

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    sll $t1, $v0, 2
    add $t2, $s4, $t1

    sw $zero, 0($t2)

    addi $s1, $s1, 1
    j Loop1

Endloop1:

    li $s1, 1 # i = 1

Loop2:
    slt $t0, $s1, $s2 # t0 is 1 if i < N+1
    beq $t0, $zero, Endloop2

    li $s5, 1 # j = 1

Loop3:
    slt $t1, $s5, $s0 # t1 = 1 if j < M+1
    beq $t1, $zero, Endloop3

    sub $t2, $s1, 1 # t2 = i - 1
    sub $t3, $s5, 1 # t3 = j - 1

    move $a0, $t2 # t2 -> a0 (1st parameter in multiply), 2nd parameter M is stored in a3
    move $a1,$a3

    addi $sp, $sp, -4 # make space in the stack
    sw $ra, 0($sp)

    jal multiply # invoke the function 

    lw $ra, 0($sp) # get the address of ra back of the previous function
    addi $sp, $sp, 4

    add $t4, $v0, $t3 # aIdx = multiply(i-1, M) + (j-1)
    sll $t4, $t4, 2 # t4 was index, so multiply by 4 and add to the base address of A
    add $t5, $s3, $t4 
    lw $t4, 0($t5) # load A[aIdx] into $t4

    # saving t4 in the stack
    addi $sp, $sp, -4
    sw $t4, 0($sp)

    # on sIdx now Lessgoooo

    move $a0, $s1
    move $a1, $s0

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal multiply

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    add $t4, $v0, $s5 # int sIdx = multiply(i, SM) + j;
    sll $t4, $t4, 2
    add $t5, $s4, $t4 

    # storing S[sIdx] in the stack list
    addi $sp, $sp, -4
    sw $t5, 0($sp)

    #ong gng lets go to upIdx

    move $a0, $t2 # a0 = i - 1 and a1 already SM from last call but still write
    move $a1, $s0

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal multiply

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    add $t4, $v0, $s5 # int upIdx = multiply(i-1, SM) + j;
    sll $t4, $t4, 2
    add $t5, $s4, $t4 
    lw $t4, 0($t5)

    # storing S[upIdx] in the stack list
    addi $sp, $sp, -4
    sw $t4, 0($sp)

    # leftIdx

    move $a0, $s1
    move $a1, $s0

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal multiply

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    add $t4, $v0, $t3
    sll $t4, $t4, 2
    add $t5, $s4, $t4
    lw $t4, 0($t5)

    # storing S[leftIdx] in the stack list
    addi $sp, $sp, -4
    sw $t4, 0($sp)

    # diagIdx
    move $a0, $t2
    move $a1, $s0

    addi $sp, $sp, -4
    sw $ra, 0($sp)

    jal multiply

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    add $t4, $v0, $t3
    sll $t4, $t4, 2
    add $t5, $s4, $t4
    lw $t4, 0($t5)

    # storing S[diagIdx] in the stack list
    addi $sp, $sp, -4
    sw $t4, 0($sp)


    # now pop out values from the stack in reverse order

    # S[diagIdx]
    lw $t0, 0($sp)
    addi $sp, $sp, 4

    # S[leftIdx]
    lw $t1, 0($sp)
    addi $sp, $sp, 4

    #S[upIdx]
    lw $t2, 0($sp)
    addi $sp, $sp, 4

    # address of S[sIdx]
    lw $t3, 0($sp)
    addi $sp, $sp, 4

    # A[aIdx]
    lw $t4, 0($sp)
    addi $sp, $sp, 4

    add $t4, $t4, $t2
    add $t4, $t4, $t1
    sub $t4, $t4, $t0
    sw $t4, 0($t3) # S[sIdx] = A[aIdx] + S[upIdx] + S[leftIdx] - S[diagIdx]

    addi $s5, $s5, 1 #s5++

    j Loop3 #jump to the loop3

Endloop3:

    addi $s1, $s1, 1
    j Loop2

Endloop2:

    lw   $s5, 24($sp)
    lw   $s4, 20($sp)
    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 28
#TODO ABOVE
    jr   $ra # last line of integral()

