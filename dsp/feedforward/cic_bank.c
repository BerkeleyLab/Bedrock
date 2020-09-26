#include <stdio.h>
#include <stdlib.h>

void cic_bank(unsigned int len, int shift, int mem_sz, int mem[])
{
	int next, sr1=0, sr2=0, sr3=0, sr4=0;
	unsigned int count_mod = mem_sz << shift;
	for (unsigned int count=0; count < len; count++) {
		unsigned int mcnt = count % count_mod;
		unsigned int mem_a = (((mcnt >> shift) & ~3) | (mcnt & 3));
		int mem_v = mem[mem_a];
		next = mem_v;
		if ((mcnt & 3) != 3) next += sr3 >> (5+shift);  // shift me?
		if ((mcnt & ~3) != 0) next += sr4;
		if ((mcnt & 3) == 0) {
			printf("%5u %6d %6d : %6d %6d %6d %6d\n", count, mem_v, next, sr1, sr2, sr3, sr4);
		}
		sr4 = sr3;
		sr3 = sr2;
		sr2 = sr1;
		sr1 = next;
	}
}

int main(int argc, char *argv[])
{
	if (argc < 3) return 1;
	unsigned int mem_sz = atoi(argv[1]);
	unsigned int len    = atoi(argv[2]);
	unsigned int shift  = atoi(argv[3]);
	int *mem = calloc(mem_sz, sizeof(int));
	if (!mem) return 2;
	for (unsigned int ix=0; ix < mem_sz; ix++) {
		int rc = scanf("%d", mem+ix);
		if (rc != 1) return 1;
	}
	cic_bank(len, shift, mem_sz, mem);
	return 0;
}
