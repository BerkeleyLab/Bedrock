.global main
.global start
.global _bss_start
.global _bss_end
# ---------------------------------------------------------------------------------------
#  Simple init routine to run C programs (no interrupts supported)
# ---------------------------------------------------------------------------------------
.section .text
start:
    lui   t0,     %hi(_bss_start)
    addi  t0, t0, %lo(_bss_start)
    lui   t1,     %hi(_bss_end)
    addi  t1, t1, %lo(_bss_end)
    # If _bss_start >= _bss_end: skip initBss
    bgeu  t0, t1, initRegs
initBss:
    # zero initialize .bss section
    sw   zero, 0(t0)
    addi t0, t0, 4
    blt  t0, t1, initBss
initRegs:
    # zero initialize all CPU registers
    # x0 is always zero
    # x1 is the return address (ra)
    # x2 is stack pointer (sp)
    addi x3, zero, 0
    addi x4, zero, 0
    addi x5, zero, 0
    addi x6, zero, 0
    addi x7, zero, 0
    addi x8, zero, 0
    addi x9, zero, 0
    addi x10, zero, 0
    addi x11, zero, 0
    addi x12, zero, 0
    addi x13, zero, 0
    addi x14, zero, 0
    addi x15, zero, 0
    addi x16, zero, 0
    addi x17, zero, 0
    addi x18, zero, 0
    addi x19, zero, 0
    addi x20, zero, 0
    addi x21, zero, 0
    addi x22, zero, 0
    addi x23, zero, 0
    addi x24, zero, 0
    addi x25, zero, 0
    addi x26, zero, 0
    addi x27, zero, 0
    addi x28, zero, 0
    addi x29, zero, 0
    addi x30, zero, 0
    addi x31, zero, 0
    li  sp, BLOCK_RAM_SIZE    # Set stack pointer to last byte in memory + 1 of user app
    addi sp,sp,-16
    sw zero,0(sp)
    sw zero,4(sp)
    sw zero,8(sp)
    sw zero,12(sp)
    jal ra, main              # call main()
    ebreak                    # returned from main, put on the ebreak

# extern uint64_t _picorv32_rd_cycle_64(void);
.globl _picorv32_rd_cycle_64
_picorv32_rd_cycle_64:
    rdcycleh     a1
    rdcycle      a0
    rdcycleh     t0
    bne          a1, t0, _picorv32_rd_cycle_64
    ret
