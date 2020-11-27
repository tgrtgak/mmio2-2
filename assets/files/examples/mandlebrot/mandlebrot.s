    # The definition. Higher values take longer, but offer more crispness
    .set    ITERATION_MAX, 50
    
    # The width of the display
    .set    DISPLAY_WIDTH, 640
    
    # The height of the display
    .set    DISPLAY_HEIGHT, 480
    
.data
    cxmin: .double -0.5
    cxmax: .double 0.5
    cymin: .double -1.0
    cymax: .double -0.25
    
.text

main:
    # Draw the mandlebrot fractal
    jal     mandlebrot
    
    # exit() system call
    li      a7, 10
    ecall

mandlebrot:
    # Preserve conventional registers s0, s1, s2, and s3
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
    
    # Get the address of the graphical display
    li      s3, 0x90000000  # s3: well-known framebuffer address
    
    # Pull out cxmin/cxmax/cymin/cymax
    # These define the upper left and lower-right coordinates of the world
    la      t0, cxmin
    fld     fs0, 0(t0)
    
    la      t0, cxmax
    fld     fs1, 0(t0)
    
    la      t0, cymin
    fld     fs2, 0(t0)
    
    la      t0, cymax
    fld     fs3, 0(t0)
    
    # Next, we get the ratio difference between the world coordinates and our
    # screen coordinates. We will calculate each pixel by doing some math based
    # on converting the coordinates from one system to the other.
    
    # pixelWidth = (cxMax - cxMin) / 640
    fsub.d  fs4, fs1, fs0
    li      t0, DISPLAY_WIDTH
    fcvt.d.l ft0, t0
    fdiv.d  fs4, fs4, ft0
    
    # pixelHeight = (cyMax - cyMin) / 480
    fsub.d  fs5, fs3, fs2
    li      t0, DISPLAY_HEIGHT
    fcvt.d.l ft0, t0
    fdiv.d  fs5, fs5, ft0
    
    # Now, we enter the nested loops. For each row (y) and then for each pixel (x)
    # we calculate number of fractal iterations are visible at that pixel. If they
    # exceed our maximum allowed iterations, we give up and cap it at that value.
    
    # We then, for each pixel, color that pixel by the number of iterations. Red
    # pixels have no iterations (external to the fractal) and blue have max iterations
    # (interal to the fractal) with colors in between in the rainbow reflecting fringe
    # areas of the fractal.
    
    # for (y = 0; y < 480; y++) {
    li      s1, 0
_mandlebrot_y_loop:
    li      t0, DISPLAY_HEIGHT
    bge     s1, t0, _mandlebrot_y_loop_exit
    
    # cy = cyMin + (y * pixelHeight)
    fcvt.d.l ft0, s1
    fmul.d  ft0, ft0, fs5
    fadd.d  fs7, fs2, ft0
    
    li      t0, 2
    fcvt.d.l ft0, t0
    fdiv.d  ft0, fs5, ft0
    fabs.d  ft1, fs7
    flt.d   t0, ft1, ft0
    # if (fabs(cy) < pixelHeight/2) {
    beqz    t0, _mandlebrot_y_loop_continue
    #   cy = 0.0
    fmv.d.x fs7, zero
_mandlebrot_y_loop_continue:
    # }
    
    # for (x = 0; x < DISPLAY_WIDTH; x++) {
    li      s0, 0
_mandlebrot_x_loop:
    li      t0, DISPLAY_WIDTH
    bge     s0, t0, _mandlebrot_x_loop_exit
    
    # cx = cxMin + (x * pixelWidth)
    fcvt.d.l ft0, s0
    fmul.d  ft0, ft0, fs4
    fadd.d  fs6, fs0, ft0
    
    # zx = 0.0
    fmv.d.x fs8, zero
    # zy = 0.0
    fmv.d.x fs9, zero
    # zx2 = zx * zx
    fmul.d  fs10, fs8, fs8
    # zy2 = zy * zy
    fmul.d  fs11, fs9, fs9
    
    # ER2 = 4.0
    # for (iteration = 0; iteration < iterationMax && ((zx2 + zy2) < ER2); iteration++) {
    li      s2, 0
_mandlebrot_iteration_loop:
    # check loop conditions
    li      t0, ITERATION_MAX
    bge     s2, t0, _mandlebrot_iteration_loop_exit
    
    fadd.d  ft0, fs10, fs11
    li      t0, 4
    fcvt.d.l ft1, t0
    flt.d   t0, ft0, ft1
    beqz    t0, _mandlebrot_iteration_loop_exit
    
    # zy = (2 * zx * zy) + cy
    li      t0, 2
    fcvt.d.l ft0, t0
    fmul.d  ft0, ft0, fs8
    fmul.d  ft0, ft0, fs9
    fadd.d  fs9, ft0, fs7
    
    # zx = zx2 - zy2 + cx
    fsub.d  ft0, fs10, fs11
    fadd.d  fs8, ft0, fs6
    
    # zx2 = zx * zx
    fmul.d  fs10, fs8, fs8
    
    # zy2 = zy * zy
    fmul.d  fs11, fs9, fs9
    
    # go to next iteration
    addi    s2, s2, 1
    j       _mandlebrot_iteration_loop
_mandlebrot_iteration_loop_exit:
    # }
    
    # hue = 170 * iteration / iterationMax
    fcvt.d.l ft0, s2
    li      t0, ITERATION_MAX
    fcvt.d.l ft1, t0
    fdiv.d  ft0, ft0, ft1
    li      t0, 170
    fcvt.d.l ft1, t0
    fmul.d  ft0, ft0, ft1
    fcvt.l.d a0, ft0
    
    # sat = 255
    li      a1, 255
    # val = 255
    li      a2, 255
    
    # hsv_to_rgb()
    jal     hsv_to_rgb
    
    # plot color
    sb      a0, 0(s3)
    sb      a1, 1(s3)
    sb      a2, 2(s3)
    li      t0, 0xff
    sb      t0, 3(s3)
    addi    s3, s3, 4

    addi    s0, s0, 1
    j       _mandlebrot_x_loop
_mandlebrot_x_loop_exit:
    # }
    
    addi    s1, s1, 1
    j       _mandlebrot_y_loop
_mandlebrot_y_loop_exit:
    # }
    
    # Clean up stack and return
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
    # return (R, G, B)
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
