#ifndef UART_H
#define UART_H

#include <stdint.h>
#include "common.h"

// UART special function register offsets (add to the base address from main.h to select the UART)
#define REG_UART_TX                 0x00
#define REG_UART_STATUS             0x04
#define REG_UART_RX                 0x08
#define REG_UART_BAUDRATE           0x0C

// Bitmask of UART_STATUS
#define BIT_UART_TX_BUSY            (1<<0)
#define BIT_UART_RX_BUSY            (1<<1)
#define BIT_UART_RX_ERROR_OVERRUN   (1<<2)
#define BIT_UART_RX_ERROR_FRAME     (1<<3)

// Return codes from UART_GETC() in the high byte
#define UART_DATA_OK        0x0000
#define UART_NO_NEW_DATA    0xFF00
#define UART_IS_DATA_OK(x) ((x&0xFF00)==UART_DATA_OK)  // data is ok when the msb 16 bits are zero

//-------------------------
// UART access macros
//-------------------------
// Setup the baudrate register
#define UART_INIT(uartBaseAddr,baudRate)    SET_REG( uartBaseAddr+REG_UART_BAUDRATE, (F_CLK/(baudRate*8)))

// Poll RX UART. Returns 16 bit value: high byte = status (UART_DATA_OK, UART_NO_NEW_DATA),  low byte = received data value
#define UART_GETC(uartBaseAddr)             ( (uint16_t)(GET_REG(uartBaseAddr+REG_UART_RX)) )

// Returns > 0 If the UART is currently busy transmitting something
#define UART_TX_IS_BUSY(uartBaseAddr)       (GET_REG(uartBaseAddr+REG_UART_STATUS)&BIT_UART_TX_BUSY)

// Send c to TX UART through FIFO. Stalls CPU if FIFO is full.
#define UART_PUTC(uartBaseAddr,c)           (SET_REG(uartBaseAddr+REG_UART_TX,c))

// Send c to TX UART. Blocks if UART is busy.
#define UART_PUTC_BLK(uartBaseAddr,c)       { while(UART_TX_IS_BUSY(uartBaseAddr)); SET_REG(uartBaseAddr+REG_UART_TX,c); }
#endif
