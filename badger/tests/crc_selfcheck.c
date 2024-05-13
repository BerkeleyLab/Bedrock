/* crc-selfcheck.c */

/* Larry Doolittle, LBNL */

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "crc32.h"

#define ETH_MAXLEN 1500   /* maximum line length */

struct pbuf {
	char buf[ETH_MAXLEN+12];
	int cur, len;
};

static int ethernet_check(char *packet, unsigned len)
{
	char *p=packet;
	unsigned int nout, u;
	int mismatch=0;
	char given_crc[4];
	printf("scanning preamble");
	while (*p==0x55 && p<(packet+len)) { printf("."); p++; }
	printf("\n");
	if ((*p & 0xff) != 0xd5) {
		printf("missing SFD (%2.2x %2.2x)\n",
			(unsigned) packet[0], (unsigned) *p);
		return 2;
	}
	nout=packet+len-(p+5);
	if ((p+5)>(packet+len) || check_crc32(p+1, nout)==0) {
		printf("CRC check failed, packet length=%u\n",nout);
		return 2;
	}
	/* Overwrite CRC given in file */
	for (u=0; u<4; u++) given_crc[u]=packet[nout+u];
	append_crc32(p+1,nout);
	for (u=0; u<4; u++) mismatch |= given_crc[u]!=packet[nout+u];
	if (mismatch) {
		printf("generated CRC mismatch\n");
		return 2;
	}

	printf("PASS  packet length=%u\n", nout);
	return 0;
}

/* Crude analog of Verilog's $readmemh */
static unsigned int readmemh(FILE *f, char *buff, size_t avail)
{
	size_t u;
	int rc;
	for (u=0; u<avail; u++) {
		unsigned int h;
		rc=fscanf(f, "%x", &h);
		if (rc!=1) break;
		buff[u]=h;
	}
	return u;
}

int main(int argc, char *argv[])
{
	FILE *f;
	unsigned int l;
	char buff[ETH_MAXLEN];
	const char *fname;
	if (argc > 2) {
		fprintf(stderr,"Usage\n");
		return 1;
	}
	if (argc == 2) {
		fname = argv[1];
		f = fopen(fname,"r");
		if (f==NULL) {
			perror(fname);
			return 1;
		}
	} else {
		f = stdin;
		fname = "(stdin)";
	}
	l = readmemh(f, buff, ETH_MAXLEN);
	printf("Read %u octets from file %s\n",l,fname);
	return ethernet_check(buff,l);
}
