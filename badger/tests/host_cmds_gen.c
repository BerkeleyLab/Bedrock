#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define AW (8)
#define BUFLEN (1<<(AW))
int16_t host_mem[BUFLEN];

static void mem_write(FILE *f, unsigned int a, unsigned int d) {
	fprintf(f, "%x %4.4x\n", a, d);
}

static void mem_close(FILE *f, unsigned int base) {
	mem_write(f, BUFLEN, base);
	fprintf(f, "wait 1\n");
	mem_write(f, BUFLEN+1, 0);
	fprintf(f, "wait 0\n");
}

/* Real-life packets can have embedded nuls, but just use
 * ASCII strings for these tests */
static void spit_packet(FILE *fout, const char s[])
{
	unsigned int base=16;
	size_t sl = strlen(s);
	unsigned ix=base;
	int16_t word=0;
	mem_write(fout, ix++, sl);
	host_mem[base] = sl;
	for (unsigned jx=0; jx<sl; jx++) {
		// Little-endian; see big_endian parameter in test_tx_mac.
		word = (s[jx]<<8) | (word>>8);
		if (jx&1) {
			mem_write(fout, ix++, word);
		}
	}
	if (sl&1) mem_write(fout, ix, word>>8);
	mem_close(fout, base);
}

int main(int argc, char *argv[])
{
	char idata[200];
	if (argc < 2) {
		fprintf(stderr, "Usage: %s mac_subset.gold\n", argv[0]);
		return 1;
	}
	FILE *fin = fopen(argv[1], "r");
	if (!fin) {
		perror("mac_subset.gold");
		return 1;
	}
	FILE *fout = fopen("host_cmds.dat", "w");
	if (!fout) {
		perror("host_cmds.dat");
		return 1;
	}
	while (fgets(idata, sizeof(idata), fin)) {
		spit_packet(fout, idata);
	}
	return 0;
}
