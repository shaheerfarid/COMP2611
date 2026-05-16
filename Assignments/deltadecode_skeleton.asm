# Your name:
# Your student id:
# Your email address:

.data
    # output messages
    initMsg: .asciiz "Please enter integers in delta array delta[] one by one, use [Enter] to split:\n"
    EnterNumberMsg1: .asciiz "delta["
    EnterNumberMsg2: .asciiz "]: "
    OutputMsg1: .asciiz "The decoded array A[] is: "
    space: .asciiz " "
    newLine: .asciiz "\n"

    # delta[] has space for 100 elements (word each)
    delta: .word 0:100
    A_SIZE: .word 10 # actual number of elements in delta[]

.text
.globl main

main:
    la   $s0, delta        # $s0 = base address of delta[]
    lw   $s1, A_SIZE       # $s1 = A_SIZE (=10)

    # Print initial prompt
    la   $a0, initMsg
    li   $v0, 4
    syscall

    # for (i=0; i<A_SIZE; i++) read delta[i]
    li   $t0, 0            # i = 0
input_array:
    beq  $t0, $s1, exit_input

    # print "delta["
    la   $a0, EnterNumberMsg1
    li   $v0, 4
    syscall

    # print i
    move $a0, $t0
    li   $v0, 1
    syscall

    # print "]: "
    la   $a0, EnterNumberMsg2
    li   $v0, 4
    syscall

    # read integer
    li   $v0, 5
    syscall

    # store into delta[i]
    sll  $t1, $t0, 2       # offset = i*4
    add  $t1, $s0, $t1     # addr = base + offset
    sw   $v0, 0($t1)

    addi $t0, $t0, 1
    j    input_array

exit_input:
    # Call DeltaDecoding(delta, A_SIZE)
    move $a0, $s0          # base address of delta[]
    move $a1, $s1          # size = 10
    jal  DeltaDecoding

    # Print output message
    la   $a0, OutputMsg1
    li   $v0, 4
    syscall

    # Print decoded array (delta[] is now A[])
    li   $t0, 0            # i = 0
print_loop:
    beq  $t0, $s1, exit_print

    sll  $t1, $t0, 2
    add  $t1, $s0, $t1
    lw   $a0, 0($t1)

    li   $v0, 1            # print integer
    syscall

    la   $a0, space        # print space after each integer
    li   $v0, 4
    syscall

    addi $t0, $t0, 1
    j    print_loop

exit_print:
    la   $a0, newLine
    li   $v0, 4
    syscall

    li   $v0, 10
    syscall

# ------------------------------------------------------------
# DeltaDecoding (in-place)
# Arguments:
#   $a0 = base address of delta[]
#   $a1 = A_SIZE  (i.e. size of A[])
# Effect:
#   When the function returns, delta[] becomes the decoded array A[], and holds the values of A[]
#
# preserve registers as needed according to slide 76 of the ISA note set
# add labels as you wish
# ------------------------------------------------------------
DeltaDecoding:
#TODO BELOW
    addi $t0, $zero, 1   # i = 1 (use $t0 instead of $s0)
    
Loop:
    slt  $t1, $t0, $a1   # i < A_SIZE?
    beq  $t1, $zero, exit
    
    sll  $t2, $t0, 2     # i * 4
    add  $t3, $a0, $t2   # &delta[i]
    lw   $t4, 0($t3)     # delta[i]
    lw   $t5, -4($t3)    # delta[i-1]
    add  $t4, $t4, $t5   # delta[i] = delta[i-1] + delta[i]
    sw   $t4, 0($t3)     # store back
    
    addi $t0, $t0, 1     # i++
    j    Loop
exit:
#TODO ABOVE
     jr   $ra # the last line of DeltaDecoding function
