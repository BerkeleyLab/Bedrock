#include <stdint.h>
#include <stdbool.h>
#include "gpio.h"
#include "timer.h"
#include "settings.h"
#include "common.h"
#include "onewire_soft.h"

// pre-calculated memory addresses for
// setting / clearing / reading the one-wire pin
static unsigned p_high;
static unsigned p_low;
static unsigned p_rd;

#define BIT_CLEAR 0x100
#define BIT_SET 0x80

// disables driver, output pin goes high impedance
#define SET1() SET_REG(p_high, 0)

// enables driver to pull output pin low
#define SET0() SET_REG(p_low, 0)

// read pin state
#define GET()  GET_REG(p_rd)

//-------------------------------------------------
// Low level functions
//-------------------------------------------------
void onewire_init(uint8_t pin)
{
    // pre-calculate memory addresses for setting / clearing / reading the pins
    // cannot rely on macros here as they are only efficient for constants
    // to make sense of this, see sfr_pack.v
    pin = (pin & 0x1F) << 2;
    p_high = BASE_ONEWIRE | (GPIO_OE_REG << 9) | BIT_CLEAR | pin;
    p_low  = BASE_ONEWIRE | (GPIO_OE_REG << 9) | BIT_SET   | pin;
    p_rd   = BASE_ONEWIRE | (GPIO_IN_REG << 9) | BIT_SET   | pin;

    // pin alternates between 0 and Z, so clear the gpioOut bit
    SET_REG(BASE_ONEWIRE | (GPIO_OUT_REG << 9) | BIT_CLEAR | pin, 0);
    SET1();

    onewire_reset_search();
}

static void onewire_stall(uint32_t et)
{
    uint32_t cur_t;
    do {
        cur_t = getCycles();
    } while (cur_t < et);
}

// Resets device, returns true if a one-wire device is present
bool onewire_reset(void)
{
    uint32_t st = getCycles();
    SET0();
    onewire_stall(st + US_TO_CYCLES(540));
    SET1();
    onewire_stall(st + US_TO_CYCLES(600));
    bool r = GET();
    onewire_stall(st + US_TO_CYCLES(1050));
    return !r;
}

static bool onewire_bit(bool x)
{
    uint32_t st = getCycles();
    SET0();
    onewire_stall(st + US_TO_CYCLES(5));
    if (x) {
        SET1();
    } else {
        SET0();
    }
    onewire_stall(st + US_TO_CYCLES(10));
    bool r = GET();
    onewire_stall(st + US_TO_CYCLES(65));
    SET1();
    onewire_stall(st + US_TO_CYCLES(95));
    return r;
}

// write a byte, use onewire_tx(0xff) for reading a byte
uint8_t onewire_tx(uint8_t dat)
{
    unsigned r = 0;
    for (unsigned i=0; i<=7; i++) {
        r = (onewire_bit(dat & 0x01) << 7) | (r >> 1);
        dat >>= 1;
    }
    return r;
}

// used for ds2438 to signal end of conversion
// read a bit until it changes to `val`, then returns true
// times out after `max_cycles` and returns false
bool onewire_poll_bit(bool val, unsigned max_cycles)
{
    unsigned st = getCycles();
    while (getCycles() - st < max_cycles) {
        if (onewire_bit(1) == val)
            return true;
    }
    return false;
}

// write several bytes
void onewire_write_bytes(const uint8_t *buf, unsigned count)
{
    while(count--)
        onewire_tx(*buf++);
}

// read several bytes
void onewire_read_bytes(uint8_t *buf, unsigned count)
{
    while(count--)
        *buf++ = onewire_tx(0xFF);
}

// Get device unique ID
// for a single device on bus only. Use onewire_search() for multiple ones
// on success writes 8 bytes into addr and returns true
bool onewire_readrom(uint8_t *addr)
{
    if (!onewire_reset())
        return false;
    onewire_tx(0x33);
    onewire_read_bytes(addr, 8);
    return true;
}

//--------------------------------------------
// everything below adapted from:
// https://github.com/PaulStoffregen/OneWire/blob/master/OneWire.cpp
//--------------------------------------------

// Do a ROM select
void onewire_select(const uint8_t rom[8])
{
    onewire_tx(0x55);  // Choose ROM
    onewire_write_bytes(rom, 8);
}

// Do a ROM skip
void onewire_skip()
{
    onewire_tx(0xCC);  // Skip ROM
}

// global search state
static unsigned char ROM_NO[8];
static unsigned LastDiscrepancy;
static unsigned LastFamilyDiscrepancy;
static bool LastDeviceFlag;

// You need to use this function to start a search again from the beginning.
// You do not need to do it for the first search, though you could.
void onewire_reset_search()
{
    // reset the search state
    LastDiscrepancy = 0;
    LastDeviceFlag = false;
    LastFamilyDiscrepancy = 0;
    for(unsigned i=0; i<8; i++)
        ROM_NO[i] = 0;
}

// Setup the search to find the device type 'family_code' on the next call
// to search(*newAddr) if it is present.
void onewire_target_search(uint8_t family_code)
{
    // set the search state to find SearchFamily type devices
    ROM_NO[0] = family_code;
    for (unsigned i=1; i<8; i++)
        ROM_NO[i] = 0;
    LastDiscrepancy = 64;
    LastFamilyDiscrepancy = 0;
    LastDeviceFlag = false;
}

// Perform a search. If this function returns a '1' then it has
// enumerated the next device and you may retrieve the ROM from the
// onewire_address variable. If there are no devices, no further
// devices, or something horrible happens in the middle of the
// enumeration then a 0 is returned.  If a new device is found then
// its address is copied to newAddr.  Use onewire_reset_search() to
// start over.
//
// --- Replaced by the one from the Dallas Semiconductor web site ---
//--------------------------------------------------------------------------
// Perform the 1-Wire Search Algorithm on the 1-Wire bus using the existing
// search state.
// Return TRUE  : device found, ROM number in ROM_NO buffer
//        FALSE : device not found, end of search
//
bool onewire_search(uint8_t *newAddr)
{
    uint8_t id_bit_number;
    uint8_t last_zero, rom_byte_number;
    bool    search_result;

    unsigned char rom_byte_mask;

    // initialize for search
    id_bit_number = 1;
    last_zero = 0;
    rom_byte_number = 0;
    rom_byte_mask = 1;
    search_result = false;

    // if the last call was not the last one
    if (!LastDeviceFlag) {
        // 1-Wire reset
        if (!onewire_reset()) {
            // reset the search
            LastDiscrepancy = 0;
            LastDeviceFlag = false;
            LastFamilyDiscrepancy = 0;
            return false;
        }

        // issue the search command
        // if (search_mode == true) {
        onewire_tx(0xF0);   // NORMAL SEARCH
        // } else {
        //   onewire_tx(0xEC);   // CONDITIONAL SEARCH
        // }

        // loop to do the search
        do {
            // read a bit and its complement
            uint8_t id_bit = onewire_bit(1);
            uint8_t cmp_id_bit = onewire_bit(1);

            // check for no devices on 1-wire
            if ((id_bit == 1) && (cmp_id_bit == 1)) {
                break;
            } else {
                unsigned char search_direction;
                // all devices coupled have 0 or 1
                if (id_bit != cmp_id_bit) {
                    search_direction = id_bit;  // bit write value for search
                } else {
                    // if this discrepancy if before the Last Discrepancy
                    // on a previous next then pick the same as last time
                    if (id_bit_number < LastDiscrepancy) {
                        search_direction = ((ROM_NO[rom_byte_number] & rom_byte_mask) > 0);
                    } else {
                        // if equal to last pick 1, if not then pick 0
                        search_direction = (id_bit_number == LastDiscrepancy);
                    }
                    // if 0 was picked then record its position in LastZero
                    if (search_direction == 0) {
                        last_zero = id_bit_number;

                        // check for Last discrepancy in family
                        if (last_zero < 9)
                            LastFamilyDiscrepancy = last_zero;
                    }
                }

                // set or clear the bit in the ROM byte rom_byte_number
                // with mask rom_byte_mask
                if (search_direction == 1)
                    ROM_NO[rom_byte_number] |= rom_byte_mask;
                else
                    ROM_NO[rom_byte_number] &= ~rom_byte_mask;

                // serial number search direction write bit
                onewire_bit(search_direction);

                // increment the byte counter id_bit_number
                // and shift the mask rom_byte_mask
                id_bit_number++;
                rom_byte_mask <<= 1;

                // if the mask is 0 then go to new SerialNum byte rom_byte_number and reset mask
                if (rom_byte_mask == 0) {
                    rom_byte_number++;
                    rom_byte_mask = 1;
                }
            }
        } while(rom_byte_number < 8);  // loop until through all ROM bytes 0-7

        // if the search was successful then
        if (!(id_bit_number < 65)) {
            // search successful so set LastDiscrepancy,LastDeviceFlag,search_result
            LastDiscrepancy = last_zero;

            // check for last device
            if (LastDiscrepancy == 0) {
                LastDeviceFlag = true;
            }
            search_result = true;
        }
    }

    // if no device found then reset counters so next 'search' will be like a first
    if (!search_result || !ROM_NO[0]) {
        LastDiscrepancy = 0;
        LastDeviceFlag = false;
        LastFamilyDiscrepancy = 0;
        search_result = false;
    } else {
        for (int i = 0; i < 8; i++) newAddr[i] = ROM_NO[i];
    }
    return search_result;
}

// Compute a Dallas Semiconductor 8 bit CRC directly.
// this is much slower, but a little smaller, than the lookup table.
uint8_t onewire_crc8(const uint8_t *addr, uint8_t len)
{
    uint8_t crc = 0;

    while (len--) {
        uint8_t inbyte = *addr++;
        for (uint8_t i = 8; i; i--) {
            uint8_t mix = (crc ^ inbyte) & 0x01;
            crc >>= 1;
            if (mix) crc ^= 0x8C;
            inbyte >>= 1;
        }
    }
    return crc;
}
