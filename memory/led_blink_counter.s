# Initialize x1 to 1 for inner loop comparison
addi  x1, x0, 1          # x1 = 1

# Turn off all LEDs (blue, green, red, user LED) for initiation
addi  x3, x0, 0
sb    x3, -4(x0)
sb    x3, -3(x0)
sb    x3, -2(x0)
sb    x3, -1(x0)

# Main loop start
# Turn user LED ON, RGB OFF
sb    x3, -4(x0)
sb    x3, -3(x0)
sb    x3, -2(x0)
addi x3, x0, 255
sb   x3, -1(x0)

# Delay loop #1
addi  x4, x0, 15

# outer_loop:
addi  x5, x0, 2047
# inner_loop:
addi  x5, x5, -1
bne   x5, x1, -2
addi  x4, x4, -1
bne   x4, x1, -16

# Turn user LED OFF, RGB ON
sb    x3, -4(x0)
sb    x3, -3(x0)
sb    x3, -2(x0)
sb    x3, -1(x0)
addi x3, x0, 0
sb   x3, -1(x0)

# Delay loop #2
addi  x4, x0, 15
# outer2:
addi  x5, x0, 2047
# inner2:
addi  x5, x5, -1
bne   x5, x1, -2
addi  x4, x4, -1
bne   x4, x1, -16

# Jump back to main loop start
jal  x0, -92
