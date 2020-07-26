# This file manages memory and RAM.

# Right now, memory is maintained by a bitmap. When a bit is set, that page is
# being used. To initialize the memory manager, that bitmap must be set up to
# target areas of RAM used by the kernel or devices (if necessary).

# That information is in the FDT, provided in our case by our emulator. We will
# pass along that information (ram size and such) to the memory manager on
# initialization.

# Our emulator does not overlap device memory with RAM. It has a very relaxed
# layout where devices are in low memory and RAM is in high memory (in 32-bit
# terms)

# Memory layout of the emulator:
# 0x00000000 - Small amount of system memory
# 0x40000000 - Device MMIO
# 0x80000000 - RAM

# At the beginning or RAM, our kernel and application are copied. Our kernel
# will initialize itself and then map in the application data. The rest of the
# RAM memory can be allocated dynamically.

# We just have a single page (4096 bytes) for our bitmap. That allows us to
# cover RAM that is 4096*4096*8 (128MiB) in size. That's not very much.

.include "const.s"
.include "util.s"

.global memory_init
.global memory_get_bitmap_size
.global memory_alloc_page
.global memory_free_page

.text

# memory_init(): Instantiates the memory manager.
#
# Arguments
#   a0: The amount of memory in MiB
memory_init:
  push  ra
  push  s0
  push  s1

  move  s0, a0

  # Retain our RAM size
  la    t1, memory_ram_size
  sd    s0, 0(t1)

  # Get the kernel's endpoint
  # "_end" is embedded by our linker (see: linker.ld)
  la    t0, _end

  # This tells us the end of our kernel. All the rest of RAM is free for us to
  # use. For instance, to allocate dynamically (malloc, etc) for ourselves and
  # applications.

  # Align this pointer on the page boundary
  # (It should already be, but whatever)
  alignPage t0

  # Retain our bitmap address
  la    t1, memory_bitmap_addr
  sd    t0, 0(t1)

  # Retain our bitmap size
  la    t1, memory_bitmap_size
  li    t2, PAGE_SIZE
  sd    t2, 0(t1)

  # Initialize our bitmap (it will be the next page of memory aka 't0')
  # We initialize it by first zeroing it out.
  move  a0, t0
  li    a1, PAGE_SIZE
  jal   memzero

  # Now, we can allocate regions.
  # We know to reserve the pages we are already using.
  # So, all of RAM from 0x0 to _end, and one more to mark our own bitmap.
  # (A bit mind-blowing!)

  # To do that, we can simply figure out how many bytes (sets of 8 pages) are
  # used. Then we call memset with 0xff (a byte will all 1s set) and then we
  # simply set the last item

  # Let's calculate the number of pages used in total.
  # That would be the address of our (bitmap + 4096) divided by 4096 (page size)
  # Since we aligned our bitmap to the page size, this will divide evenly
  move  t1, t0            # recall the address of our bitmap (the kernel size)
  la    t3, _start        # Get the address of the beginning of the kernel
  sub   t1, t1, t3        # Subtract to get the kernel size.
  li    t3, PAGE_SIZE
  add   t1, t1, t3        # add our bitmap itself
  divu  t1, t1, t3        # determine the number of pages used

  # t1: The total pages used.

  # Now, let's get the remainder (pages % 8) which tells us how many pages go
  # into the last byte.

  # t2: The total pages on the fringe.
  li    t3, 8
  remu  t2, t1, t3

  # Subtracting that gets us the number of pages that are represented by filled
  # bytes. Dividing that by 8, thus, gets us the number of filled bytes.
  sub   t1, t1, t2
  li    t3, 8
  divu  t1, t1, t3

  # t1: Is now the number of saturated bytes in our bitmap.
  
  # Cool. We can saturate those bytes with a call to memset.
  move  a0, t0
  li    a1, 0xff
  move  a2, t1
  jal   memset

  # Set the remaining section to t2, the byte value that remains.
  # Determine the bitmap value, which is a byte with a number of ones equal to
  # the current value of t2.

  # To generate a binary value with X number of 1s, you simply take the value 1
  # and left shift it the number of 1s you want and then subtract 1.
  # If we wanted the value 0b111111, which is 6 1s, we would left shift 1 by 6
  # and subtract 1:

  # (1 << 6) - 1
  # aka. (1000000 - 1) = 111111

  li    t3, 1
  sll   t3, t3, t2
  add   t2, t3, -1
  
  add   t0, t0, t1
  sb    t2, 0(t0)

  # Our bitmap is set up!
  # We can now allocate free pages of RAM upon request.

  pop   s1
  pop   s0
  pop   ra
  jr    ra

# memory_get_bitmap_size(): Returns the space taken up by our bitmap.
#
# Returns
#   a0: The size in bytes of the bitmap data structure.
memory_get_bitmap_size:
  la    a0, memory_bitmap_size
  ld    a0, 0(a0)
  jr    ra

# memory_alloc_page(): Returns a free page.
#
# Note: It does not clear the page itself. That page will have whatever was
#       already in it.
#
# Returns
#   a0: The address of a now allocated page. -1 if no memory left.
memory_alloc_page:
  push  ra
  push  s0

  # Find a free page in our bitmap and allocate it.

  # Search the bitmap for a non 0xff byte
  # Not very efficient :) could look for words/dwords the same way!
  la    t0, memory_bitmap_addr
  ld    s0, 0(t0)

  bnez  s0, _foo
  ebreak

_foo:

  # Determine the end of our bitmap
  # (TODO: change this if we make the bitmap bigger)
  move  t3, s0
  li    t2, PAGE_SIZE
  add   t3, t3, t2

  # We are looking for 0xff
  li    t2, 0xff

  # Our current pointer will be at the beginning of the bitmap
  move  t0, s0
_memory_alloc_page_scan:
  # If our current pointer has surpassed the end of our bitmap, then we
  # have run out of memory.
  bgeu   t0, t3, _memory_alloc_page_error

  # Pull out a byte from our bitmap, compare with 0xff
  # If it is not 0xff, it must have a 0 within it somewhere.
  lbu   t1, 0(t0)
  bne   t1, t2, _memory_alloc_page_found_byte

  add   t0, t0, 1

  j     _memory_alloc_page_scan

_memory_alloc_page_error:
  la    a0, str_memory_error
  jal   console_writez

  li    a0, -1
  j     _memory_alloc_page_exit

_memory_alloc_page_found_byte:
  # Determine the PPN of the free page
  # Recall: t0 is the address of the byte within the bitmap containing a zero.
  #         t1 is the value of that byte
  #         s0 is the address of the bitmap

  # To do this, we will calculate the offset of this byte and multiply by 8
  # And then deterine the position of the 0 in the byte.
  sub   t2, t0, s0 # The byte position within the bitmap
  sll   t2, t2, 3  # The PPN of the first bit of the byte (multiply by 8)

  # We will assume t0 is our answer
  # To calculate the address, we multiply by the page size again
  move  a0, t2
  li    t3, PAGE_OFFSET # multiply by PAGE_SIZE
  sll   a0, a0, t3

  # Now to determine the position of the zero
  # Look at each bit until we find it

  # We will maintain the new value by maintain a shift amount in t3
  # And maintain a shifted marker in t0
  li    t3, 1
_memory_alloc_page_found_byte_scan:
  # If the first bit in the value is 0, exit
  # We will report t0
  and   t2, t1, 0x1
  beqz  t2, _memory_alloc_page_found_byte_commit

  # Shift it over and try again
  srl   t1, t1, 1
  
  # Shift over the bit we are checking
  sll   t3, t3, 1
  
  # Add another page to our address
  li    t2, PAGE_SIZE
  add   a0, a0, t2
  j _memory_alloc_page_found_byte_scan

_memory_alloc_page_found_byte_commit:
  # Update the byte
  lbu   t2, 0(t0)
  or    t2, t2, t3
  sb    t2, 0(t0)
  j     _memory_alloc_page_exit

_memory_alloc_page_exit:
  # Return the address.
  pop   s0
  pop   ra
  jr    ra

# memory_free_page(): Frees a previously allocated page
#
# Arguments
#   a0: The address of a previously allocated page.
memory_free_page:
  # Clear the given page via its physical address.
  # Determine the PPN (Physical Page Number) which is its page index.
  srl   a0, a0, PAGE_OFFSET
  
  # Determine the byte in question by dividing by 8
  srl   t0, a0, 3

  # Determine the bit position within the byte by masking
  and   t1, a0, 0x7

  # Get the bitmap address
  la    t2, memory_bitmap_addr
  ld    t2, 0(t2)

  srl   a0, a0, PAGE_OFFSET

  # Go to the byte in question
  add   t2, t2, t0

  # Craft the mask
  li    t3, 1
  sll   t1, t3, t1  #   1 << bit position
  not   t1, t1      # ~(1 << bit position)

  # Read the byte
  lbu   t3, 0(t2)

  # Clear the bit
  and   t3, t3, t1

  # Set the byte
  sb    t3, 0(t2)

  # Return
  jr    ra

.data
.balign 8, 0

# Our bitmap address.
memory_bitmap_addr:   .dword  0

# Our bitmap size.
memory_bitmap_size:   .dword  0

# The total available memory in RAM
memory_ram_size:      .dword  0

# Error messages
str_memory_error:     .string "Memory: Cannot allocate memory.\n"
