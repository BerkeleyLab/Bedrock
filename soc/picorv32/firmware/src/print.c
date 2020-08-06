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

void print_udec(uint32_t val)
{
    char buffer[10];
    char *p = buffer;
    while (val || p == buffer) {
        *(p++) = val % 10;
        val = val / 10;
    }
    while (p != buffer) {
        _putchar('0' + *(--p));
    }
}

void print_dec(int32_t val)
{
    if(val < 0) {
        _putchar('-');
        val = -val;
    } else {
        _putchar(' ');
    }
    print_udec(val);
}

void print_udec_fix(uint32_t val, const uint8_t nFract, uint8_t nDigits)
{
    uint32_t fractMask = ((1<<nFract)-1);   //mask the fractional part
    print_dec(val>>nFract);               //Print the integer part
    _putchar('.');
    val &= fractMask;                       //Convert to fractional part
    while(nDigits-- > 0) {
        val *= 10;
        _putchar('0' + (val>>nFract));    //Print digit
        val &= fractMask;                   //Convert to fractional part
    }
}

void print_dec_fix(int32_t val, const uint8_t nFract, uint8_t nDigits)
{
    if(val < 0) {
        _putchar('-');
        val = -val;
    } else {
        _putchar(' ');
    }
    print_udec_fix(val, nFract, nDigits);
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
