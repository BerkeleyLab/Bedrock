#ifndef ONEWIRE_SOFT_H
#define ONEWIRE_SOFT_H
#include <stdint.h>
#include <stdbool.h>

//-------------------------------------------------
// Onewire bit-bang library
//-------------------------------------------------
// * set BASE_ONEWIRE at compile time
// * bus multiplexer: select gpio pin at runtime with onewire_init()
//
// Expects the following macros in settings.h:
// #define BASE_ONEWIRE       0x01000000  //base address of the gpio module

//-------------------------------------------------
// Low level functions
//-------------------------------------------------
// initialize or change GPIO pin
void onewire_init(uint8_t pin);

// reset bus with long low-going pulse
// returns true if a one-wire device is present
bool onewire_reset(void);

// write a byte, use onewire_tx(0xff) for reading a byte
uint8_t onewire_tx(uint8_t dat);

// write several bytes
void onewire_write_bytes(const uint8_t *buf, unsigned count);

// read several bytes
void onewire_read_bytes(uint8_t *buf, unsigned count);

// used for ds2438 to signal end of conversion
// read a bit until it changes to `val`, then return true
// times out after `max_cycles` and returns false
bool onewire_poll_bit(bool val, unsigned max_cycles);

// Get device unique ID
// for a single device on bus only. Use onewire_search() for multiple ones
// on success writes 8 bytes into addr and returns true
bool onewire_readrom(uint8_t *addr);

//-------------------------------------------------
// High level functions from:
// https://github.com/PaulStoffregen/OneWire/blob/master/OneWire.h
//-------------------------------------------------
// Issue a 1-Wire rom select command, you do the reset first.
void onewire_select(const uint8_t rom[8]);

// Issue a 1-Wire rom skip command, to address all on bus.
void onewire_skip(void);

// Clear the search state so that if will start from the beginning again.
void onewire_reset_search(void);

// Setup the search to find the device type 'family_code' on the next call
// to search(*newAddr) if it is present.
void onewire_target_search(uint8_t family_code);

// Look for the next device. Returns 1 if a new address has been
// returned. A zero might mean that the bus is shorted, there are
// no devices, or you have already retrieved all of them.  It
// might be a good idea to check the CRC to make sure you didn't
// get garbage.  The order is deterministic. You will always get
// the same devices in the same order.
bool onewire_search(uint8_t *newAddr);

// Compute a Dallas Semiconductor 8 bit CRC, these are used in the
// ROM and scratchpad registers.
uint8_t onewire_crc8(const uint8_t *addr, uint8_t len);

#endif
