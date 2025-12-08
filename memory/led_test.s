# Set LEDs to known state
addi x1, x0, 0
sb x1, -3(x0)

# Turn user LED on
addi x2, x0, 0xFF
sw x2, -3(x0)

