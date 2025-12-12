# Turn off all LEDs (blue, green, red, user LED)
addi  x3, x0, 0          # x3 = 0
sb    x3, -4(x0)         # LED blue
sb    x3, -3(x0)         # LED green
sb    x3, -2(x0)         # LED red
sb    x3, -1(x0)         # LED user

# Initial LED ON, set state = 1
addi  x3, x0, 255        # x3 = 255 (100% PWM LED on)
sb    x3, -1(x0)         # write brightness to user LED
addi  x2, x0, 1          # x2 = 1 (state = LED ON)

# Compute next toggle time: next = millis + 500
lw   x5, -8(x0)         # x5 = millis
addi  x9, x5, 500        # x9 = target time miilis + 500

# Start Loop
lw    x6, -8(x0)         # load current millis
bltu  x6, x9, -4         # if x6 < x9 jump back to lw x6

# Decide whether to turn LED on or off based on x2
beq   x2, x0, 28         # if (state == 0) skip ahead to LED on block

# Turn LED off
addi  x3, x0, 0          # x3 = 0 turn LED OFF
sb    x3, -1(x0)         # write LED value
addi  x2, x0, 0          # state = 0 (LED now OFF)
addi  x5, x6, 0          # x5 = current millis
addi  x9, x5, 500        # x9 = next toggle time
jal   x0, -32            # jump back to start loop

# Turn LED on
addi  x3, x0, 255        # x3 = 255 turn LED ON
sb    x3, -1(x0)         # write LED value
addi  x2, x0, 1          # state = 1 (LED now ON)
addi  x5, x6, 0          # x5 = current millis
addi  x9, x5, 500        # x9 = next toggle time
jal   x0, -56            # jump back to start loop
