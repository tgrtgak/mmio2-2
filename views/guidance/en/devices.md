# Devices

![A Velociraptor](../images/dynamic/hex/ae8bab/dinosaurs/velociraptor.svg)

Many machines are more than just a CPU and some memory.
Computers are made up of many different pieces.
By themselves, CPUs offer a very general yet very useful service: mathematics.
Often it is useful to add on some very specific capabilities.

## Keyboard

The keyboard device manages interpreting key presses.
The `kernel` has a driver that waits for keys to be pressed (or released) and keeps track of them.
If you are using an `{.instruction}ecall` that reads text input from someone, the `kernel` will interpret the keys pressed as characters.

In situations where keys are pressed at any other time, they are not lost.
The `kernel` manages some memory that keeps track of which keys are currently pressed.
Your program can react to those in order to add some interactivity.

The "keyboard state" is a page of memory (a continuous array of data) that starts at address `0x80000000`.
Each byte corresponds to a different key.
Yet, these do not respect the labels that are on your keyboard.
So, for many keyboards across the world, the keys have to be interpreted in different ways depending on their keyboard layout.
Here are a set of key codes that match the United States keyboard layout:
(RAWRS does its best to convert from the native keyboard layout to the US one so certain system calls work, but use of the keyboard state table may react differently on different keyboard layouts)

```riscv
.set KEY_BACKSPACE,   0x08
.set KEY_TAB,         0x09
.set KEY_ENTER,       0x0d
.set KEY_SHIFT,       0x10
.set KEY_CONTROL,     0x11
.set KEY_ALT,         0x12
.set KEY_CAPSLOCK,    0x14
.set KEY_SPACE,       0x20
.set KEY_0,           0x30
.set KEY_1,           0x31
.set KEY_2,           0x32
.set KEY_3,           0x33
.set KEY_4,           0x34
.set KEY_5,           0x35
.set KEY_6,           0x36
.set KEY_7,           0x37
.set KEY_8,           0x38
.set KEY_9,           0x39
.set KEY_A,           0x41
.set KEY_B,           0x42
.set KEY_C,           0x43
.set KEY_D,           0x44
.set KEY_E,           0x45
.set KEY_F,           0x46
.set KEY_G,           0x47
.set KEY_H,           0x48
.set KEY_I,           0x49
.set KEY_J,           0x4a
.set KEY_K,           0x4b
.set KEY_L,           0x4c
.set KEY_M,           0x4d
.set KEY_N,           0x4e
.set KEY_O,           0x4f
.set KEY_P,           0x50
.set KEY_Q,           0x51
.set KEY_R,           0x52
.set KEY_S,           0x53
.set KEY_T,           0x54
.set KEY_U,           0x55
.set KEY_V,           0x56
.set KEY_W,           0x57
.set KEY_X,           0x58
.set KEY_Y,           0x59
.set KEY_Z,           0x5a
.set KEY_NUMPAD_0,    0x60
.set KEY_NUMPAD_1,    0x61
.set KEY_NUMPAD_2,    0x62
.set KEY_NUMPAD_3,    0x63
.set KEY_NUMPAD_4,    0x64
.set KEY_NUMPAD_5,    0x65
.set KEY_NUMPAD_6,    0x66
.set KEY_NUMPAD_7,    0x67
.set KEY_NUMPAD_8,    0x68
.set KEY_NUMPAD_9,    0x69
.set KEY_NUMPAD_MUL,  0x6a
.set KEY_NUMPAD_ADD,  0x6b
.set KEY_NUMPAD_SUB,  0x6d
.set KEY_NUMPAD_DOT,  0x6e
.set KEY_NUMPAD_DIV,  0x6f
.set KEY_SEMICOLON,   0xba
.set KEY_EQUALS,      0xbb
.set KEY_COMMA,       0xbc
.set KEY_HYPHEN,      0xbd
.set KEY_PERIOD,      0xbe
.set KEY_F_SLASH,     0xbf
.set KEY_BACKTICK,    0xc0
.set KEY_L_BRACKET,   0xdb
.set KEY_B_SLASH,     0xdc
.set KEY_R_BRACKET,   0xdd
.set KEY_APOSTROPHE,  0xde
```

Here is a small example that shows how to read from this keyboard table.
In this program, you can press '`A`' to print out a message.
You can press '`Z`' to end the program.
As you can see, the '`A`' key is byte `0x41` (65th) within the table.
Therefore, accessing `KEY_A(t0)` in this code will retrieve the key state.
A `0` means the key is not pressed and a `1` means it is currently held down.

```riscv
.set KEY_A,     0x41
.set KEY_Z,     0x5a
    
    li      t0, 0x80000000  # The keyboard table address
    
_loop:
    lbu     t1, KEY_Z(t0)
    bnez    t1, _exit
    
    lbu     t1, KEY_A(t0)
    beqz    t1, _loop
    
    li      a7, 4
    la      a0, str_woo
    ecall
    
_loop_depressed:
    lbu     t1, KEY_Z(t0)
    bnez    t1, _exit
    
    lbu     t1, KEY_A(t0)
    bnez    t1, _loop_depressed
    
    j _loop
    
_exit:
    li      a7, 4
    la      a0, str_done
    ecall
    
    li      a7, 10
    ecall
    
.data
str_woo:    .string "Woo! 'A' pressed!\n"
str_done:   .string "'Z' pressed! We're outta here!\n"
```

## Framebuffer (Video)

You can do a lot with just text.
Many computers were just that for many years.
There are many celebrated works of interactive art that are just text-based adventures where you type in commands to act and react to the world.  
Yet, it is certainly also fun to paint the world in whatever colors you wish.

With a "framebuffer", you get a particular range of memory that is mapped to a display.
Writing to this memory has the "side effect" that it gets painted to the video display.
With this, you can draw sprites, backgrounds, landscapes... whatever you can imagine (and then create in code!)

Using this is relatively straightforward.
The framebuffer memory starts at address `0x90001000` and proceeds continuously to create an array of pixels.
Each word (4 bytes) represents a single pixel in the form `a8b8g8r8` where the `a` stands for alpha (transparency) which is ignored by our display. The `r` stands for **red**, `g` stands for **green**, and `b` stands for **blue**.
The resulting color is determined by mixing each of these together.

You may be used to additive color.
This is what happens when you mix paints or inks together.
Red and blue make purple.
However, this is subtractive color, which is what happens when you mix colors of light together.
This is the preferred way to represent colors on computers since we end up displaying them on a light-emitting screen (and not printed out on paper.)
Red and blue, in this scheme, also make purple.
However, red and green (opposites in subtractive color) make yellow, here.
This takes some getting used to, but there are many resources online to retrieve the red-green-blue (RGB) values from any color you like.

The first word in memory (at `0x90001000`) represents the top-left-most pixel.
The next word in memory (at `0x90001004`) represents the pixel to the immediate right of that one.
The words continue along that row until it hits the last pixel within that row at its right-most edge.
In that case, the next word in memory represents the first pixel of the next row, at its left-most edge.
All in all, the words (and pixels) of the screen go from top-left and proceed strictly to the right, whip back to the left with every row, and end on the last pixel at the bottom-right.

The screen, by default, is 640 pixels wide and 480 pixels high.
Therefore, there are `640 * 480` pixels.
Since each pixel is a word (4 bytes), there are 1,228,800 bytes.
That's quite a lot! Think about your display, now.
A 640 by 480 display was quite common in the 90s, but a 4K display, today, is 3840 by 2160.
By the same 4-bytes-per-pixel rule, that comes to 33,177,600 bytes just to display one frame.
We have come a long way.

Our little simulator, because of how much control we have over it and what it does for us, is not as powerful as your actual machine.
Because of that, it won't be able to keep up if the screen was too large.
So, we have our small screen to start with.
Modern machines have a lot of tricks up their sleeves to make graphics processing and drawing to the screen really fast, which we don't have here.
But this is still a good place to start.

Here is some code to paint the display red:

```riscv
  li    t0, 0x90001000    # pixel_address = The framebuffer address
  li    t3, 640           # width = 640
  li    t4, 480           # height = 480

  li    t1, 0             # y = 0
_loop_y:
  li    t2, 0             # x = 0
_loop_x:
  li    t5, 0xff0000ff    # Color = (A = 0xff, B = 0x00, G = 0x00, R = 0xff)
  sw    t5, 0(t0)         # pixel_address <- Color
  add   t0, t0, 4         # pixel_address = pixel_address + 4
  add   t2, t2, 1         # x = x + 1
  bne   t1, t3, _loop_x

  add   t1, t1, 1         # y = y + 1
  bne   t1, t3, _loop_y
```

Try replacing the color value with your favorite color.
Remember, the "alpha" value should be `0xff`.
For one of my favorite colors (R: 146, G: 122, B: 144), the hex values would be (R: 0x92, G: 0x7a, B: 0x90) so I would use `0xff907a92` as my color value.

Try it yourself!

With some effort, you can start drawing characters and animations.

As we said before, the display size is 640 pixels wide by 480 pixels high by *default*.
The first 4096 bytes (the first "page" of memory, which you may learn a bit about later on) is for the device control.
The first word in memory here (at address `0x90000000`) is the display width and the next word (at address `0x90000004`) is the display height.
The display itself will be scaled to fit the video container in the RAWRS application.

Making the display very large might make your application a little slower since it has to do a lot more work to paint the screen.
