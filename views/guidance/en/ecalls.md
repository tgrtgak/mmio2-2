# Environment Calls

![Logo](../images/dynamic/hex/ae8bab/dinosaurs/tyrannosaurus.svg)

**Environment Calls** are special higher-level useful actions that can be used in strained environments such
as our bare-metal situation. They are often called *System Calls*. Many machines offer these functions
as a means of aiding development without having to write everything from scratch. (*Phew!!* Of course,
you can still see their implementations if you look at the `syscall.s` file in the kernel source code)

To invoke these, which are implemented by the kernel, you follow the instructions provided in the table
and description sections below for the environment call you wish to use. Then you use the special `ecall`
instruction which will call into the kernel and perform the requested action before returning to your
own code.

For example, printing a number:

```riscv
  li    a0, 4     # Select environment call 4 (print integer)
  li    a1, 42    # Pass in arguments using the a1 register (see the table)
  ecall           # Invoke the environment call (it will print '42')
```

Other environment calls may have more or no arguments. Some may provide results in various registers, typically `a0`.
Refer to the table below for more information.

## Overview

<!-- for styling the table appropriately -->
<p class="syscalls-table"></p>

| a0 | Name            | Sets (if any) | Arguments | Description                                                  |
|:--:|:---------------:|---------------|-----------|--------------------------------------------------------------|
| 1  | print integer   |               | a1: integer to print | Prints the integer given in a1. It does not print a newline. |
| 2  | print float     |               | f0: float to print | Prints the float given in f0. It does not print a newline.   |
| 3  | print double    |               | f0: double to print | Prints the double given in f0. It does not print a newline.  |
| 4  | print string    |               | a1: address of string | Prints the null-terminated string given in a1. It does not print a newline.  |
| 5  | read integer    | a0: integer read |           | |
| 6  | read float      | f0: float read |           | |
| 7  | read double     | f0: double read |           | |
| 8  | read string     | a0: characters read | a1: address of buffer<br>a2: maximum number of characters to read. | |
| 9  | sbrk            |               | a1: number of bytes to allocate | |
| 10 | exit            |               | a1: exit code | Terminates the program and powers down the machine.          |
| 11 | print character |               | a1: character to print | Prints the character given in a1.                            |
| 30 | system time     | a0: milliseconds since boot | | Gets the number of milliseconds since booting the machine. Will not be incredibly accurate. |
| 40 | set seed        | | a0: id of generator | Sets the given random number generator to the given seed. |
| 41 | random word     | a0: random word | a1: The id of the generator to use. |

## Descriptions and Usage

### print integer

Set `a0` to 4.

Prints the given integer in `a1`.

```riscv
  li    a0, 4     # Select environment call 4 (print integer)
  li    a1, 42    # Pass in arguments using the a1 register (see the table)
  ecall           # Invoke the environment call (it will print '42')
```

### print float
