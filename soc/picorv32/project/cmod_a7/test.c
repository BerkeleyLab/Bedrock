#include <stdbool.h>
#include "test.h"
#include "print.h"

uint32_t xorshift32(uint32_t *state)
{
	/* Algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs" */
	uint32_t x = *state;
	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	*state = x;

	return x;
}

int cmd_memtest(void)
{
	// copied from:
	// https://github.com/cliffordwolf/picorv32/blob/master/picosoc/firmware.c
	int cyc_count = 5;
	int stride = 256;
	uint32_t state;

	volatile uint32_t *base_word = (uint32_t *) 0;
	volatile uint8_t *base_byte = (uint8_t *) 0;

	print_str("Running memtest ");

	// Walk in stride increments, word access
	for (int i = 1; i <= cyc_count; i++) {
		state = i;

		for (int word = 0; word < BLOCK_RAM_SIZE / sizeof(int); word += stride) {
			*(base_word + word) = xorshift32(&state);
		}

		state = i;

		for (int word = 0; word < BLOCK_RAM_SIZE / sizeof(int); word += stride) {
			if (*(base_word + word) != xorshift32(&state)) {
				print_str(" ***FAILED WORD*** at ");
				print_hex(4*word, 4);
				_putchar('\n');
				return -1;
			}
		}
		_putchar('.');
	}

	// Byte access
	for (int byte = 0; byte < 128; byte++) {
		*(base_byte + byte) = (uint8_t) byte;
	}

	for (int byte = 0; byte < 128; byte++) {
		if (*(base_byte + byte) != (uint8_t) byte) {
			print_str(" ***FAILED BYTE*** at ");
			print_hex(byte, 4);
			_putchar('\n');
			return -1;
		}
	}

	print_str(" passed\n");
	return 0;
}

// A simple Sieve of Eratosthenes
// copied from:
// https://github.com/cliffordwolf/picorv32/blob/master/firmware/sieve.c
static uint32_t bitmap[BITMAP_SIZE/32];
static uint32_t hash;

static uint32_t mkhash(uint32_t a, uint32_t b)
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
	int idx = 1;
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
	_putchar('\n');
	return hash;
}
