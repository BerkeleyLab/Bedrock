#include <stdbool.h>
#include "test.h"
#include "print.h"

unsigned xorshift32(unsigned *state)
{
	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	unsigned x = *state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	*state = x;

	return x;
}

int cmd_memtest(volatile unsigned *base, unsigned len, unsigned stride, unsigned cycles)
{
    // copied from:
    // https://github.com/cliffordwolf/picorv32/blob/master/picosoc/firmware.c
    unsigned state;
    volatile uint8_t *base_byte = (volatile uint8_t*)base;

    for (unsigned i = 1; i <= cycles; i++) {
        // Walk in stride increments, word access
        state = i;
        for (unsigned word = 0; word < len / 4; word += stride) {
            base[word] = xorshift32(&state);
        }

        state = i;
        for (unsigned word = 0; word < len / 4; word += stride) {
            if (base[word] != xorshift32(&state)) {
                print_str(" ***FAILED WORD*** at ");
                print_hex(4 * word, 6);
                _putchar('\n');
                return -1;
            }
        }

        // Byte access
        for (unsigned byte=0; byte<len; byte+=stride) {
            base_byte[byte] = (uint8_t)byte;
        }

        for (unsigned byte=0; byte<len; byte+=stride) {
            if (base_byte[byte] != (uint8_t)byte) {
                print_str(" ***FAILED BYTE*** at ");
                print_hex(byte, 6);
                _putchar('\n');
                return -1;
            }
        }

        _putchar('.');
	}

    print_str(" ok\n");
    return 0;
}

// A simple Sieve of Eratosthenes
// copied from:
// https://github.com/cliffordwolf/picorv32/blob/master/firmware/sieve.c
static unsigned bitmap[BITMAP_SIZE/32];
static unsigned hash;

static unsigned mkhash(unsigned a, unsigned b)
{
	// The XOR version of DJB2
	return ((a << 5) + a) ^ b;
}

static void bitmap_set(int idx)
{
	bitmap[idx/32] |= 1 << (idx % 32);
}

static bool bitmap_get(int idx)
{
	return (bitmap[idx/32] & (1 << (idx % 32))) != 0;
}

static void print_prime(int idx, int val)
{
	if (((idx - 1) % 16) == 0)
		_putchar('\n');
	print_hex(val, 4);
	_putchar(' ');
	hash = mkhash(hash, idx);
	hash = mkhash(hash, val);
}

unsigned sieve(unsigned nPrimes)
{
	unsigned idx = 1;
	hash = 5381;
	print_prime(idx++, 2);
	for (int i = 0; i < BITMAP_SIZE; i++) {
		if (bitmap_get(i))
			continue;
		print_prime(idx, 3+2*i);
		if (idx >= nPrimes)
			break;
		idx++;
		for (int j = 2*(3+2*i);; j += 3+2*i) {
			if (j%2 == 0)
				continue;
			int k = (j-3)/2;
			if (k >= BITMAP_SIZE)
				break;
			bitmap_set(k);
		}
	}

	print_str("\nchecksum: ");
	print_hex(hash, 8);
	return hash;
}
