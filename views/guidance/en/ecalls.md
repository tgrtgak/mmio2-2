# Environment Calls

![Logo](../images/dynamic/hex/ae8bab/dinosaurs/tyrannosaurus.svg)

**Environment Calls** are special higher-level useful actions that can be used in strained environments such
as our bare-metal situation. They are often called *System Calls*. Many machines offer these functions
as a means of aiding development without having to write everything from scratch. (*Phew!!* Of course,
you can still see their implementations if you look at the `{.file}syscall.s` file in the kernel source code.
Everything that runs in our little virtual machine is written in assembly and built the same way as your code!)

To invoke these, which are implemented by the kernel, you follow the instructions provided in the table
and description sections below for the environment call you wish to use. Then you use the special `{.instruction}ecall`
instruction which will call into the kernel and perform the requested action before returning to your
own code.

For example, printing a number:

```riscv
  li    a7, 4     # Select environment call 4 (print integer)
  li    a0, 42    # Pass in arguments using the a1 register (see the table)
  ecall           # Invoke the environment call (it will print '42')
```

Other environment calls may have more or no arguments. Some may provide results in various registers, typically
`{.register}a0`.
Refer to the table below for more information.

## Overview

<!-- for styling the table appropriately -->
<p class="syscalls-table"></p>

| a7 | Name            | Sets (if any) | Arguments | Description                                                  |
|:--:|:---------------:|---------------|-----------|--------------------------------------------------------------|
| 1  | print integer   |               | `{.register}a0`: integer to print | Prints the integer given in `{.register}a1`. It does not print a newline. |
| 2  | print float     |               | `{.register}fa0`: 32-bit float to print | Prints the 32-bit floating point value given in `{.register}fa0`. It does not print a newline. |
| 3  | print double    |               | `{.register}fa0`: 64-bit double to print | Prints the 64-bit floating point value given in `{.register}fa0`. It does not print a newline. |
| 4  | print string    |               | `{.register}a0`: address of string | Prints the null-terminated string given in `{.register}a0`. It does not print a newline.  |
| 5  | read integer    | `{.register}a0`: integer read |           | |
| 8  | read string     | `{.register}a0`: characters read | `{.register}a0`: address of buffer<br>`{.register}a1`: maximum number of characters to read. | |
| 9  | sbrk            |               | `{.register}a0`: number of bytes to allocate | |
| 10 | exit            |               | `{.register}a0`: exit code | Terminates the program and powers down the machine.          |
| 11 | print character |               | `{.register}a0`: character to print | Prints the character given in `{.register}a0`.                            |
| 30 | system time     | `{.register}a0`: milliseconds since boot | | Gets the number of milliseconds since booting the machine. Will not be incredibly accurate. |
| 34 | print integer in hexadecimal |  | `{.register}a0`: integer to print | Prints the integer given in `{.register}a1` as an 8 or 16 digit hexadecimal number, padding with zeros if necessary. It does not print a newline. |
| 35 | print integer in binary  |      | `{.register}a0`: integer to print | Prints the integer given in `{.register}a1` as a 32 or 64 digit binary numbder, padding with zeros if necessary. It does not print a newline. |
| 40 | set seed        | | `{.register}a0`: id of generator | Sets the given random number generator to the given seed. |
| 41 | random word     | `{.register}a0`: random word | `{.register}a0`: The id of the generator to use. |

<!--
| 2  | print float     |               | `{.register}f0`: float to print | Prints the float given in `{.register}f0`. It does not print a newline.   |
| 3  | print double    |               | `{.register}f0`: double to print | Prints the double given in `{.register}f0`. It does not print a newline.  |
| 6  | read float      | `{.register}f0`: float read |           | |
| 7  | read double     | `{.register}f0`: double read |           | |
-->

## Descriptions and Usage

### print integer

Set `{.register}a7` to 1.

Prints the given integer in `{.register}a0`.

```riscv
  li    a7, 1     # Select environment call 1 (print integer)
  li    a0, 42    # Pass in arguments using the a0 register (see the table)
  ecall           # Invoke the environment call (it will print '42')
```

### print string

Set `{.register}a7` to 4.

Prints the given string whose address is within `{.register}a0`.

```riscv
  li    a7, 4     # Select environment call 4 (print string)
  li    a0, str   # Pass in arguments using the a0 register (see the table)
  ecall           # Invoke the environment call (it will print 'Hello!')

.data

str: .string "Hello!"
```

### read integer

Set `{.register}a7` to 5.

Waits for something to be typed in and parses that as an integer which it stores in `{.register}a0`.

```riscv
  li    a7, 5     # Select environment call 5 (read integer)
  ecall           # Invoke the environment call (it will wait here until something is typed in)

  # Now, a0 is the number typed in (or your program errors if the input was not a number!)
  # Let's double the number with a shift left
  sll   a0, a0, 1

  # While a0 is still the number we care about ... let's print it out
  li    a7, 1     # Now, we will print it out using the print integer environment call
  ecall           # Prints the number (double the input) back out! (Remember, a0 is still that number!)
```

### read string

Set `{.register}a7` to 8.

Waits for something to be typed in (ends with an 'enter' press) and writes it to the buffer given in `{.register}a0`.

```riscv
  li    a7, 8     # Select environment call 8 (read string)
  la    a0, buff  # Give it the address of our memory we want to use to write the string to
  li    a1, 99    # We can write up to 99 characters into our buffer
  ecall           # Invoke the environment call (it will wait for a line to be entered)

  # Now, our buffer in `buff` is filled with the line just typed in
  # Let's print it out again

  li    a7, 4     # Use the print string ecall
  la    a0, str   # Prints a helpful string
  ecall

  li    a7, 4     # Use the print string ecall again
  la    a0, buff  # Prints the typed in string
  ecall

.data

buff: .fill 100, 1, 0 # Fills 100 bytes with 0s
str:  .string "\nYou typed in: "
```
