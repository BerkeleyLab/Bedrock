// --------------------------------------------------------
//  Low level Modbus client library
// --------------------------------------------------------
// Can send and receive Modbus frames with CRC check and symbol timeouts
// Payload consists of a one byte function code and a n-byte data block

#ifndef MY_MODBUS_CLIENT_H
#define MY_MODBUS_CLIENT_H

#include <stdint.h>
#include <stdbool.h>

// in settings.h
// #define MODBUS_UART      BASE_UART0
// #define MODBUS_BAUDRATE  115200

// Slave devices are assigned addresses in the range of 1 - 247
// Address 0 is used for the broadcast address, which all slave devices recognize.
// For now we ignore broadcast addresses
#define MODBUS_CLIENT_ADDRESS 1
#define MODBUS_BUFFER_SIZE (32*2+5)                          //Maximum length (in bytes) of a TX or RX Modbus frame
#define MODBUS_TIMEOUT_CYCLES (3*10LL*F_CLK/MODBUS_BAUDRATE) //Minimum RX pause to recognize the end of a modbus frame [CPU_CLK_CYCLES]

void modbusPutC( uint8_t c );

// This function must be called regularly in the main loop.
// Speaks to UART, receives single bytes and handles the timeout between frames
// Calls processModbusRxFrame() once a complete frame is received
void modbusPoll( void );

// Callback function when a new valid modbus frame is received.
// It's up to the user, to figure out what to do with this data
void processModbusPayload( uint8_t *frameBuffer, uint8_t functionCode );

// Send out the payloadBuffer as a valid modbus frame with Address, functionCode and CRC. Blocks.
// if isPrependNbytes is True, the number of payload bytes is prepended before the payload starts
void sendModbusFrame( uint8_t *payloadBuffer, uint16_t nBytes, uint8_t functionCode, bool isPrependNbytes );

// Send out error for current frame
void send_modbus_exception( uint8_t functionCode, uint8_t error_code);

// --------------------------------------------------------
//  Internal stuff
// --------------------------------------------------------
// convert data at `buffer` to a unsigned integer with big endian of len=1..4 bytes
uint32_t extractUint( uint8_t *buffer, uint8_t len );
// convert data at `buffer` to a signed integer with big endian of len=1..4 bytes
int32_t extractInt( uint8_t *buffer, uint8_t len );
// convert `len=1..4` bytes at buffer to an unsigned integer with little endian
uint32_t extractUintLE( uint8_t *buffer, uint8_t len );

// Modbus function codes [from](http://modbus.org/docs/PI_MBUS_300.pdf)
#define MODBUS_READ_COIL_STATUS           1 //groups of 8-bit
#define MODBUS_READ_INPUT_STATUS          2
#define MODBUS_READ_HOLDING_REGISTERS     3 //read multiple 16 bit words, big endian
#define MODBUS_READ_INPUT_REGISTERS       4
#define MODBUS_FORCE_SINGLE_COIL          5
#define MODBUS_PRESET_SINGLE_REGISTER     6
#define MODBUS_READ_EXCEPTION_STATUS      7
#define MODBUS_DIAGNOSTICS                8
#define MODBUS_PROGRAM                    9
#define MODBUS_POLL                      10
#define MODBUS_FETCH_COMM_EVENT_CTR      11
#define MODBUS_FETCH_COMM_EVENT_LOG      12
#define MODBUS_PROGRAM_CONTROLLER        13
#define MODBUS_POLL_CONTROLLER           14
#define MODBUS_FORCE_MULTIPLE_COILS      15
#define MODBUS_PRESET_MULTIPLE_REGISTERS 16 //write multiple 16 bit words, big endian
#define MODBUS_REPORT_SLAVE_ID           17
#define MODBUS_PROGRAM_884_M84           18
#define MODBUS_RESET_COMM_LINK           19
#define MODBUS_READ_GENERAL_REFERENCE    20
#define MODBUS_WRITE_GENERAL_REFERENCE   21
#define MODBUS_MASK_WRITE_4X_REGISTER    22
#define MODBUS_READ_WRITE_4X_REGISTERS   23
#define MODBUS_READ_FIFO_QUEUE           24
// Modbus exception code. To be ORed with the received function code
#define MODBUS_EXCEPTION                 0x80

#endif
