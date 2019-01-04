# This file implements a random number generator. This implementation stays true
# to the MARS system calls where you can have multiple seeds ongoing at the same
# time.

.include "const.s"
.include "util.s"

.global random_set_seed
.global random_get_word

.text

# The maximum number of ongoing RNGs we can have
.set MAX_RNG, 1024

# The RNG parameters for a naive type-0 random number generator
.set A,    1103515245
.set C,    12345
.set MASK, 0x7fffffff

# random_set_seed(rng_id, seed): Sets the seed of the given generator.
#
# Arguments
#   a0: The random number generator id
#   a1: The seed to set this RNG to
random_set_seed:
  push  ra

  # Look up the RNG by id
  jal   random_lookup_rng_id

  # Mask the seed
  li    t0, MASK
  and   a1, a1, t0

  # Store the seed
  sw    a1, 0(a0)

  # Return
  pop   ra
  jr    ra

# random_get_word(rng_id): Gets the next random word for the given RNG id.
#
# Arguments
#   a0: The random number generator id
#
# Returns
#   a0: An unsigned random word
random_get_word:
  push  ra

  # Look up the RNG by id
  jal   random_lookup_rng_id

  # Manipulate that current value
  lwu   t0, 0(a0)

  li    t1, A
  mul   t0, t0, t1
  li    t1, C
  add   t0, t0, t1

  # Mask, Set it back
  li    t1, MASK
  and   t0, t0, t1
  sw    t0, 0(a0)

  # Return it
  move  a0, t0

  pop   ra

# random_lookup_rng_id(rng_id): Finds the address of the current rng seed.
#
# Arguments
#   a0: The random number generator id.
#
# Returns
#   a0: The address of the seed, or the next available.
random_lookup_rng_id:
  # Look up the RNG by id
  la    t0, random_current_rng_ids
  la    t1, random_total_used
  ld    t1, 0(t1)

_random_lookup_rng_id_loop:
  beqz  t1, _random_lookup_rng_id_break
  lwu   t2, 0(t0)
  beq   t2, a0, _random_lookup_rng_id_break

  add   t0, t0, -4
  add   t1, t1, -1
  j     _random_lookup_rng_id_loop
_random_lookup_rng_id_break:
  # Get the offset into the array
  la    t2, random_current_rng_ids
  sub   t0, t0, t2
  # And add that to the seeds pointer
  la    t2, random_current_seeds
  add   a0, t2, t0
  # If this is a newly allocated one, acquire a seed first
  bnez  t1, _random_lookup_rng_id_exit
  # TODO: get the system time, here
  sw    zero, 0(a0)
  # Increment counter (unless we have consumed the maximum total)
  la    t1, random_total_used
  ld    t2, 0(t1)
  li    t0, MAX_RNG
  beq   t0, t2, _random_lookup_rng_id_exit
  add   t2, t2, 1
  sw    t2, 0(t1)

_random_lookup_rng_id_exit:
  # Return a0, the address to the seed pointer requested
  # (or the next available one)
  jr    ra

.data
.balign 8, 0

# Have a page of possible ids
random_current_rng_ids:   .fill   MAX_RNG, 4, 0

# Have a page of possible ongoing seeds
random_current_seeds:     .fill   MAX_RNG, 4, 0

# How many RNGs are being used (max: MAX_RNG)
random_total_used:        .dword  0
