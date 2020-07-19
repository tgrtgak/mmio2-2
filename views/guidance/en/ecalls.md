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
  li    a0, 4     # Select environment call 4 (print integer)
  li    a1, 42    # Pass in arguments using the a1 register (see the table)
  ecall           # Invoke the environment call (it will print '42')
```

Other environment calls may have more or no arguments. Some may provide results in various registers, typically
`{.register}a0`.
Refer to the table below for more information.

## Overview

<!-- for styling the table appropriately -->
<p class="syscalls-table"></p>

| a0 | Name            | Sets (if any) | Arguments | Description                                                  |
|:--:|:---------------:|---------------|-----------|--------------------------------------------------------------|
| 1  | print integer   |               | `{.register}a1`: integer to print | Prints the integer given in `{.register}a1`. It does not print a newline. |
| 2  | print float     |               | `{.register}f0`: float to print | Prints the float given in `{.register}f0`. It does not print a newline.   |
| 3  | print double    |               | `{.register}f0`: double to print | Prints the double given in `{.register}f0`. It does not print a newline.  |
| 4  | print string    |               | `{.register}a1`: address of string | Prints the null-terminated string given in `{.register}a1`. It does not print a newline.  |
| 5  | read integer    | `{.register}a0`: integer read |           | |
| 6  | read float      | `{.register}f0`: float read |           | |
| 7  | read double     | `{.register}f0`: double read |           | |
| 8  | read string     | `{.register}a0`: characters read | `{.register}a1`: address of buffer<br>`{.register}a2`: maximum number of characters to read. | |
| 9  | sbrk            |               | `{.register}a1`: number of bytes to allocate | |
| 10 | exit            |               | `{.register}a1`: exit code | Terminates the program and powers down the machine.          |
| 11 | print character |               | `{.register}a1`: character to print | Prints the character given in `{.register}a1`.                            |
| 30 | system time     | `{.register}a0`: milliseconds since boot | | Gets the number of milliseconds since booting the machine. Will not be incredibly accurate. |
| 40 | set seed        | | `{.register}a1`: id of generator | Sets the given random number generator to the given seed. |
| 41 | random word     | `{.register}a0`: random word | `{.register}a1`: The id of the generator to use. |

## Descriptions and Usage

### print integer

Set `{.register}a0` to 4.

Prints the given integer in `{.register}a1`.

```riscv
  li    a0, 4     # Select environment call 4 (print integer)
  li    a1, 42    # Pass in arguments using the a1 register (see the table)
  ecall           # Invoke the environment call (it will print '42')
```

### print float
