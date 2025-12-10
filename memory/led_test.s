# Negative offsets from x0:
#   -4(x0) -> 0xFFFFFFFC -> BLUE
#   -3(x0) -> 0xFFFFFFFD -> GREEN
#   -2(x0) -> 0xFFFFFFFE -> RED
#   -1(x0) -> 0xFFFFFFFF -> USER

# --- Clear all LEDs (write 0x00) ---
addi x1, x0, 0       # x1 = 0
sb   x1, -4(x0)      # BLUE  <- 0x00
sb   x1, -3(x0)      # GREEN <- 0x00
sb   x1, -2(x0)      # RED   <- 0x00
sb   x1, -1(x0)      # USER  <- 0x00

# --- Prepare value 0xFF for turning LEDs on ---
addi x2, x0, 255     # x2 = 0xFF

# --- Blue on ---
sb   x2, -4(x0)      # BLUE  <- 0xFF

