#include "settings.h"
#----------------------------
# Picorv32 serial bootloader
#----------------------------
# send:    "ok\n"
# receive: "g"                         Wait max. BOOTLOADER_DELAY cycles, then jump into user app
# send:    "o\n"
# receive: <N[3]><N[2]><N[1]><N[0]>    N = number of bytes to write to mem
# receive: <D[0]> ...      <D[N-1]>    Receive data and write it to mem starting at _startup_adr
# send:    <D[0]> ...      <D[N-1]>    Send back mem data for verification
# wait for uart_busy bit
# jump into user app at _startup_adr

# fixed values:
# t5 = '\n'
# t6 = 'o'
# gp = BASE_UART0

    j start_bootloader

# forward interrupt vector to the user app
.balign 0x10
    j _startup_adr + 0x10

start_bootloader:
    # Set UART baud-rate register
    li    gp, BASE_UART0
    li    t0, F_CLK / (BOOTLOADER_BAUDRATE * 8)
    sw    t0, 0x0C(gp)

    # Write ook\n
    li    t5, '\n'
    li    t6, 'o'
    sw    t6, 0x00(gp)
    sw    t6, 0x00(gp)
    li    t0, 'k'
    sw    t0, 0x00(gp)
    sw    t5, 0x00(gp)

    # Wait for start character
    li    t0, 'g'            # the start char. to wait for
    li    t1, 0              # t1 = 0, timeout counter
    li    t2, BOOTLOADER_DELAY# t2 max. timeout count
wait_loop:
    bgeu  t1, t2, finished   # if( t1 > max. timeout ) goto finished
    addi  t1, t1, 1          # t1++
    lw    t3, 0x08(gp)       # Get character from UART into t3
    bne   t3, t0, wait_loop  # check t3 != 'g'

    # When we are here, we have received 'g' and not timed out
    # send: o\n
    sw    t6, 0x00(gp)
    sw    t5, 0x00(gp)

    # Read number of bytes to write into t4
    jal   ra, waitForChar
    slli  t4, a0, 24         #t4 = waitForChar()<<24;
    jal   ra, waitForChar
    slli  a0, a0, 16         #a0 = waitForChar()<<16;
    or    t4, t4, a0         #t4 |= a0
    jal   ra, waitForChar
    slli  a0, a0,  8         #a0 = waitForChar()<<8;
    or    t4, t4, a0         #t4 |= a0
    jal   ra, waitForChar
    or    t4, t4, a0         #t4 |= a0
    # sw    t4, 0(gp)          #send it out for debugging
    # ebreak

    # write t4 bytes to memory at sp
    lui   sp,     %hi(_startup_adr)# sp = begin of user program memory
    addi  sp, sp, %lo(_startup_adr)
    add   t0, sp, t4         # t0 = sp + t4 (memory write end pointer)
writeLoop:
    jal   ra, waitForChar    # receive byte in a0
    sb    a0, 0(sp)          # write it to memory at sp
    addi  sp, sp, 1          # sp++
    bltu  sp, t0, writeLoop  # while (sp<t0)

    # read back t4 bytes from sp to uart
    lui   sp,     %hi(_startup_adr)# sp = begin of user program memory
    addi  sp, sp, %lo(_startup_adr)
    add   t0, sp, t4         # t0 = sp + t4 (memory read end pointer)
readLoop:
    lbu   a0, 0(sp)          # load byte from memory at sp
    sw    a0, 0(gp)          # send it to UART
    addi  sp, sp, 1          # sp++
    bltu  sp, t0, readLoop   # while (sp < t0)
uartBusyLoop:
    lw    a0, 4(gp)          # a0 = uart_status_word
    andi  a0, a0, 1          # a0 &= 1 (bit 0 = tx_busy)
    blt   zero, a0, uartBusyLoop # while (0 < a0)

finished:
    j     _startup_adr       # Jump into main USER app

# Block until UART0 has received a byte, then return it in a0, overwrites t1.
waitForChar:
    li    t1, 0xFF00
waitForCharLoop:
    lw    a0, 0x08(gp)            # Get character from UART into a0
    bgeu  a0, t1, waitForCharLoop # Check if it is >= 0xFF00 (no new data)
    ret                           # Otherwise return(a0)
