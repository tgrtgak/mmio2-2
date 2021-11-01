# Snake game example
#
# Collect apples and do not collide with the edges, walls, or the snake itself!
#
# Remember to click on the game screen in order for it to pick up your keyboard
# presses!
#
# 'W' - up
# 'A' - left
# 'S' - down
# 'D' - right

# Constants

# The width of the display
.set  DISPLAY_WIDTH,      60

# The height of the display
.set  DISPLAY_HEIGHT,     45

# The display memory address
.set  DISPLAY_ADDRESS,    0x90000000

# The color palette
.set  COLOR_BLACK,        0xff000000
.set  COLOR_BLUE,         0xffaa0000
.set  COLOR_GREEN,        0xff00aa00
.set  COLOR_CYAN,         0xffaaaa00
.set  COLOR_RED,          0xff0000aa
.set  COLOR_MAGENTA,      0xffaa00aa
.set  COLOR_YELLOW,       0xff0055aa
.set  COLOR_LIGHTGRAY,    0xffaaaaaa
.set  COLOR_DARKGRAY,     0xff555555
.set  COLOR_LIGHTBLUE,    0xffff5555
.set  COLOR_LIGHTGREEN,   0xff55ff55
.set  COLOR_LIGHTCYAN,    0xffffff55
.set  COLOR_LIGHTRED,     0xff5555ff
.set  COLOR_LIGHTMAGENTA, 0xffff55ff
.set  COLOR_LIGHTYELLOW,  0xff55ffff
.set  COLOR_WHITE,        0xffffffff

# Some of the keyboard keys we need
.set  KEY_A,              0x41
.set  KEY_D,              0x44
.set  KEY_S,              0x53
.set  KEY_W,              0x57
.set  KEYBOARD_ADDRESS,   0x80000000

# Delay for a game tick in milliseconds
.set  DELAY,              50

# Set the color to clear to
.set  BACKGROUND_COLOR,   COLOR_WHITE
.set  WALL_COLOR,         COLOR_BLUE
.set  SNAKE_COLOR,        COLOR_GREEN
.set  APPLE_COLOR,        COLOR_RED

# Maximum length for the snake
.set  MAX_SNAKE_LENGTH,   20

# Snake directions
.set  SNAKE_RIGHT,        0
.set  SNAKE_LEFT,         1
.set  SNAKE_UP,           2
.set  SNAKE_DOWN,         3

# Game state
.set  STATE_RUNNING,      0
.set  STATE_GAME_OVER,    1

# Code section
.text

# Entry point
main:
    li      a0, DISPLAY_WIDTH
    li      a1, DISPLAY_HEIGHT
    jal     framebuffer_init

    # Seed the random number generator with the current time
    # a0 = time_of_day = get_time_of_day()
    li      a7, 30
    ecall

    # set_seed(0, time_of_day)
    move    a1, a0
    li      a0, 0
    li      a7, 40
    ecall

    jal     place_apple
    jal     start
    jr      ra

# Perform the loop
start:
    add     sp, sp, -8
    sd      ra, 0(sp)
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)

    li      s1, 0

    li      a0, BACKGROUND_COLOR
    jal     clear

    # Get an initial time
    li      a7, 30  # ecall(get_system_time)
    ecall

    move    s0, a0
    li      t0, DELAY
    add     s0, s0, t0

    # Enter loop and wait for counter to do update()
_start_loop:
    # Get current time
    li      a7, 30
    ecall

    # Compare with established time
    bltu    a0, s0, _start_loop

    # If it is the right thing, ok! we perform an update
    # and we preserve this new time and wait for the next tick
    move    s0, a0
    li      t0, DELAY
    add     s0, s0, t0

    # Increment the game ticks
    addi    s1, s1, 1

    # Update the game state
    move    a0, s1
    jal     update

    # Determine if the game is over
    la      t0, game_state
    lw      t0, 0(t0)
    li      t1, STATE_GAME_OVER
    beq     t0, t1, _start_end_game

    # Clear the game board
    li      a0, BACKGROUND_COLOR
    jal     clear

    # Draw the game board
    la      a0, board
    li      a1, WALL_COLOR
    jal     draw_board

    # Draw the game state
    li      a0, SNAKE_COLOR
    li      a1, APPLE_COLOR
    jal     draw

    # Enter loop again
    j       _start_loop

_start_end_game:
    jal     game_over

    # Exit.
    li      a7, 10
    ecall

    # This does not happen
    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# update(ticks)
# Perform a game tick.
# This will be called a few times a second based on the DELAY constant.
#
# Arguments:
#   ticks - The number of game ticks that have occurred.
update:
    add     sp, sp, -8
    sd      ra, 0(sp)
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)
    add     sp, sp, -8
    sd      s2, 0(sp)
    add     sp, sp, -8
    sd      s3, 0(sp)

    # s0: The global ticks.
    move    s0, a0

    # Detect keys
    la      t2, snake_facing
    lw      t2, 0(t2)
_update_check_up:
    # Ignore if we are facing down
    li      t0, SNAKE_DOWN
    beq     t2, t0, _update_check_down

    # Look for 'W'
    li      t0, KEYBOARD_ADDRESS
    lbu     t0, KEY_W(t0)
    beqz    t0, _update_check_down
    la      t0, snake_facing
    li      t1, SNAKE_UP
    sw      t1, 0(t0)

_update_check_down:
    # Ignore if we are facing up
    li      t0, SNAKE_UP
    beq     t2, t0, _update_check_left

    # Look for 'S'
    li      t0, KEYBOARD_ADDRESS
    lbu     t0, KEY_S(t0)
    beqz    t0, _update_check_left
    la      t0, snake_facing
    li      t1, SNAKE_DOWN
    sw      t1, 0(t0)

_update_check_left:
    # Ignore if we are facing right
    li      t0, SNAKE_RIGHT
    beq     t2, t0, _update_check_right

    # Look for 'A'
    li      t0, KEYBOARD_ADDRESS
    lbu     t0, KEY_A(t0)
    beqz    t0, _update_check_right
    la      t0, snake_facing
    li      t1, SNAKE_LEFT
    sw      t1, 0(t0)

_update_check_right:
    # Ignore if we are facing left
    li      t0, SNAKE_LEFT
    beq     t2, t0, _update_move_snake

    # Look for 'D'
    li      t0, KEYBOARD_ADDRESS
    lbu     t0, KEY_D(t0)
    beqz    t0, _update_move_snake
    la      t0, snake_facing
    li      t1, SNAKE_RIGHT
    sw      t1, 0(t0)

    # Move snake
_update_move_snake:
    la      t0, snake_speed
    lw      t0, 0(t0)
    rem     t0, s0, t0
    bnez    t0, _update_skip_snake

    # Determine how to move the snake
    # First, t1 will be the direction of the snake
    la      t0, snake_facing
    lw      t1, 0(t0)

    # We will decide how much to move the snake right (s2)
    # And how much to move the snake down (s3)
    li      s2, 0
    li      s3, 0

_update_move_snake_left:
    li      t0, SNAKE_LEFT
    bne     t1, t0, _update_move_snake_right
    li      s2, -1

_update_move_snake_right:
    li      t0, SNAKE_RIGHT
    bne     t1, t0, _update_move_snake_up
    li      s2, 1

_update_move_snake_up:
    li      t0, SNAKE_UP
    bne     t1, t0, _update_move_snake_down
    li      s3, -1

_update_move_snake_down:
    li      t0, SNAKE_DOWN
    bne     t1, t0, _update_move_snake_eat_apple
    li      s3, 1

_update_move_snake_eat_apple:
    # Eat an apple, maybe
    # Determine where the head is going to be
    la      t0, snake_x
    lw      t5, 0(t0)
    add     t5, t5, s2
    la      t0, snake_y
    lw      t6, 0(t0)
    add     t6, t6, s3

    # Determine where the apple is
    la      t0, apple_x
    lw      t0, 0(t0)
    la      t1, apple_y
    lw      t1, 0(t1)

    # If it is not where the apple is, continue
    bne     t0, t5, _update_move_snake_check
    bne     t1, t6, _update_move_snake_check

    # Place a new apple
    jal     place_apple

    # Speed up the snake
    la      t0, snake_speed
    lw      t0, 0(t0)
    li      t1, 1
    beq     t0, t1, _update_move_snake_eat_apple_grow
    addi    t1, t0, -1
    la      t0, snake_speed
    sw      t1, 0(t0)

_update_move_snake_eat_apple_grow:
    # Ok, eat the apple by incrementing the snake (if possible)
    la      t0, snake_length
    lw      t0, 0(t0)
    addi    t0, t0, 1
    li      t1, MAX_SNAKE_LENGTH
    bge     t0, t1, _update_move_snake_check
    move    t1, t0
    la      t0, snake_length
    sw      t1, 0(t0)

_update_move_snake_check:
    # Check for collisions
    la      t0, snake_x
    lw      t1, 0(t0)
    add     t1, t1, s2

    li      t0, DISPLAY_WIDTH
    bge     t1, t0, _update_move_snake_collide
    blt     t1, zero, _update_move_snake_collide

    la      t0, snake_y
    lw      t1, 0(t0)
    add     t1, t1, s3

    li      t0, DISPLAY_HEIGHT
    bge     t1, t0, _update_move_snake_collide
    blt     t1, zero, _update_move_snake_collide

    # Check against the board
    la      a0, board
    la      a1, snake_x
    lw      a1, 0(a1)
    add     a1, a1, s2
    la      a2, snake_y
    lw      a2, 0(a2)
    add     a2, a2, s3
    jal     check_board_collision
    bnez    a0, _update_move_snake_collide

    # Check against the snake
    la      a0, snake_x
    lw      a0, 0(a0)
    add     a0, a0, s2
    la      a1, snake_y
    lw      a1, 0(a1)
    add     a1, a1, s3
    jal     check_snake_collision
    bnez    a0, _update_move_snake_collide

    j       _update_move_snake_commit

_update_move_snake_collide:
    la      t0, game_state
    li      t1, STATE_GAME_OVER
    sw      t1, 0(t0)
    j       _update_skip_snake

_update_move_snake_commit:
    # Do the snake thing to move each segment of the snake
    la      t0, snake_x
    la      t1, snake_y

    # Go to the last segment of the snake
    la      t5, snake_length
    lw      t5, 0(t5)
    sll     t5, t5, 2
    add     t0, t0, t5
    add     t1, t1, t5

    # Track the index of the segment
    li      s1, 0
_update_move_snake_commit_loop:
    # Move to the next segment, toward the head
    addi    s1, s1, 1
    addi    t0, t0, -4
    addi    t1, t1, -4

    # If we are at the head, bail and commit the head's movement
    la      t5, snake_length
    lw      t5, 0(t5)
    beq     s1, t5, _update_move_snake_commit_head

    addi    t5, t0, -4
    addi    t6, t1, -4
    lw      t5, 0(t5)
    lw      t6, 0(t6)
    sw      t5, 0(t0)
    sw      t6, 0(t1)
    j       _update_move_snake_commit_loop

_update_move_snake_commit_head:
    # Move snake along x axis
    lw      t5, 0(t0)
    add     t5, t5, s2
    sw      t5, 0(t0)

    # Move snake along y axis
    lw      t6, 0(t1)
    add     t6, t6, s3
    sw      t6, 0(t1)

_update_skip_snake:
    ld      s3, 0(sp)
    add     sp, sp, 8
    ld      s2, 0(sp)
    add     sp, sp, 8
    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# Draws the provided game board
draw_board:
    add     sp, sp, -8
    sd      ra, 0(sp)
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)
    add     sp, sp, -8
    sd      s2, 0(sp)
    add     sp, sp, -8
    sd      s3, 0(sp)

    # Retain the address
    move    s0, a0

    # Retain the color
    move    s1, a1

    # Start at (0, 0)
    li      s2, 0
    li      s3, 0

_draw_board_loop:
    addi    s0, s0, 1
    addi    s2, s2, 1
    li      t0, DISPLAY_WIDTH
    beq     t0, s2, _draw_board_loop_next_row
    j       _draw_board_loop_setpixel

_draw_board_loop_next_row:
    li      s2, 0
    addi    s3, s3, 1
    li      t0, DISPLAY_HEIGHT
    beq     t0, s3, _draw_board_loop_exit

_draw_board_loop_setpixel:
    lbu     t0, 0(s0)
    li      t1, ' '
    beq     t0, t1, _draw_board_loop

    move    a0, s2
    move    a1, s3
    move    a2, s1
    jal     setpixel
    j       _draw_board_loop

_draw_board_loop_exit:
    # Return
    ld      s3, 0(sp)
    add     sp, sp, 8
    ld      s2, 0(sp)
    add     sp, sp, 8
    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# Draws the game board.
draw:
    add     sp, sp, -8
    sd      ra, 0(sp)
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)
    add     sp, sp, -8
    sd      s2, 0(sp)

    # Retain arguments
    move    s1, a0
    move    s2, a1

    # Draw apple
    la      t0, apple_x
    lw      a0, 0(t0)

    la      t0, apple_y
    lw      a1, 0(t0)

    move    a2, s2
    jal     setpixel

    # Draw snake
    li      s0, 0
_draw_snake_loop:
    la      t0, snake_length
    lw      t0, 0(t0)
    beq     s0, t0, _draw_snake_loop_exit

    la      t0, snake_x
    sll     t1, s0, 2
    add     t0, t0, t1
    lw      a0, 0(t0)

    la      t0, snake_y
    sll     t1, s0, 2
    add     t0, t0, t1
    lw      a1, 0(t0)

    move    a2, s1
    jal     setpixel

    addi    s0, s0, 1
    j       _draw_snake_loop
_draw_snake_loop_exit:

    # Return
    ld      s2, 0(sp)
    add     sp, sp, 8
    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# Places an apple on the board somewhere in an open space
place_apple:
    add     sp, sp, -8
    sd      ra, 0(sp)

_place_apple_try:
    # Use an ecall to get a random number
    li      a0, 0
    li      a7, 41
    ecall

    # Get the random x
    li      t0, DISPLAY_WIDTH
    rem     t1, a0, t0
    la      t0, apple_x
    sw      t1, 0(t0)

    # Use an ecall to get another random number
    li      a0, 0
    li      a7, 41
    ecall

    # Get the random y
    li      t0, DISPLAY_HEIGHT
    rem     t1, a0, t0
    la      t0, apple_y
    sw      t1, 0(t0)

    # Check the apple position against collisions and repeat if it collides
    la      a0, board
    la      a1, apple_x
    lw      a1, 0(a1)
    la      a2, apple_y
    lw      a2, 0(a2)
    jal     check_board_collision
    beqz    a0, _place_apple_check_snake_collision
    j       _place_apple_try

_place_apple_check_snake_collision:
    # Check the apple position against collisions with snake and maybe try again
    la      a0, board
    la      a0, apple_x
    lw      a0, 0(a0)
    la      a1, apple_y
    lw      a1, 0(a1)
    jal     check_snake_collision
    beqz    a0, _place_apple_return
    j       _place_apple_try

_place_apple_return:
    # Return
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# Checks to see if the given coordinate (in a1, a2) collides with the board (a0)
# Returns 1 in a0 if it does, otherwise 0.
check_board_collision:
    add     sp, sp, -8
    sd      ra, 0(sp)

    li      t0, DISPLAY_WIDTH
    mul     a2, a2, t0
    add     a1, a1, a2
    add     a0, a0, a1
    lbu     a0, 0(a0)

    li      t0, ' '
    beq     t0, a0, _check_board_collision_empty
    li      a0, 1
    j       _check_board_collision_return

_check_board_collision_empty:
    li      a0, 0

_check_board_collision_return:
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# Checks to see if the given coordinate hits the snake
# Returns 1 in a0 if it does, otherwise 0.
check_snake_collision:
    add     sp, sp, -8
    sd      ra, 0(sp)
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)

    # Retain coordinate
    move    s0, a0
    move    s1, a1

    # Returns 0 by default
    li      a0, 0

    # Look at each snake segment. If it collides
    la      t0, snake_x
    la      t1, snake_y
    la      t2, snake_length
    lw      t2, 0(t2)
_check_snake_collision_loop:
    # Read the segment coordinate
    lw      t3, 0(t0)
    lw      t4, 0(t1)

    # Compare
    bne     s0, t3, _check_snake_collision_loop_next
    bne     s1, t4, _check_snake_collision_loop_next

    # Collides!
    li      a0, 1
    j       _check_snake_collision_return

_check_snake_collision_loop_next:
    # Go to the next segment
    addi    t0, t0, 4
    addi    t1, t1, 4

    # Bail if we consumed all segments
    addi    t2, t2, -1
    beqz    t2, _check_snake_collision_return

    # Loop otherwise to check all other segments
    j       _check_snake_collision_loop

_check_snake_collision_return:
    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# Marks the game as in the game over state
game_over:
    add     sp, sp, -8
    sd      ra, 0(sp)

    # Clear the black
    li      a0, COLOR_BLACK
    jal     clear

    # Draw the game over text
    la      a0, game_over_board
    li      a1, COLOR_RED
    jal     draw_board

    # Draw (red snake, red apple)
    li      a0, COLOR_RED
    li      a1, COLOR_RED
    jal     draw

    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# Draw black pixels on the entire screen
clear:
    add     sp, sp, -8
    sd      ra, 0(sp)
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)
    add     sp, sp, -8
    sd      s2, 0(sp)

    move    s2, a0

    # For s0 from [-1, DISPLAY_WIDTH)
    # And s1 from [0, DISPLAY_HEIGHT)
    li      s0, -1
    li      s1, 0
_clear_loop:
    # Increment s0 (which is the x coordinate)
    addi    s0, s0, 1
    li      t0, DISPLAY_WIDTH
    bne     s0, t0, _clear_loop_step

    # Go to the next row (set s0 to 0 again, and increment s1)
    li      s0, 0
    addi    s1, s1, 1

    # Bail out on the loop (and function) when s1 is the display height
    # This means we have cleared the entire display.
    li      t1, DISPLAY_HEIGHT
    beq     s1, t1, _clear_loop_exit

_clear_loop_step:
    # Set the pixel to the background color
    move    a0, s0
    move    a1, s1
    move    a2, s2
    jal     setpixel

    # Loop for the next pixel
    j       _clear_loop

_clear_loop_exit:
    # Return
    ld      s2, 0(sp)
    add     sp, sp, 8
    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    ld      ra, 0(sp)
    add     sp, sp, 8
    jr      ra

# setpixel(x, y, color)
setpixel:
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)

    # Get the framebuffer base
    li      s0, (DISPLAY_ADDRESS + 0x1000)

    # Step to the correct pixel data
    li      s1, DISPLAY_WIDTH
    mul     a1, a1, s1
    add     s1, a0, a1
    slli    s1, s1, 2
    add     s0, s0, s1

    # Write pixel
    sw      a2, 0(s0)

    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    jr      ra

# getpixel(x, y)
# a0 is set to the color value
getpixel:
    add     sp, sp, -8
    sd      s0, 0(sp)
    add     sp, sp, -8
    sd      s1, 0(sp)

    # Get the framebuffer base
    li      s0, 0x90001000

    # Step to the correct pixel data
    li      s1, DISPLAY_WIDTH
    mul     a1, a1, s1
    add     s1, a0, a1
    slli    s1, s1, 2
    add     s0, s0, s1

    # Write pixel
    lw      a0, 0(s0)

    ld      s1, 0(sp)
    add     sp, sp, 8
    ld      s0, 0(sp)
    add     sp, sp, 8
    jr      ra

# framebuffer_init(width, height)
framebuffer_init:
    add     sp, sp, -8
    sd      s0, 0(sp)

    # Set the width
    li      s0, 0x90000000
    sw      a0, 0(s0)

    # Set the height
    li      s0, 0x90000004
    sw      a1, 0(s0)

    # Return
    ld      s0, 0(sp)
    add     sp, sp, 8
    jr      ra

# Data section (Variables, etc)
.data

# The state of the game
game_state:   .int  STATE_RUNNING

# The snake positions, length, and speed
# Using: .fill count, size, value
snake_x:      .fill MAX_SNAKE_LENGTH, 4, 0
snake_y:      .fill MAX_SNAKE_LENGTH, 4, 0
snake_length: .int  1
snake_speed:  .int  8
snake_facing: .int  0

# The apple position
apple_x:      .int  10
apple_y:      .int  15

# The play board
board:

  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "  xxxxx                                              xxxxx  "
  .ascii "    x                                                  x    "
  .ascii "    x                                                  x    "
  .ascii "    x                                                  x    "
  .ascii "    x                                                  x    "
  .ascii "    xxxxx                                          xxxxx    "
  .ascii "      x                                              x      "
  .ascii "      x                                              x      "
  .ascii "      x                                              x      "
  .ascii "      x                                              x      "
  .ascii "      xxxxx              x   xx   x              xxxxx      "
  .ascii "                        x    xx    x                        "
  .ascii "                       x     xx     x                       "
  .ascii "                      x      xx      x                      "
  .ascii "      xxxxx          x                x          xxxxx      "
  .ascii "          x         x                  x         x          "
  .ascii "          x        x                    x        x          "
  .ascii "        xxxxx     x          xx          x     xxxxx        "
  .ascii "                  x          xx          x                  "
  .ascii "                  x                      x                  "
  .ascii "        xxxxx     x                      x     xxxxx        "
  .ascii "                  x                      x                  "
  .ascii "                  x          xx          x                  "
  .ascii "        xxxxx     x          xx          x     xxxxx        "
  .ascii "          x        x                    x        x          "
  .ascii "          x         x                  x         x          "
  .ascii "      xxxxx          x                x          xxxxx      "
  .ascii "                      x      xx      x                      "
  .ascii "                       x     xx     x                       "
  .ascii "                        x    xx    x                        "
  .ascii "      xxxxx              x   xx   x              xxxxx      "
  .ascii "      x                                              x      "
  .ascii "      x                                              x      "
  .ascii "      x                                              x      "
  .ascii "      x                                              x      "
  .ascii "    xxxxx                                          xxxxx    "
  .ascii "    x                                                  x    "
  .ascii "    x                                                  x    "
  .ascii "    x                                                  x    "
  .ascii "    x                                                  x    "
  .ascii "  xxxxx                                              xxxxx  "
  .ascii "                                                            "
  .ascii "                                                            "

# The Game Over Screen
game_over_board:

  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "     xxxx  xxx  xx   xx xxxx       xxxx x   x xxxx xxx      "
  .ascii "     x    x   x x x x x x          x  x x   x x    x  x     "
  .ascii "     x xx xxxxx x  x  x xxxx       x  x x   x xxxx xxx      "
  .ascii "     x  x x   x x     x x          x  x  x x  x    x  x     "
  .ascii "     xxxx x   x x     x xxxx       xxxx   x   xxxx x  x     "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
  .ascii "                                                            "
