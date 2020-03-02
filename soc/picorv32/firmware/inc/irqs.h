#ifndef IRQS_H
#define IRQS_H

// --------------------------------------------------------------
//  Interrupt mapping
// --------------------------------------------------------------
// Irq 0-15 = level triggered. Irq 16-31 rising edge triggered
#define IRQ_TIMER0       0x00
#define IRQ_EBREAK       0x01
#define IRQ_BUSERR       0x02
#define IRQ_UART0_RX     0x03      //IRQ when byte received. Cleared when byte read from UART_RX_REG
//#define IRQ_UART0_TX     0x04    //IRQ on IDLE?
#define IRQ_UART1_RX     0x05      //IRQ when byte received. Cleared when byte read from UART_RX_REG
//#define IRQ_UART1_TX     0x06

// --------------------------------------------------------------
//  IRQ assembler functions (see start.S)
// --------------------------------------------------------------
// setting a bit in `iMask` disables the corresponding interrupt
// returns the previous interrupt mask
extern uint32_t _picorv32_irq_mask( uint32_t iMask );

// Disable individual interrupts by setting specific bits in the interrupt mask register
// returns the current interrupt mask
extern uint32_t _picorv32_irq_disable( uint32_t irqsToDisable );

// Enable individual interrupts by clearing specific bits in the interrupt mask register
// returns the current interrupt mask
extern uint32_t _picorv32_irq_enable( uint32_t irqsToEnable );

// loads the timer with `tVal`. Counting down with every instruction,
// it will trigger `IRQ_TIMER0` and stop once it reaches zero
// returns the previous timer value before the reload
extern uint32_t _picorv32_irq_timer( uint32_t tVal );

// for testing how to in- and output values to GCC
// a0 = first argument & return value
// a1 = second argument
extern uint32_t _asm_test( uint32_t inpa, uint32_t inpb );

// reset (jump to address 0) from within an interrupt
extern void _picorv32_irq_reset(void);


// --------------------------------------------------------------
// Interrupt handler
// --------------------------------------------------------------
// called for all 32 interrupts
// *regs = context save X-registers
// irqs = q1 = bitmask of all IRQs to be handled
// For the level interrupts (0-15), the ISR must make sure the interrupt is
// cleared before returning (by reading the UART data register for example),
// else it will trigger again right away.
uint32_t *irq(uint32_t *regs, uint32_t irqs);

#endif
