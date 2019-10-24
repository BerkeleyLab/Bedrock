#ifndef TEST_H
#define TEST_H

// returns 0 on pass
int cmd_memtest(void);

// Maximum prime number value <= 1 + 2 * (BITMAP_SIZE - 1)
#define BITMAP_SIZE 4096

// returns DJB2 hash of prime numbers
unsigned sieve(unsigned nPrimes);

#endif
