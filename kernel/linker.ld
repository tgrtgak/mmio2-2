/* This describes how the executable is laid out. */

SECTIONS
{
  /* Place start code at 0x80000000 */
  /* This is the entrypoint */
  . = 0xffff800080000000;
  .boot :
  {
    _start = .;
    start.o
  }

  /* Make room for FDT */
  .text ALIGN(0x1000):
  {
    *(.text)
  }

  /* Align data after text section */

  .data ALIGN(0x1000):
  {
    *(.data)

    /* Making sure the kernel is exactly a multiple of the page size */
    _end = ALIGN(0x1000);
  }

  PROVIDE(end = _end);
}
