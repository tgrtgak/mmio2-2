  li    s0, 0x00 # hue
  li    s1, 0xff # saturation
  li    s2, 0x80 # light value
  li    s3, 0x90000000 # framebuffer address
  li    s4, 640 # width
  li    s5, 480 # height
  li    s6, 0 # x
  li    s7, 0 # y

_foo_x:
  # calculate pixel color
  move  a0, s6
  li    t0, 0xff
  rem   a0, a0, t0
  move  a1, s1
  move  a2, s7
  li    t0, 0xff
  rem   a2, a2, t0
  blt   s7, t0, _foo_x_skip
  sub   a2, t0, a2
_foo_x_skip:
  jal   hsv_to_rgb
  move  s8, a0
  move  s9, a1
  move  s10, a2
  move  t0, a0
  sll   t0, t0, 8
  move  t1, a1
  or    t0, t0, t1
  sll   t0, t0, 8
  move  t1, a2
  or    t0, t0, t1
  
  li    t1, 0xff # alpha
  sll   t1, t1, 24
  or    t0, t0, t1
  sw    t0, 0(s3) # set pixel
  
  add   s0, s0, 1 # next hue
  li    t0, 0xff
  rem   s0, s0, t0 # cycle the hue

  add   s6, s6, 1 # goto next x
  add   s3, s3, 4 # goto next pixel
  
  beq   s4, s6, _foo_x_exit
  j     _foo_x
  
_foo_x_exit:
  add   s7, s7, 1 # goto next y
  li    s6, 0     # x starts at 0 again
  
  beq   s5, s7, _foo_y_exit
  
  j     _foo_x
  
_foo_y_exit:
  li    a7, 10
  ecall

hsv_to_rgb:
  add   sp, sp, -8
  sd    ra, 0(sp)
  add   sp, sp, -8
  sd    s0, 0(sp)
  add   sp, sp, -8
  sd    s1, 0(sp)
  add   sp, sp, -8
  sd    s2, 0(sp)
  add   sp, sp, -8
  sd    s3, 0(sp)
  add   sp, sp, -8
  sd    s4, 0(sp)

  # Check if the color is Grayscale

  # if S == 0:
  bnez  a1, _hsv_to_rgb_continue
  #   R = V
  #   G = V
  #   B = V
  move  a0, a2
  move  a1, a2
  #   return (R, G, B)
  j _hsv_to_rgb_exit
  
_hsv_to_rgb_continue:

  # Make hue 0-5
  # region (s0) = H // 43;
  li    t0, 43
  div   s0, a0, t0

  # Find remainder part, make it from 0-255
  # remainder (s1) = (H - (region * 43)) * 6; 
  li    t0, 43
  mul   t0, s0, t0
  sub   t0, a0, t0  # t0 = (H - (region * 43))
  li    t1, 6
  mul   s1, t0, t1  # remainder (s1) = t0 * 6

  # Calculate temp vars, doing integer multiplication
  # P (s2) = (V * (255 - S)) >> 8;
  li    t0, 255
  sub   t0, t0, a1
  mul   t0, t0, a2
  srl   s2, t0, 8
  # Q (s3) = (V * (255 - ((S * remainder) >> 8))) >> 8;
  li    t0, 255
  mul   t1, a1, s1  # t1 = S * remainder
  srl   t1, t1, 8   # t1 >>= 8
  sub   t0, t0, t1  # t0 = 255 - t1
  mul   t0, a2, t0  # t0 *= V
  srl   s3, t0, 8   # s3 >>= 8
  # T (s4) = (V * (255 - ((S * (255 - remainder)) >> 8))) >> 8;
  li    t1, 255
  sub   t0, t1, s1  # t0 = 255 - remainder
  mul   t0, t0, a1  # t0 *= S
  srl   t0, t0, 8   # t0 >>= 8
  sub   t0, t1, t0  # t0 = 255 - t0
  mul   t0, t0, a2  # t0 *= V
  srl   s4, t0, 8   # s4 = t0 >> 8

  # Assign temp vars based on color cone region
  
_hsv_to_rgb_region0:
  # if region == 0:
  bnez  s0, _hsv_to_rgb_region1
  #   R = V
  #   G = T
  #   B = P
  move  a0, a2
  move  a1, s4
  move  a2, s2
  j _hsv_to_rgb_exit

_hsv_to_rgb_region1:
  # elif region == 1:
  li    t0, 1
  bgt   s0, t0, _hsv_to_rgb_region2
  #   R = Q;
  #   G = V; 
  #   B = P;
  move  a0, s3
  move  a1, a2
  move  a2, s2
  j _hsv_to_rgb_exit

_hsv_to_rgb_region2:
  # elif region == 2:
  li    t0, 2
  bgt   s0, t0, _hsv_to_rgb_region3
  #   R = P; 
  #   G = V; 
  #   B = T;
  move  a0, s2
  move  a1, a2
  move  a2, s4
  j _hsv_to_rgb_exit

_hsv_to_rgb_region3:
  # elif region == 3:
  li    t0, 3
  bgt   s0, t0, _hsv_to_rgb_region4
  #   R = P; 
  #   G = Q; 
  #   B = V;
  move  a0, s2
  move  a1, s3
  move  a2, a2
  j _hsv_to_rgb_exit

_hsv_to_rgb_region4:
  # elif region == 4:
  li    t0, 4
  bgt   s0, t0, _hsv_to_rgb_region5
  #   R = T; 
  #   G = P; 
  #   B = V;
  move  a0, s4
  move  a1, s2
  move  a2, a2
  
  j _hsv_to_rgb_exit
  
_hsv_to_rgb_region5:
  # else: 
  #   R = V; 
  #   G = P; 
  #   B = Q;
  move  a0, a2
  move  a1, s2
  move  a2, s3

_hsv_to_rgb_exit:
  #return (R, G, B)
  ld    s4, 0(sp)
  add   sp, sp, 8
  ld    s3, 0(sp)
  add   sp, sp, 8
  ld    s2, 0(sp)
  add   sp, sp, 8
  ld    s1, 0(sp)
  add   sp, sp, 8
  ld    s0, 0(sp)
  add   sp, sp, 8
  ld    ra, 0(sp)
  add   sp, sp, 8
  jr    ra
