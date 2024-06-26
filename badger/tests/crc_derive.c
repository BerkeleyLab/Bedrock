#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>

/* Larry Doolittle  <ldoolitt@recycle.lbl.gov>  August 4, 2008
 * XXX extend to arbitrary length
 */

static unsigned long crc_eval( unsigned int order, unsigned long poly, unsigned long crc,
	unsigned int width, unsigned long inword)
{
	unsigned long mask_c = 1UL << (order-1);
	unsigned long mask_d = 1UL << (width-1);
	for (unsigned int u=0; u<width; u++) {
		unsigned int bit = ((crc&mask_c)!=0) ^ ((inword&mask_d)!=0);
		if (0) printf("u=%u crc=%lx inword=%lx bit=%u poly=%lx\n",
			u, crc, inword, bit, poly);
		inword = inword << 1;
		crc = crc << 1;
		if (bit) crc = crc ^ poly;
	}
	return crc;
}

#define MAX_ORDER 64
int main(int argc, char *argv[])
{
	unsigned long poly, mask;
	unsigned int width, order, u, k, lsb;
	unsigned long dres[MAX_ORDER];
	unsigned long cres[MAX_ORDER];
	int oi=1;
	lsb=0;
	if (argc > 1 && strcmp(argv[1],"-lsb")==0) {
		lsb=1;
		oi++;
	}
	if (argc < 3+oi) {
		fprintf(stderr,"usage: %s order [-lsb] poly width\n\tpoly is normal, high-order bit omitted, and can be hex (e.g., 0x1021)\n", argv[0]);
		return 1;
	}
	order  = strtoul(argv[oi+0], NULL, 0);
	poly   = strtoul(argv[oi+1], NULL, 0);
	width  = strtoul(argv[oi+2], NULL, 0);

	if (order > MAX_ORDER || order > CHAR_BIT*sizeof(unsigned long)) {
		fprintf(stderr, "order %u too big\n", order);
		return 1;
	}
	if (width > MAX_ORDER || width > CHAR_BIT*sizeof(unsigned long)) {
		fprintf(stderr, "width %u too big\n", width);
		return 1;
	}
	if ((poly&1) != 1) {
		fprintf(stderr, "bogus polynomial (0x%lx)\n", poly);
		return 1;
	}
	printf("// Machine generated by %s%s %u 0x%lx %u\n", argv[0], lsb ? " -lsb" : "", order, poly, width);
	printf("// D is the %u-bit input data (%csb-first)\n", width, lsb ? 'l' : 'm');
	printf("// crc and O are the new and old %u-bit CRC\n", order);
	printf("// Generating polynomial is 0x%lx (normal form, leading 1 suppressed)\n", poly);
	printf("// Reference: https://en.wikipedia.org/wiki/Cyclic_redundancy_check\n");

	for (u=0; u<width; u++) {
		dres[u] = crc_eval(order, poly, 0, width, 1UL<<u);
	}
	for (u=0; u < order; u++) {
		cres[u] = crc_eval(order, poly, 1UL<<u, width, 0);
	}
	for (u=0; u<order; u++) {
		int s=' ';
		mask = 1UL<<u;
		printf("crc[%u] <=", u);
		for (k=0; k<width || k<order; k++) {
			unsigned kk = lsb ? width-1-k : k;
			if (k<width && dres[k]&mask) {printf("%cD[%u]",s,kk);s='^';}
			if (k<order && cres[k]&mask) {printf("%cO[%u]",s,k );s='^';}
		}
		if (s==' ') printf(" 0; // XXX\n");
		else printf(";\n");
	}
	return 0;
}
