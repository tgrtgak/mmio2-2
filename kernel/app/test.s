# Calculates a fibonacci sequence.

.global main

.text
main:
    li      a0, 8
    jal     fibonacci                   # n = fibonacci(8)

    move    t0, a0

    li      a0, 4
    la      a1, strResult
    ecall                               # printString(strResult)
    
    move    a1, t0
    li      a0, 1
    ecall                               # printInt(n)

    li      a0, 4
    la      a1, strNewline
    ecall                               # printString(strNewline)

    li      a0, 4
    la      a1, strResult
    ecall                               # printString(strResult)

    li      a0, 41
    li      a1, 0
    ecall                               # rand(0)

    li      a0, 41
    li      a1, 0
    ecall                               # rand(0)

    li      a0, 41
    li      a1, 0
    ecall                               # rand(0)

    li      a0, 41
    li      a1, 0
    ecall                               # rand(0)
    
    move    a1, a0
    li      a0, 1
    ecall                               # printInt(n)
    
    li      a0, 10
    li      a1, 0
    ecall                               # exit(0)

# fibonacci(n): Returns the fibonacci sequence requested.
# 
# Arguments
#   a0: (n) The index of the fibonacci number we want.
fibonacci:
    li      t0, 0                       # older = 0
    li      t1, 1                       # old   = 0
    move    t2, a0                      # counter = n
    
    # Return value is initially 0 (the value of t0)
    li      a0, 0                       # ret = 0
    
_fibonacci_loop:
    blez    t2, _fibonacci_exit         # while(counter > 0) {
    
    # Retain old value
    add     t3, t0, t1                  #   tmp = older + old
    move    t0, t1                      #   older = old
    move    t1, t3                      #   old = tmp
    add     t2, t2, -1                  #   counter = counter - 1

    # the result is in t0
    move    a0, t0                      #   ret = older
    
    j       _fibonacci_loop             # }
    
_fibonacci_exit:
    jr      ra                          # return ret

.data

strNewline: .string   "\n"
strResult:  .string   "Result... "
