#ifndef TEST_H
#define TEST_H

// Maximum prime number value <= 1 + 2 * (BITMAP_SIZE - 1)
#define BITMAP_SIZE 4096

// returns DJB2 hash of prime numbers
unsigned sieve(unsigned nPrimes);

// tests 32 bit and 8 bit access to internal / external memory, returns 0 on pass
int cmd_memtest(volatile unsigned *base, unsigned len, unsigned stride, unsigned cycles);

#endif
