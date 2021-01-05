#include <stdint.h>
#include "print.h"

// Stub to prevent linker errors. User shall redefine this function!
void __attribute__((weak)) _putchar(char c)
{
    (void)c;
}

void print_str(const char *p)
{
    while (*p != 0)
        _putchar(*(p++));
}

// returns number of characters written to buf
static unsigned udec(uint32_t val, char *buf)
{
    char buffer[16];
    char *p = buffer;
    while (val || p == buffer) {
        *(p++) = val % 10;
        val = val / 10;
    }
    unsigned ret = 0;
    while (p != buffer) {
        *buf++ = '0' + *(--p);
        ret++;
    }
    *buf = '\0';
    return ret;
}

static void dec(int32_t val, char *buf)
{
    if (val < 0) {
        val = -val;
        *buf++ = '-';
    }
    udec(val, buf);
}

void print_udec(uint32_t val)
{
    char buffer[16];
    udec(val, buffer);
    print_str(buffer);
}

void print_dec(int32_t val)
{
    char buffer[16];
    dec(val, buffer);
    print_str(buffer);
}

// val 130, n 4
// dp 0:   130
// dp 1:  13.0
// dp 2:  1.30
// dp 3: 0.130
// dp 4: .0130
void udec_dp(uint32_t val, const uint8_t n, const uint8_t dp, char *buf)
{
    char buffer[16], *p=buffer;
    unsigned i;
    for (i=0; i<n; i++) {
        if (i > 0 && i == dp)
            *p++ = '.';
        if (val == 0 && i > dp)  // suppress leading zeros
            *p++ = ' ';
        else
            *p++ = '0' + val % 10;
        val = val / 10;
    }
    if (i == dp)
        *p++ = '.';
    while (p != buffer)
        *buf++ = *(--p);  // reverse the string
    *buf++ = '\0';
}

void dec_dp(int32_t val, const uint8_t n, const uint8_t dp, char *buf)
{
    if(val < 0) {
        *buf++ = '-';
        val = -val;
    } else {
        *buf++ = ' ';
    }
    udec_dp(val, n, dp, buf);
}

void print_udec_dp(uint32_t val, const uint8_t n, const uint8_t dp)
{
    char buffer[16];
    udec_dp(val, n, dp, buffer);
    print_str(buffer);
}

void udec_fix(uint32_t val, const uint8_t nFract, uint8_t nDigits, char *buf)
{
    uint32_t fractMask = ((1 << nFract) - 1);  // mask the fractional part
    unsigned ret = udec(val >> nFract, buf);  // Print the integer part
    buf += ret;
    *buf++ = '.';
    val &= fractMask;  // Convert to fractional part
    while(nDigits-- > 0) {
        val *= 10;
        *buf++ = '0' + (val >> nFract);  // Print digit
        val &= fractMask;  // Convert to fractional part
    }
    *buf++ = '\0';
}

void dec_fix(int32_t val, const uint8_t nFract, uint8_t nDigits, char *buf)
{
    if(val < 0) {
        *buf++ = '-';
        val = -val;
    } else {
        *buf++ = ' ';
    }
    udec_fix(val, nFract, nDigits, buf);
}

void print_udec_fix(uint32_t val, const uint8_t nFract, uint8_t nDigits)
{
    char buffer[16];
    udec_fix(val, nFract, nDigits, buffer);
    print_str(buffer);
}

void print_dec_fix(int32_t val, const uint8_t nFract, uint8_t nDigits)
{
    char buffer[16];
    dec_fix(val, nFract, nDigits, buffer);
    print_str(buffer);
}

void print_hex(uint32_t val, uint8_t digits)
{
    for (int i = (4*digits)-4; i >= 0; i -= 4)
        _putchar("0123456789ABCDEF"[(val >> i) % 16]);
}

void hexDump(uint8_t *buffer, uint16_t nBytes)
{
    for(uint16_t i=0; i<nBytes; i++) {
        if((nBytes>16) && ((i%16)==0)) {
            print_str("\n    ");
            print_hex(i, 4);
            print_str(": ");
        }
        print_hex(*buffer++, 2);
        print_str(" ");
    }
    print_str("\n");
}

void hexDump32(uint32_t *buffer, uint16_t nWords)
{
    for(uint16_t i=0; i<nWords; i++) {
        if((nWords>4) && ((i%4)==0)) {
            print_str("\n    ");
            print_hex(i*4, 4);
            print_str(": ");
        }
        print_hex(*buffer++, 8);
        print_str(" ");
    }
    print_str("\n");
}
