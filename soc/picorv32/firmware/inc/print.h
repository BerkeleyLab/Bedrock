//-------------------------------------------------------------
// Minimalistic print functions
//-------------------------------------------------------------
// Note that the _putchar function needs to be implemented by the user!
// For example to print to UART, add this line to your code:
// void _putchar(char c){ UART_PUTC(BASE_DEBUG_UART, c); }

#ifndef PRINT_H
#define PRINT_H
#include <stdint.h>

// Print a single character (see note above!)
void _putchar(char c);

// Print an integer as N hex digits
void print_hex(uint32_t val, uint8_t digits);

// Print a signed integer as decimal number
void print_dec(int32_t val);

// Print an unsigned integer as decimal number
void print_udec(uint32_t val);

// convert to decimal with fixed number of digits + decimal point
// ecample for val: 130, n: 4
// dp 0:   130
// dp 1:  13.0
// dp 2:  1.30
// dp 3: 0.130
// dp 4: .0130
void udec_dp(uint32_t val, const uint8_t n, const uint8_t dp, char *buf);
void dec_dp(int32_t val, const uint8_t n, const uint8_t dp, char *buf);
void print_udec_dp(uint32_t val, const uint8_t n, const uint8_t dp);

// Print a fixed point fractional number
// with `nFract` fractional bits and print only `nDigits` after the .
void udec_fix(uint32_t val, const uint8_t nFract, uint8_t nDigits, char *buf);
void dec_fix(int32_t val, const uint8_t nFract, uint8_t nDigits, char *buf);
void print_udec_fix(uint32_t val, const uint8_t nFract, uint8_t nDigits);
void print_dec_fix(  int32_t val, const uint8_t nFract, uint8_t nDigits);

// Print a zero terminated string
void print_str(const char *p);

// Print a memory region as 8-bit ordered hexdump
void hexDump(uint8_t *buffer, uint16_t nBytes);

// Print a memory region as N-bit ordered hexdump
void hexDump16(uint16_t *buffer, uint16_t nWords);
void hexDump32(uint32_t *buffer, uint16_t nWords);

#endif
