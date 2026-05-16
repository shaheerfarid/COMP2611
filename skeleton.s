##
# Your student ID: 21119751
# Your name: Muhammad Shaheer Bin Farid
# Your email: msbfarid@connect.ust.hk
##
.data
##
# A 1D array representing each tile in the Minesweeper game.
# The size of the board is 16 x 16, and each tile consists of
# four words in sequence. As a reminder, each word consists of 4-bytes.
#
# The first three words of a tile are as follows:
# row: a 4-byte variable representing the row of the tile
# col: a 4-byte representing the column of the title
# neighbourMines: a 4-byte variable storing the number of adjacent mines of a given tile
#
# Since the following three variables are boolean variables, they are packed into a single word
# in the interest of efficiency (though this is still rather wasteful; see below).
# The first 29 bits are leading zeros (you can use this for other purposes if you wish).
# The last three bits are as follows:
# isRevealed: A single bit representing whether the tile is revealed.
# hasMine: A single bit representing whether the tile has a mine.
# hasFlag: A single bit representing whether the tile has been manually flagged by the player.
# You should use bit operations to extract the relevant bits.
#
# As an example, if isRevealed is true, hasMined is false, and hasFlag is true,
# the last word will look like this (spaces added for clarity):
# 00000000 0000000 00000000 00000101
#
# Tiles are laid out in row-major order (i.e. tiles[0] is the first element in the first row,
# tiles[1] is the second element in the first row, and tiles[16] is the first element in the second row).
##
tiles: .word 0:1024

action: .word 0 # Whether the user's click is a left or right click; 0 = left clicked; 1 = right click
rowClicked: .word 0 # The clicked row
colClicked: .word 0 # The clicked column
##
# A number representing the current status of the game.
# 0: Lost
# 1: Won
# 2: Continue
##
curStatus: .word 0

.text
jal setSeed
li $v0, 200 # Setup window (we know that the array should be all zeros)
syscall

la $a0, tiles
li $v0, 201 # Force a render
syscall

##
# The main loop of the game.
##
mainLoop:
    jal initBoard
    jal addMines
    jal updateNeighbourCount
    
    la $a0, tiles # obtain the starting address
    li $v0, 201 # Render
    syscall
    mainGameLoop:
        li $v0, 202 # Suspend until input
        syscall

        beq $v0, $zero, endMainLoop # Safety for closed window

        li $v0, 203 # Get click type
        syscall
        la $t0, action
        sw $v0, 0($t0)

        li $v0, 204 # Get click position
        syscall
        la $t0, rowClicked
        la $t1, colClicked
        sw $v0, 0($t0)
        sw $v1, 0($t1)

        li $t1, 1
        lw $t2, action
        beq $t2, $t1, rightClick
            jal handleLeftClick
            j endClick
        rightClick:
            jal handleRightClick
        endClick:

        la $a0, tiles
        li $v0, 201 # Render
        syscall

        li $t0, 2
        lw $t1, curStatus
        beq $t0, $t1, mainGameLoop

        # Either won or lost
        addi $a0, $t1, 0
        li $v0, 205 # Continue / Reset dialogue
        syscall

        beq $v0, $zero, mainLoop # NOT mainGameLoop; this resets the board
        j endMainLoop
    endMainGameLoop:
    j mainLoop
endMainLoop:
j exitGame

##
# Sets the seed of the random number generator.
# Useful for reproducing a specific map.
# By default, this is commented out to make the game random each time.
# During testing and / or grading, this will be set to a specific value such that we can grade your code deterministically.
#
# Do NOT modify this block (except by uncommenting the statements).
# Otherwise, the autograder may fail to grade your code.
##
setSeed:
  li $a0, 0 # The 0th random number generator
  # li $a1, 2012 # The seed; can be any value
  li $v0, 40
  syscall
  jr $ra
endSetSeed:

##
# (Re)-initializes the board, setting all relevant words to zero.
# This is necessary because we might come back to this if the player decides to restart.
#
# $s0 = row idx
# $s1 = col idx
# $s2 = row max = col max = 16
# $s3 = current tile base offset
##
initBoard:
    # Store return address
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp)
    sw $s1, 24($sp)
    sw $s2, 20($sp)
    sw $s3, 16($sp)
    sw $s4, 12($sp)
    sw $s5, 8($sp)
    sw $s6, 4($sp)
    sw $s7, 0($sp)
    
    li $s0, 0
    li $s2, 16
    initRow:
        beq $s0, $s2, endInitRow
        li $s1, 0
        initCol:
            beq $s1, $s2, endInitCol

            addi $a0, $s0, 0
            addi $a1, $s1, 0
            jal getTileAddr

            addi $s3, $v0, 0

            li $t0, 0
            sw $s0, 0($s3)
            sw $s1, 4($s3)
            sw $t0, 8($s3)
            sw $t0, 12($s3)

            addi $s1, $s1, 1
            j initCol
        endInitCol:

        addi $s0, $s0, 1
        j initRow
    endInitRow:

    # Reload the registers
    lw $s7, 0($sp)
    lw $s6, 4($sp)
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra
endInitBoard:

##
# Adds the mines to the board in a loop.
#
# $s0: The number of mines to place (40).
# $s1: The number of currently placed mines.
# $s2: Randomly generated row index.
# $s3: Randomly generated column index.
# $s5: Base address of current tile.
##
addMines:
    # Store return address
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp)
    sw $s1, 24($sp)
    sw $s2, 20($sp)
    sw $s3, 16($sp)
    sw $s4, 12($sp)
    sw $s5, 8($sp)
    sw $s6, 4($sp)
    sw $s7, 0($sp)

    li $s0, 40
    li $s1, 0
    addMineLoop:
        beq $s0, $s1, endAddMineLoop

        li $a0, 0
        li $a1, 16 # Number of rows
        li $v0, 42
        syscall

        addi $s3, $a0, 0

        li $a0, 0
        li $a1, 16 # Number of columns
        li $v0, 42
        syscall

        addi $s4, $a0, 0

        addi $a0, $s3, 0
        addi $a1, $s4, 0
        jal getTileAddr

        addi $s5, $v0, 0

        lw $a0, 12($s5)
        li $a1, 1
        jal getBit

        addi $t0, $v0, 0
        li $t1, 1

        beq $t0, $t1, addMineLoop # Already taken; skip and retry

        # We know that it must be x0x, so direct addition is fine
        lw $t0, 12($s5) # Reload
        addi $t0, $t0, 2 # Equivalent to setting that specific bit (add ...10)
        sw $t0, 12($s5)

        addi $s1, $s1, 1
        j addMineLoop
    endAddMineLoop:
    # Reload the registers
    lw $s7, 0($sp)
    lw $s6, 4($sp)
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra
endAddMines:

##
# Updates the neighbour counts of each tile.
##
updateNeighbourCount:
    # Complete task 1 here!
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp) # s0 = max rows == max columns == 16
    sw $s1, 24($sp) # s1 = current tile base offset
    sw $s2, 20($sp) # s2 = row idx
    sw $s3, 16($sp) # s3 = col idx
    sw $s4, 12($sp) # s6 = current neighbour count
    # sw $s4, 12($sp) # s4 = new row idx
    # sw $s5, 8($sp) # s5 = new col idx

    li $s0, 16
    li $s2 , 0 # current row is 0

    outerloop:
        beq $s2, $s0, endOuterLoop # if row == 16 exit loop
        li $s3 , 0 # current col = 0

        innerLoop0:
            beq $s3, $s0, nextOuter0 # if col == 16 exit loop
            move $a0, $s2 # first argument for getTileAddr a0 = row
            move $a1, $s3 # second argument for getTileAddr a1 = col

            jal getTileAddr
            move $s1, $v0 #copying the returned address of the current Tile

            lw $a0, 12($s1)
            li $a1, 1 
            jal getBit #find whether the tile contains mine or not 
            bne $v0, $zero, skipTile
            j continueTile

            skipTile:
                addi $s3, $s3, 1
                j innerLoop0
                
            continueTile:
                li $s4, 0 # setting the current neighbour count for each tile 0

                li $t0, -1 #set t0 as -1/ for the rows

                rowLoop:
                    slti $t1, $t0, 2 # set t1 as 1 if t0 < 2 / t0<=1
                    beq $t1, $zero, exitRowLoop
                    
                    li $t2, -1 #set t2 as -1/ for the columns

                    columnLoop:
                        slti $t1, $t2, 2 # set t1 as 1 if t2 < 2 / t2<=1
                        beq $t1, $zero, exitcolumnLoop

                        bne $t0, $zero, computeNeighbor   # if t0 != 0 → definitely a neighbour
                        bne $t2, $zero, computeNeighbor   # if t2 != 0 → also neighbour
                        j skipCurrentOffset               # only case left: t0 == 0 AND t2 == 0

                        computeNeighbor:
                            add $t3, $s2, $t0 # new row = t0 + old row
                            add $t4, $s3, $t2 # new col = t2 + old col
                            
                            #if new row < 0, jump to rowLoop and go for another value of the row
                            slti $t1, $t3, 0 # if newRow < 0, t1 = 1
                            bne $t1, $zero, skipCurrentOffset  # if t1 != zero , exit Current Offset

                            slti $t1, $t3, 16 # if new row >= 16, t1 = 0
                            beq $t1, $zero, skipCurrentOffset # if t1 == 0, exit Current offset

                            slti $t1, $t4, 0 # if newCol < 0, t1 = 1
                            bne $t1, $zero, skipCurrentOffset  # if t1 != zero , exit Current Offset

                            slti $t1, $t4, 16 # if new Col >= 16, t1 = 0
                            beq $t1, $zero, skipCurrentOffset # if t1 == 0, exit Current offset

                            move $a0, $t3
                            move $a1, $t4
                            # Preserve dr/dc across helper calls; getTileAddr/getBit clobber $t regs.
                            sw $t0, 8($sp)
                            sw $t2, 4($sp)
                            jal getTileAddr

                            lw $a0, 12($v0)
                            li $a1, 1
                            jal getBit
                            lw $t2, 4($sp)
                            lw $t0, 8($sp)
                            beq $v0, $zero, skipCurrentOffset
                            addi $s4, $s4, 1 # updating the neighbour count if mine found

                        skipCurrentOffset:
                            addi $t2, $t2, 1 #move to the next column
                            j columnLoop


                    exitcolumnLoop:
                        addi $t0, $t0, 1 # move to the next row
                        j rowLoop 
                
                
                exitRowLoop:
                    sw $s4, 8($s1) # store the mine count into the current tile's neighboringMines field
                    addi $s3, $s3, 1 # increment the column by 1 
                    j innerLoop0 

        nextOuter0:
            addi $s2, $s2, 1
            j outerloop


    endOuterLoop:

    # Reload the registers and return
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra
endUpdateNeighbourCount:

##
# Handles a left click from the GUI.
#
# Left clicks are used to reveal a tile in the game.
# If the tile is already revealed or is flagged, do nothing.
# If the tile has a mine, reveal all mines, remove all flags, and set `curStatus` to 0 (lost).
#
# Otherwise, call `revealTiles` with the correct arguments to reveal the relevant tiles.
# After that, loop over all tiles and check if all non-mine tiles have been either flagged or revealed.
# If so, set `curStatus` to 1 (won). Otherwise, set `curStatus` to 2 (continue).
##
handleLeftClick:
    # Complete task 2 here!
    # Save the registers
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp) # $s0: The clicked row.
    sw $s1, 24($sp) # $s1: The clicked column.
    sw $s2, 20($sp) # $s2: Base address of the clicked tile.
    sw $s3, 16($sp) # $s3: Last 8 bits of the clicked tile.
    sw $s4, 12($sp) # $s4: The current row in the loop.
    sw $s5, 8($sp) # $s5: The current column in the loop.
    sw $s6, 4($sp) # $s6: The base tile address of the tile in the loop.
    sw $s7, 0($sp) # s7: max row/col == 16

    lw $s0, rowClicked
    lw $s1, colClicked

    move $a0, $s0
    move $a1, $s1
    jal getTileAddr # get the tile address

    move $s2, $v0   # tile address
    lw $s3, 12($s2) # loading the last 8 bits of the clicked tile in s3
    
    move $a0, $s3
    li $a1, 2
    jal getBit 
    bne $v0, $zero, handleLeftClickEarlyReturn

    move $a0, $s3
    li $a1, 0
    jal getBit
    bne $v0, $zero, handleLeftClickEarlyReturn

    move $a0, $s3
    li $a1, 1
    jal getBit

    li $s7, 16             # max rows/cols
    bne $v0, $zero, revealMines   # if mine → go reveal all
    j notMineCase                  # else → normal flow

    revealMines:
        li $s4, 0              # row = 0
        revealMinesOuterLoop:
            beq $s4, $s7, revealMinesDone   # if row == 16 → done
            li $s5, 0              # col = 0

            revealMinesInnerLoop:
                beq $s5, $s7, revealMinesNextRow   # if col == 16 → next row

                move $a0, $s4
                move $a1, $s5
                jal getTileAddr

                move $s6, $v0          # save tile address

                lw $t1, 12($s6)        # load bits of current tile
                move $a0, $t1
                li $a1, 1              # check hasMine
                jal getBit

                lw $t2, 12($s6)
                andi $t2, $t2, 0xFFFE      # clear hasFlag for every tile
                sw $t2, 12($s6)

                beq $v0, $zero, revealMinesSkipTile   # if NOT mine → skip reveal bit

                lw $t1, 12($s6)
                ori $t1, $t1, 4
                sw $t1, 12($s6)      # store back

                revealMinesSkipTile:
                    addi $s5, $s5, 1       # col++
                    j revealMinesInnerLoop

            revealMinesNextRow:
                addi $s4, $s4, 1       # row++
                j revealMinesOuterLoop
        revealMinesDone:
            li $t0, 0
            sw $t0, curStatus # lost the game
            j handleLeftClickDone

        notMineCase:
            li $t0, 2
            sw $t0, curStatus # continue unless we prove a win

            # 1. Reveal tiles
            move $a0, $s0
            move $a1, $s1
            jal revealTiles

            # 2. Assume WON
            li $t0, 1          # 1 = WON
            li $s4, 0          # row = 0

        winOuterLoop:
            beq $s4, $s7, endWinCheck

            li $s5, 0          # col = 0

        winInnerLoop:
            beq $s5, $s7, nextRow

            # get tile address
            move $a0, $s4
            move $a1, $s5
            jal getTileAddr

            move $s6, $v0      # save tile address

            # load bits
            lw $t1, 12($s6)

            # check hasMine
            move $a0, $t1
            li $a1, 1
            jal getBit
            bne $v0, $zero, skipWinTile   # if mine → ignore

            # check isRevealed
            lw $t1, 12($s6)
            move $a0, $t1
            li $a1, 2
            jal getBit
            bne $v0, $zero, skipWinTile   # if revealed → ok

            # # check hasFlag
            # move $a0, $t1
            # li $a1, 0
            # jal getBit
            # bne $v0, $zero, skipWinTile   # if flagged → ok

            # found a safe tile NOT revealed AND NOT flagged
            li $t0, 2          # 2 = ONGOING
            j endWinCheck

        skipWinTile:
            addi $s5, $s5, 1
            j winInnerLoop

        nextRow:
            addi $s4, $s4, 1
            j winOuterLoop

        endWinCheck:
            sw $t0, curStatus
            j handleLeftClickDone

handleLeftClickEarlyReturn:
    li $t0, 2
    sw $t0, curStatus

handleLeftClickDone:

    lw $s7, 0($sp)
    lw $s6, 4($sp)
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra

##
# Reveals the tiles around the input tile recursively.
# The algorithm is as follows:
# 1. Check if the input tile is already revealed, out of bounds, or is flagged. If so, do nothing and return.
# 2. Reveal the input tile by setting the appropriate bit.
# 3. If the input tile has zero neighbour mines, recursively call this function on all 8 neighbour tiles.
#
# Arguments:
# $a0: The row of the tile to reveal.
# $a1: The column of the tile to reveal.
##
revealTiles:
    # Complete task 3 here!
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp) # $s0: current row
    sw $s1, 24($sp) # $s1: current column
    sw $s2, 20($sp) # $s2: Base address of the clicked tile.
    sw $s3, 16($sp) # max col/row = 16
    sw $s4, 12($sp) # stores the last 8 bits
    sw $s5, 8($sp) # neighboring mines
    sw $s6, 4($sp) # loop row
    sw $s7, 0($sp) # loop column

    move $s0, $a0
    move $s1, $a1
    li $s3, 16

    # checking for out of bounds
    slti $t0, $a0, 0 # if #a0 < 0 then $t0 is 1
    bne $t0, $zero, endRevealTiles

    slti $t0, $a0, 16 # if $a0 < 16, then $t0 is 1
    beq $t0, $zero, endRevealTiles

    slti $t0, $a1, 0 # if $a1 < 0, then $t0 is 1
    bne $t0, $zero, endRevealTiles
    
    slti $t0, $a1, 16 # if $a1 < 16, then $t0 is 1
    beq $t0, $zero, endRevealTiles

    move $a0, $s0
    move $a1, $s1
    jal getTileAddr

    move $s2, $v0 # copied the address of the tile
    lw $s4, 12($s2) # t0 = last 8 bits

    move $a0, $s4
    li $a1, 2 # check for isRevealed
    jal getBit
    bne $v0, $zero, endRevealTiles

    move $a0, $s4
    li $a1, 0 # check for hasFlag
    jal getBit
    bne $v0, $zero, endRevealTiles

    # reveal the tile
    lw  $t1, 12($s2)
    ori $t1, $t1, 4
    sw  $t1, 12($s2)

    #neighboring tiles check
    lw $s5, 8($s2)
    bne $s5, $zero, endRevealTiles
    
    li $s6, -1 # for rows / i
    loopRow:
        slti $t0, $s6, 2 #t0 =1 is s6 < 2
        beq $t0, $zero, endLoopRow
        li $s7, -1 # for columns / j
        loopColumn:
            slti $t0, $s7, 2 
            beq $t0, $zero, endLoopColumn
            
            # skip (0,0)
            bne $s6, $zero, doCall
            bne $s7, $zero, doCall
            j skipCall

        doCall:
            add $a0, $s0, $s6
            add $a1, $s1, $s7
            jal revealTiles
            move $a0, $s0
            move $a1, $s1

        skipCall:
            addi $s7, $s7, 1
            j loopColumn

        endLoopColumn:
            addi $s6, $s6, 1
            j loopRow

    endLoopRow:

endRevealTiles:
    lw $s7, 0($sp)
    lw $s6, 4($sp)
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra    

##
# Handles a right click from the GUI.
#
# Right clicks are used to toggle flags on un-revealed tiles.
# If the tile is already revealed, do nothing.
# If the user has successfully flagged all mines, set `curStatus` to 1 (won).
# Otherwise, set it to 2 (continue).
#
# $s0: The clicked row.
# $s1: The clicked column.
# $s2: Base address of the clicked tile.
# $s3: Last 8 bits of the clicked tile.
# $s4: The current row in the loop.
# $s5: The current column in the loop.
# $s6: The base tile address of the tile in the loop.
# $s7: Whether the tile in the loop has a mine.
##
handleRightClick:
    # Save the registers
    addi $sp, $sp, -36
    sw $ra, 32($sp)
    sw $s0, 28($sp)
    sw $s1, 24($sp)
    sw $s2, 20($sp)
    sw $s3, 16($sp)
    sw $s4, 12($sp)
    sw $s5, 8($sp)
    sw $s6, 4($sp)
    sw $s7, 0($sp)

    lw $s0, rowClicked
    lw $s1, colClicked
    addi $a0, $s0, 0
    addi $a1, $s1, 0
    jal getTileAddr

    addi $s2, $v0, 0
    lw $s3, 12($s2)
    addi $a0, $s3, 0
    li $a1, 2
    jal getBit

    beq $v0, $zero, rightClickIsValid
        # Reload the registers
        lw $s7, 0($sp)
        lw $s6, 4($sp)
        lw $s5, 8($sp)
        lw $s4, 12($sp)
        lw $s3, 16($sp)
        lw $s2, 20($sp)
        lw $s1, 24($sp)
        lw $s0, 28($sp)
        lw $ra, 32($sp)
        addi $sp, $sp, 36
        jr $ra
    rightClickIsValid:

    addi $a0, $s3, 0
    li $a1, 0
    jal getBit

    beq $v0, $zero, toggleOnFlag
        # Toggle off
        addi $s3, $s3, -1
        sw $s3, 12($s2)
        j endToggleFlag
    toggleOnFlag:
        addi $s3, $s3, 1
        sw $s3, 12($s2)
    endToggleFlag:

    li $s4, 0
    rightClickRowLoop:
        li $s5, 0
        li $t0, 16
        beq $s4, $t0, endRightClickRowLoop

        rightClickColLoop:
            li $t0, 16
            beq $s5, $t0, endRightClickColLoop

            addi $a0, $s4, 0
            addi $a1, $s5, 0
            jal getTileAddr

            addi $s6, $v0, 0
            lw $a0, 12($s6)
            li $a1, 1
            jal getBit # Get hasMine bit
            addi $s7, $v0, 0

            lw $a0, 12($s6) # Reload
            li $a1, 0
            jal getBit # Get hasFlag bit

            bne $v0, $s7, flagNotMatch

            addi $s5, $s5, 1
            j rightClickColLoop
        endRightClickColLoop:

        addi $s4, $s4, 1
        j rightClickRowLoop
    endRightClickRowLoop:
    # If we reach this, flags == mines
    li $t0, 1
    sw $t0, curStatus
    
    # Return properly; reload the registers
    lw $s7, 0($sp)
    lw $s6, 4($sp)
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
	jr $ra

    flagNotMatch:
    li $t0, 2
    sw $t0, curStatus
    # Reload the registers
    lw $s7, 0($sp)
    lw $s6, 4($sp)
    lw $s5, 8($sp)
    lw $s4, 12($sp)
    lw $s3, 16($sp)
    lw $s2, 20($sp)
    lw $s1, 24($sp)
    lw $s0, 28($sp)
    lw $ra, 32($sp)
    addi $sp, $sp, 36
    jr $ra
endHandleRightClick:

##
# The following section are utility functions which have been given to you.
# You do NOT need to modify them, and are in fact encouraged to use them to simplify your code.
##

##
# Computes the base tile address.
#
# Arguments:
# $a0: The row index.
# $a1: The column index.
#
# Return:
# $v0: The base address of the tile at (a0, a1).
##
getTileAddr:
    la $t0, tiles
    li $t1, 16 # Row length
    mul $t2, $a0, $t1
    add $t2, $t2, $a1
    li $t3, 16 # Tile words
    mul $t4, $t2, $t3
    add $t4, $t4, $t0
    addi $v0, $t4, 0
    jr $ra
endGetTileAddr:

##
# Extracts a given bit from the input value.
# Note that this procedure does NOT accept addresses, only values.
#
# Arguments:
# $a0: The value to extract a bit from
# $a1: The zero-indexed bit to extract, starting from the rightmost bit (i.e to get 1 from 0000 0100, pass 2).
#
# Return:
# $v0: The extracted bit.
##
getBit:
    # Unfortunately, MARS (and our course) does not support the use of srlv
    # (for right-shifting by a variable number of bits).
    # To get around this, we write a loop instead.
    addi $t0, $a0, 0
    li $t1, 0
    getBitLoop:
        beq $t1, $a1, endGetBitLoop
        srl $t0, $t0, 1
        addi $t1, $t1, 1
        j getBitLoop
    endGetBitLoop:
    li $t2, 1 # Bitmask (0...1)
    and $v0, $t0, $t2 # Apply the bitmask
    jr $ra
endGetBit:

exitGame:
li $v0, 206 # Cleanup
syscall
li $v0, 10 # Graceful exit
syscall
