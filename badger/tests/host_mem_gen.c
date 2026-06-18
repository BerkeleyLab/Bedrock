#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define AW (8)
#define BUFLEN (1<<(AW))
uint16_t host_mem[BUFLEN];

/* Real-life packets can have embedded nuls, but just use
 * ASCII strings for these tests */
static void load_packet(const char s[], unsigned int base)
{
	size_t sl = strlen(s);
	unsigned ix=base+1;
	uint16_t word=0;
	host_mem[base] = sl;
	for (unsigned jx=0; jx<sl; jx++) {
		// Little-endian; see big_endian parameter in test_tx_mac.
		word = (s[jx]<<8) | (word>>8);
		if (jx&1) {
			host_mem[ix++] = word;
			if (ix >= BUFLEN) ix=0;
			word = 0;
		}
	}
	if (sl&1) host_mem[ix] = word>>8;
}

int main(void)
{
	FILE *f = fopen("host_mem", "w");
	{
		// Base address also hard-coded in test_tx_tb.v
		load_packet("Hello World\n", 0);
		load_packet("The quick red fox\n", 30);
		load_packet("All good men should come to the aid\n", 60);
		// Strings need to match those in test_tx.gold
	}
	if (f) {
		for (unsigned jx=0; jx<BUFLEN; jx++) {
			fprintf(f, "%4.4x\n", host_mem[jx]);
		}
	}
	return 0;
}
