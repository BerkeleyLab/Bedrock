.section .text
.global start

start:
    # Do a byte-wise write to memory
    li  gp, 0x04100000   # memory address
    li  t0, 'H'
    SW  t0, 0x04(gp)
    li  t0, 'e'
    SW  t0, 0x08(gp)
    li  t0, 'l'
    SW  t0, 0x10(gp)
    li  t0, 'l'
    SW  t0, 0x20(gp)
    li  t0, 'o'
    SW  t0, 0x0c(gp)
    # read back memory
    LW  t0, 0x00(gp)
    LW  t0, 0x04(gp)
    nop
    nop
    LW  t0, 0x08(gp)
    LW  t0, 0x0c(gp)
    li  t0, 't'
    SW  t0, 0x10(gp)
    LW  t0, 0x10(gp)

    jal blind

    # Add some blind instructions
blind:
    li  t0, 42
    loop:
    ADDI t0, t0, -1
    #SW t0, 0(gp)
    BNE  t0, zero, loop

    # The definite last instruction
    ebreak
