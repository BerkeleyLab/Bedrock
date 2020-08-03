# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
# ---------------------------------------------------------------------------------------
#  Init script to run C programs
# ---------------------------------------------------------------------------------------
# requires this function to be present in C program:
# uint32_t *irq(uint32_t *regs, uint32_t irqs){ return regs; }
#include "custom_ops.S"
.global irq
.global main
.global start

# The bootloader will jump to reset_vec on power-up
# theres only space for 16 bytes = 4 instructions, so jump into main quickly
.section .text
start:
	#picorv32_maskirq_insn( zero, zero )  # enable all 32 interrupt sources
	j init_for_c

#**********************************
#* Interrupt handler              *
#**********************************
# Only save registers in IRQ wrapper that are to be saved by the caller in
# the RISC-V ABI, with the excpetion of the stack pointer. The IRQ handler
# will save the rest if necessary. I.e. skip x3, x4, x8, x9, and x18-x27.
.balign 16
irq_vec:
	# save registers

	picorv32_setq_insn(q2, x1)
	picorv32_setq_insn(q3, x2)

	lui x1, %hi(irq_regs)
	addi x1, x1, %lo(irq_regs)

	picorv32_getq_insn(x2, q0)
	sw x2,   0*4(x1)

	picorv32_getq_insn(x2, q2)
	sw x2,   1*4(x1)

	picorv32_getq_insn(x2, q3)
	sw x2,   2*4(x1)


	sw x5,   5*4(x1)
	sw x6,   6*4(x1)
	sw x7,   7*4(x1)
	sw x10, 10*4(x1)
	sw x11, 11*4(x1)
	sw x12, 12*4(x1)
	sw x13, 13*4(x1)
	sw x14, 14*4(x1)
	sw x15, 15*4(x1)
	sw x16, 16*4(x1)
	sw x17, 17*4(x1)
	sw x28, 28*4(x1)
	sw x29, 29*4(x1)
	sw x30, 30*4(x1)
	sw x31, 31*4(x1)

	# call interrupt handler C function

	lui sp, %hi(irq_stack)
	addi sp, sp, %lo(irq_stack)

	# arg0 = address of regs
	lui a0, %hi(irq_regs)
	addi a0, a0, %lo(irq_regs)

	# arg1 = interrupt type
	picorv32_getq_insn(a1, q1)

	# call to C function
	jal ra, irq

	# restore registers

	# new irq_regs address returned from C code in a0
	addi x1, a0, 0

	lw x2,   0*4(x1)
	picorv32_setq_insn(q0, x2)

	lw x2,   1*4(x1)
	picorv32_setq_insn(q1, x2)

	lw x2,   2*4(x1)
	picorv32_setq_insn(q2, x2)

	lw x5,   5*4(x1)
	lw x6,   6*4(x1)
	lw x7,   7*4(x1)
	lw x10, 10*4(x1)
	lw x11, 11*4(x1)
	lw x12, 12*4(x1)
	lw x13, 13*4(x1)
	lw x14, 14*4(x1)
	lw x15, 15*4(x1)
	lw x16, 16*4(x1)
	lw x17, 17*4(x1)
	lw x28, 28*4(x1)
	lw x29, 29*4(x1)
	lw x30, 30*4(x1)
	lw x31, 31*4(x1)

	picorv32_getq_insn(x1, q1)
	picorv32_getq_insn(x2, q2)

	picorv32_retirq_insn()

init_for_c:
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
	li  sp, BLOCK_RAM_SIZE          # Set stack pointer to last byte in memory + 1 of user app
	addi sp,sp,-16
	sw zero,0(sp)
	sw zero,4(sp)
	sw zero,8(sp)
	sw zero,12(sp)
	jal ra, main              # call main()
	ebreak                    # returned from main, put on the ebreak

#-----------------------------------------------
# C-wrappers for the custom instructions
#-----------------------------------------------
# extern uint32_t _asm_test( uint32_t inpa, uint32_t inpb );
# for testing how to in- and output values to GCC
# a0 = first argument & return value
# a1 = second argument
# .globl _asm_test
# _asm_test:
# 	addi a0, a1, 0  # return( inpb );
# 	ret

# extern uint64_t _picorv32_rd_cycle_64(void);
.globl _picorv32_rd_cycle_64
_picorv32_rd_cycle_64:
	rdcycleh     a1
	rdcycle      a0
	rdcycleh     t0
	bne          a1, t0, _picorv32_rd_cycle_64
	ret

# extern uint32_t _picorv32_irq_mask( uint32_t iMask );
# setting a bit in `iMask` disables the corresponding interrupt
# returns the previous interrupt mask
.globl _picorv32_irq_mask
_picorv32_irq_mask:
	picorv32_maskirq_insn(a0, a0)
	ret

# extern uint32_t _picorv32_irq_disable( uint32_t irqsToDisable );
# Disable individual interrupts by setting specific bits in the interrupt mask register
# returns the current interrupt mask
.globl _picorv32_irq_disable
_picorv32_irq_disable:
	li t0, 0xFFFFFFFF
	picorv32_maskirq_insn(t0, t0)     # t0 = currentMask, also disable all interrupts
	or a0, a0, t0                     # a0 = bitsToSet | t0
	picorv32_maskirq_insn(zero, a0)   # set new interrupt mask
	ret                               # return( a0 );

# extern uint32_t _picorv32_irq_enable( uint32_t irqsToEnable );
# Enable individual interrupts by clearing specific bits in the interrupt mask register
# returns the current interrupt mask
.globl _picorv32_irq_enable
_picorv32_irq_enable:
	li t0, 0xFFFFFFFF
	xor a0, a0, t0                    # a0 = ~bitsToClear;
	picorv32_maskirq_insn(t0, t0)     # t0 = currentMask, also disable all interrupts
	and a0, a0, t0                    # a0 = a0 & currentMask
	picorv32_maskirq_insn(zero, a0)   # set new interrupt mask
	ret                               # return( a0 );

# extern void _picorv32_irq_reset(void);
# reset (jump to address 0) from within an interrupt
.globl _picorv32_irq_reset
_picorv32_irq_reset:
	li t0, 0xFFFFFFFF
	picorv32_maskirq_insn(zero, t0)   # disable all interrupts
	picorv32_setq_insn(q0, zero)      # set return address to 0
	picorv32_retirq_insn()            # return from interrupt jump to 0

# extern uint32_t _picorv32_irq_timer( uint32_t tVal );
# loads the timer with `tVal`. Counting down with every instruction,
# it will trigger int0 and stop once it reaches zero
# returns the previous timer value before the reload
.globl _picorv32_irq_timer
_picorv32_irq_timer:
	picorv32_timer_insn(a0, a0)
	ret

# IRQ stack
.section .bss
irq_regs:
	# registers are saved to this memory region during interrupt handling
	# the program counter is saved as register 0
	.fill 32,4

	# stack for the interrupt handler
	.fill 128,4
irq_stack:
