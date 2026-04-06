# ══════════════════════════════════════════════════════════════════════
#  fibonacci.s  —  RV32IM demo for your CPU
#
#  Computes fib(10) = 55, stores every fib number in data memory,
#  then does a few multiplication demos using the M-extension.
#
#  Register map
#  ─────────────────────────────────────────────────────────────────────
#  x1  (ra)  — return address / scratch
#  x2  (sp)  — (unused — no real stack needed)
#  x3  (t0)  — loop counter  i
#  x4  (t1)  — fib(i-2)      f_prev2
#  x5  (t2)  — fib(i-1)      f_prev1
#  x6  (t3)  — fib(i)        f_cur
#  x7  (t4)  — memory pointer (byte address)
#  x10 (a0)  — general scratch / function arg
#  x11 (a1)  — general scratch / function return
# ══════════════════════════════════════════════════════════════════════

# ── 1. Compute first 12 Fibonacci numbers ─────────────────────────────
#   fib(0)=0, fib(1)=1, fib(2)=1, fib(3)=2, … fib(11)=89

    addi  x4, x0, 0          # f_prev2 = 0   (fib 0)
    addi  x5, x0, 1          # f_prev1 = 1   (fib 1)
    addi  x3, x0, 10         # loop counter: we want fib(0)..fib(11)
    addi  x7, x0, 0          # mem pointer = 0 (byte offset)

    # Store fib(0) and fib(1) before the loop
    sw    x4, 0(x7)          # mem[0] = 0
    addi  x7, x7, 4
    sw    x5, 0(x7)          # mem[4] = 1
    addi  x7, x7, 4

fib_loop:
    beqz  x3, fib_done       # if counter == 0, exit

    add   x6, x4, x5         # f_cur = f_prev2 + f_prev1
    sw    x6, 0(x7)          # store to memory
    addi  x7, x7, 4          # advance pointer

    mv    x4, x5             # f_prev2 = f_prev1
    mv    x5, x6             # f_prev1 = f_cur
    addi  x3, x3, -1         # i--
    j     fib_loop

fib_done:
    # x5 now holds fib(11) = 89

# ── 2. Multiply demo using M-extension ────────────────────────────────
#   Compute 7 × 6 = 42 and store at mem[48]

    addi  x10, x0, 7
    addi  x11, x0, 6
    mul   x12, x10, x11      # x12 = 42
    sw    x12, 0(x7)         # mem[48] = 42
    addi  x7, x7, 4

# ── 3. Division & remainder ───────────────────────────────────────────
#   100 / 7 = 14 remainder 2

    addi  x10, x0, 100
    addi  x11, x0, 7
    div   x13, x10, x11      # x13 = 14
    rem   x14, x10, x11      # x14 = 2
    sw    x13, 0(x7)         # mem[52] = 14
    addi  x7, x7, 4
    sw    x14, 0(x7)         # mem[56] = 2
    addi  x7, x7, 4

# ── 4. Bubble sort (array of 5 elements) ─────────────────────────────
#  Array at mem[64..80]: [5, 3, 8, 1, 4]  → sorted: [1, 3, 4, 5, 8]

    addi  x15, x0, 64        # base address of array

    li    x16, 5
    sw    x16, 0(x15)
    li    x16, 3
    sw    x16, 4(x15)
    li    x16, 8
    sw    x16, 8(x15)
    li    x16, 1
    sw    x16, 12(x15)
    li    x16, 4
    sw    x16, 16(x15)

    # Outer loop: i = 4 down to 1
    addi  x17, x0, 4         # outer counter

outer:
    beqz  x17, sorted
    addi  x18, x0, 0         # inner counter j = 0
    mv    x20, x15           # pointer = base

inner:
    bge   x18, x17, next_outer
    lw    x21, 0(x20)        # load arr[j]
    lw    x22, 4(x20)        # load arr[j+1]
    ble   x21, x22, no_swap  # if arr[j] <= arr[j+1], skip
    # swap
    sw    x22, 0(x20)
    sw    x21, 4(x20)
no_swap:
    addi  x20, x20, 4
    addi  x18, x18, 1
    j     inner

next_outer:
    addi  x17, x17, -1
    j     outer

sorted:
    # Sorted array is now in mem[64..80]
    # x1=ra will hold last JAL return addr — let's put fib(11) in x1 for debug
    mv    x1, x5             # x1 = 89  (visible in dbg_x1)
    mv    x2, x12            # x2 = 42  (visible in dbg_x2)
    mv    x3, x13            # x3 = 14  (visible in dbg_x3)

# ── 5. Infinite spin (don't fall off the end) ─────────────────────────
spin:
    j spin