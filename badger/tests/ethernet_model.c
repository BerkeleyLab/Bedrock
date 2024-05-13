/* ethernet_model.c, used in tap-vpi.c */

/* Larry Doolittle, LBNL */

#include <string.h>   /* strspn() */
#include <stdio.h>    /* snprintf() */
#include <unistd.h>   /* read() and write() */
#include <time.h>     /* nanosleep() */
#include <fcntl.h>
#include <errno.h>
#include "crc32.h"
#include "tap_alloc.h"
#include "ethernet_model.h"

#define GMII
#ifdef GMII
#define DATA_BASE 8
#define CRC_SIZE 4
#else
#define DATA_BASE 0
#define CRC_SIZE 0
#endif

#define MIN_IFG 12

#define ETH_MAXLEN 1520   /* maximum line length */
/* Empirically on Linux, 1500 isn't enough:  I've seen
 * the TAP device try give me 1514 bytes, even though
 * ifconfig claims its MTU is 1500. */

struct pbuf {
	unsigned char buf[ETH_MAXLEN+12];
	unsigned int cur, len;
};

#define HEX(x) ((x)>9 ? 'A' - 10 + (x) : '0' + (x))
static void print_hex(FILE *f, unsigned int c)
{
	fputc(HEX((c>>4)&0xf), f);
	fputc(HEX((c   )&0xf), f);
}

static void print_buf(FILE *f, struct pbuf *b)
{
	for (unsigned jx=0; jx < b->len; jx++) {
		fputc(' ', f);
		print_hex(f, b->buf[jx]);
	}
	fputc('\n', f);
}

int ethernet_model(int out_octet, int out_valid, int *in_octet, int *in_valid, int thinking)
{
	static struct pbuf inbuf;
	static struct pbuf outbuf;
	static int initialized=0;
	static unsigned int activity_counter=0;
	static int prev_out_valid=0;
	int val = 0;
	char device[20];
	static int tapfd;
	static int sleepctr=0;
	static int sleepmax=1;
	char in_txt[15], out_txt[15];
	int ethernet_model_debug = 0;  /* adjustable */

	if (out_valid) {
		sprintf(out_txt, "0x%2.2x", (unsigned int)(out_octet&0xff));
	} else {
		strcpy(out_txt, "----");
	}

	if (!initialized) {
		fprintf(stderr, "ethernet_model initializing\n");
		inbuf.cur = 0;
		inbuf.len = 0;
#ifdef GMII
		{
			unsigned u;
			for (u=0; u<7; u++) inbuf.buf[u]=0x55;  /* Preamble */
		}
		inbuf.buf[7]=0xd5;  /* SFD */
#endif
		outbuf.cur = 0;
		outbuf.len = 0;
		initialized = 1;
		strcpy(device, "tap0");
		if ((tapfd = tap_alloc(device)) < 0) {
			perror("tap_alloc");
			return 1;  /* failure */
		}
		fcntl(tapfd, F_SETFL, O_NONBLOCK);
	}

	if (inbuf.cur == inbuf.len + MIN_IFG) {
		/* non-blocking read packet */
		int rc = read(tapfd, inbuf.buf+DATA_BASE, ETH_MAXLEN);
		if (rc < 0) {
			if ((errno != EAGAIN) && (errno != EWOULDBLOCK)) {
				struct timespec minsleep = {0, 500000000};
				fprintf(stderr, "TAP read failed: errno %d (%s)\n", errno, strerror(errno));
				nanosleep(&minsleep, NULL);
			}
			if (!out_valid && !thinking && sleepctr++ > sleepmax) {
				struct timespec minsleep = {0, 2000000};
				nanosleep(&minsleep, NULL);
			}
		} else {
			if (1 || ethernet_model_debug) {
				fprintf(stderr, "ethernet_model: Rx %d tap octets\n", rc);
			}
#ifdef GMII
			if (rc < 60) {
				/* Pad to satisfy Ethernet's minimum frame size */
				/* 4 bytes of CRC, added next, will take it up to 64 */
				for (int ix=rc; ix<60; ix++) {
					inbuf.buf[DATA_BASE+ix]=0;
				}
				rc = 60;
			}
			append_crc32(inbuf.buf+DATA_BASE, rc);
			if (check_crc32(inbuf.buf+DATA_BASE, rc)==0) {
				fprintf(stderr, "CRC self-test failed\n");
			}
#endif
			inbuf.len = rc+DATA_BASE+CRC_SIZE;
			inbuf.cur = 0;
			if (ethernet_model_debug) {
				fputs("TAP_RX:", stderr); print_buf(stderr, &inbuf);
			}
		}
	}
	if (inbuf.cur < inbuf.len) {
		if (in_octet) *in_octet = inbuf.buf[inbuf.cur];
		inbuf.cur++;
		val = 1;
	} else if (inbuf.cur < inbuf.len + MIN_IFG) {
		if (in_octet) *in_octet = 0;  /* could in principle be XX */
		inbuf.cur++;
		val = 0;
	}
	if (in_valid) *in_valid = val;
	if (val) {
		sprintf(in_txt, "0x%2.2x", (unsigned int)((*in_octet)&0xff));
	} else {
		strcpy(in_txt, "----");
	}
	if (0) fprintf(stderr, "Ethernet model %s to Verilog, %s from Verilog\n", in_txt, out_txt);
	activity_counter++;
	if (ethernet_model_debug && activity_counter > 30) {
		fputc('-', stderr);
		activity_counter = 0;
	}
	if (out_valid) {
		outbuf.buf[outbuf.cur] = out_octet;
		if (outbuf.cur < ETH_MAXLEN+12) outbuf.cur++;
		else fprintf(stderr, "Ethernet output packet too long\n");
	} else if (prev_out_valid) {
		unsigned nout = outbuf.cur;  /* number of octets to finally write() */
		/* write output packet */
		outbuf.len = outbuf.cur;
		if (ethernet_model_debug) {
			fputs("\nTAP_TX:", stderr); print_buf(stderr, &outbuf);
		}
#ifdef GMII
		const unsigned char *p=outbuf.buf;
		while (*p==0x55 && p<(outbuf.buf+outbuf.cur)) { p++; }
		if (p-outbuf.buf < 3) {
			fprintf(stderr, "preamble too short, only found %ld x 0x55\n", (long int)(p-outbuf.buf));
		} else if ((*p & 0xff) != 0xd5) {
			fprintf(stderr, "output packet len %u missing SFD (%2.2x %2.2x)\n",
				outbuf.cur, outbuf.buf[0], *p);
		} else if (nout=outbuf.buf+outbuf.cur-(p+5), nout < 64-4) {
			fprintf(stderr, "output Ethernet packet len %u too short\n", nout+4);
		} else if (check_crc32(p+1, nout)==0) {
			fprintf(stderr, "output packet len %u CRC failed\n",
				outbuf.cur);
		} else
#endif
		if (1 || ethernet_model_debug) {
			int rc = write(tapfd, p+1, nout);
			fprintf(stderr, "ethernet_model: Tx %u GMII octets, write rc=%d\n", outbuf.cur, rc);
			/* Note GMII octets include preamble and CRC, write rc includes neither */
		}
		outbuf.cur=0;
	}
	prev_out_valid = out_valid;
	return 0;  /* success */
}
