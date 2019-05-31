#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include "uart.h"
#include "timer.h"
#include "print.h"
#include "modbus_slave.h"

enum{
    IDLE,       //IDLE timer has expired. ready for receiving a new frame
    RX_FRAME,   //IDLE timer is running. We are in the process of receiving a frame
    REJECT_FRAME//Wait until the end of this frame
}modBusState = IDLE;

bool gDebugOutputFlags = false;
uint16_t gRunningCrc = 0xFFFF;          // Global variable to keep CRC state
#define resetRunnningCRC() {gRunningCrc=0xFFFF;}

// put 1 character of modbus data on the UART and print to debug Output if debug switch is On
void modbusPutC( uint8_t c ){
    UART_PUTC(MODBUS_UART, c);
    if ( gDebugOutputFlags ){
        print_hex(c, 2);
        print_str(" ");
    }
}

// convert `len=1..4` bytes at buffer to an unsigned integer with big endian
uint32_t extractUint( uint8_t *buffer, uint8_t len ){
    uint32_t tmp=0;
    while( len-->0 ){
        tmp |= (*buffer++)<<(len*8);
    }
    return tmp;
}

// convert `len=1..4` bytes at buffer to an unsigned integer with little endian
uint32_t extractUintLE( uint8_t *buffer, uint8_t len ){
    uint32_t tmp=0;
    for( uint8_t i=0; i<len; i++ ){
        tmp |= (*buffer++)<<(i*8);
    }
    return tmp;
}

// convert `len=1..4` bytes at buffer to a signed integer with big endian
int32_t extractInt( uint8_t *buffer, uint8_t len ){
    int32_t tmp=0;
    while( len-->0 ){
        tmp |= (*buffer++)<<(len*8);
    }
    return tmp;
}

// Stolen and modified from E. Williams Arduino code. This one operates on byte streams and keeps state.
void runningCRC( uint8_t inputByte ) {
    gRunningCrc ^= inputByte;
    for( uint8_t b=0; b<=7; b++ ){     // For each bit in the byte
        gRunningCrc = (gRunningCrc & 1) ? ((gRunningCrc >> 1) ^ 0xA001) : (gRunningCrc >> 1);
    }
}

// Output a character to UART and update CRC state
void putCRC( uint8_t c ) {
    runningCRC( c );
    modbusPutC( c );
}

// CRC calculation over a complete buffer
uint16_t calculateCRC( uint8_t *buffer, uint16_t frameLen ) {
    resetRunnningCRC();
    while( frameLen-->0 ){       // For each byte in the buffer
        runningCRC( *buffer++ );
    }
    return gRunningCrc;
}

// Check the received modbus frame. If it is okay, call processModbusPayload()
void processModbusRxFrame( uint8_t *buffer, uint16_t nBytesReceived ){
    uint8_t address      = buffer[0];
    uint8_t functionCode = buffer[1];
    uint16_t calcCRC, rxCRC;

    if(nBytesReceived < 4){
        send_modbus_exception(functionCode, 1);
        return;
    }
    //if( !(address==0||address==MODBUS_CLIENT_ADDRESS) ){          //Respond to broadcast address 0
    if( !(address==MODBUS_CLIENT_ADDRESS) ){   //Ignore broadcast address 0
        send_modbus_exception(functionCode, 1);
        return;
    }
    rxCRC   = extractUintLE( &buffer[nBytesReceived-2], 2 );        //Recover the 16 bit CRC checksum from Buffer
    calcCRC = calculateCRC( buffer, nBytesReceived-2 );             //Exclude received CRC word from checksum calculation
    if( rxCRC != calcCRC){
        send_modbus_exception(functionCode, 2);
        return;
    }

    if ( gDebugOutputFlags ){
        print_str("   > ");
        hexDump( buffer, nBytesReceived );
    }
    processModbusPayload( &buffer[2], functionCode );//Hand over the payload to the user defined `processModbusPayload()` function
}

// Send out payloadBuffer as valid Modbus frame.
void sendModbusFrame( uint8_t *payloadBuffer, uint16_t nBytes, uint8_t functionCode, bool prependNbytes ){
    if ( gDebugOutputFlags ){
        print_str("   < ");
    }
    resetRunnningCRC();
    putCRC( MODBUS_CLIENT_ADDRESS );
    putCRC( functionCode );
    if( prependNbytes ){
        putCRC( nBytes );             // Payload Byte Count field. Not always there. Hopefully nBytes <= 255 :p
    }
    while( nBytes-->0 ){
        putCRC( *payloadBuffer++ );
    }
    modbusPutC( gRunningCrc & 0xFF );// Add CRC low byte
    modbusPutC( gRunningCrc >> 8 );  // Add CRC high byte
    if ( gDebugOutputFlags ){
        print_str("\n");
    }
}

void send_modbus_exception( uint8_t functionCode, uint8_t error_code) {
    resetRunnningCRC();
    putCRC(functionCode | 0x80);
    putCRC(error_code);
    modbusPutC( gRunningCrc & 0xFF );// Add CRC low byte
    modbusPutC( gRunningCrc >> 8 );  // Add CRC high byte
}

// Handles the main modbus statemachine, taking care of raw received data and RX delays
// Non-blocking, but must be called in a tight loop, else the UART will drop bytes
void modbusPoll(){
    uint16_t tempRxChar;
    static uint16_t nBytesReceived=0;
    static uint8_t modbusData[MODBUS_BUFFER_SIZE];          // Buffer for received modbus frames
    static uint8_t *writePointer;                           // Next free space in the buffer
    tempRxChar = UART_GETC(MODBUS_UART);                    // Try to get a new byte from UART
    switch( modBusState ){
        case IDLE:
            if( !UART_IS_DATA_OK(tempRxChar) ){             // return if nothing new is there
                return;
            }
            writePointer = modbusData;                      // Otherwise start receiving a new frame, switch to state RX_FRAME
            *writePointer++ = (uint8_t)(tempRxChar&0x00FF);
            nBytesReceived = 1;
            resetTimer();                                   // Reset and start IDLE timer
            modBusState = RX_FRAME;
        break;

        case RX_FRAME:
        case REJECT_FRAME:
            if( UART_IS_DATA_OK(tempRxChar) ){              // if there is a new UART byte, append it to the buffer ...
                if ( nBytesReceived < MODBUS_BUFFER_SIZE ){ // ... but only if there is space :)
                    *writePointer++ = (uint8_t)(tempRxChar&0x00FF);
                    nBytesReceived++;
                } else {                                    // If the buffer overflows ...
                    modBusState = REJECT_FRAME;             // ... reject the complete frame and start again with the next one
                }
                resetTimer();                               // Reset frame timeout
            }
            if ( getTimer() > MODBUS_TIMEOUT_CYCLES ) {     // If frame timeout expired, process received frame
                if( modBusState == RX_FRAME ){
                    processModbusRxFrame( modbusData, nBytesReceived );
                } else {
                    send_modbus_exception(modbusData[1], 3);
                }
                modBusState = IDLE;
            }
        break;
        default:
            send_modbus_exception(modbusData[1], 4);
            modBusState = IDLE;
    }
}
