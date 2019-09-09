/* udp_model.c */

/* Larry Doolittle, LBNL */

#include <vpi_user.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/stat.h>
#include <string.h>   /* strspn() */
#include <stdlib.h>   /* exit() */
#include <stdio.h>    /* snprintf() */
#include <unistd.h>   /* read() and write() */
#include <time.h>     /* nanosleep() */
#include <fcntl.h>
#include <assert.h>
#include <errno.h>
#include <stdint.h>

#include "udp_model.h"

/*
 * VPI (a.k.a. PLI 2) routines for connection to a UDP
 * port to/from a Verilog program.
 *
 * $udp_in(udp_idata, udp_iflag, udp_count, thinking);
 * $udp_outdup_odata, opack_complete);
 *   in_octet is data received from the UDP port, sent
 *      to the Verilog program.
 *   out_octet provided by the Verilog program, will be sent to
 *      the UDP port, once out_valid is low for a cycle.
 *
 * Written according to standards, but so far only tested on
 * Linux with Icarus Verilog.
 */

#define ETH_MAXLEN 1500   /* maximum line length */

static void setup_receive(int usd, unsigned int interface, unsigned short port)
{
	struct sockaddr_in sa_rcvr;
	memset(&sa_rcvr, 0, sizeof sa_rcvr);
	sa_rcvr.sin_family=AF_INET;
	sa_rcvr.sin_addr.s_addr=htonl(interface);
	sa_rcvr.sin_port=htons(port);
	if (bind(usd, (struct sockaddr *) &sa_rcvr, sizeof sa_rcvr) == -1) {
		perror("bind");
		fprintf(stderr, "could not bind to udp port %u\n", port);
		exit(1);
	}
}

struct pbuf {
	unsigned char buf[ETH_MAXLEN];
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
	unsigned jx;
	for (jx=0; jx < b->len; jx++) {
		fputc(' ', f);
		print_hex(f, b->buf[jx]);
	}
	fputc('\n', f);
}

struct sockaddr_in src_addr;  /* Global */
socklen_t src_addrlen;
int udpfd;

void udp_receiver(int *in_octet, int *in_valid, int *in_count, int thinking)
{
	static struct pbuf inbuf;
	static int initialized=0;
	int val = 0;
	static int sleepctr=0;
	static int sleepmax=10;
	static unsigned int preamble_cnt=0, postfix_cnt=0;
	int udp_model_debug = 0;  /* adjustable */

	if (!initialized) {
		fprintf(stderr, "udp_receiver initializing UDP port %u\n", udp_port);
		inbuf.cur = 0;
		inbuf.len = 0;
		initialized = 1;
		if ((udpfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
			perror("socket");
			exit(1);
		}
		setup_receive(udpfd, INADDR_ANY, udp_port);
		/* setup_transmit(udpfd, lskdjfsdlj, 2000); */
		fcntl(udpfd, F_SETFL, O_NONBLOCK);
	}

	if (inbuf.cur == inbuf.len) {
		/* non-blocking read packet */
		/* int rc = read(udpfd, inbuf.buf, ETH_MAXLEN); */
		int rc;
		src_addrlen = sizeof(src_addr);
		rc = recvfrom(udpfd, inbuf.buf, ETH_MAXLEN, 0, (struct sockaddr *) &src_addr, &src_addrlen);

		if (rc < 0 && errno == EAGAIN) {
			if (!thinking) sleepctr++;
			/* fprintf(stderr, "foo %d %d\n", sleepctr, thinking); */
			if (/* !out_valid && */ sleepctr > sleepmax) {
				struct timespec minsleep = {0, 100000000};
				nanosleep(&minsleep, NULL);
			}
		} else {
			fprintf(stderr, "udp_model: Rx %d udp bytes, source port %u\n", rc, src_addr.sin_port);
			/* for (unsigned jx=0; jx<src_addrlen; jx++) fprintf(stderr, " %2.2x", ((char *) &src_addr)[jx]); */
			inbuf.len = rc;
			inbuf.cur = 0;
			sleepctr = 0;
			preamble_cnt = 18;  /* should be 44(?) but I'm easily bored. */
			if (udp_model_debug) {
				fputs("Rx:", stderr);
				print_buf(stderr, &inbuf);
			}
		}
	}
	if (preamble_cnt > 0) {
		--preamble_cnt;
		if (in_valid) *in_valid = 1;
		if (in_count) *in_count = 0;
		return;
	}
	if (postfix_cnt > 0) {
		--postfix_cnt;
		if (in_valid) *in_valid = 1;
		if (in_count) *in_count = 0;
		return;
	}
	if (inbuf.cur < inbuf.len) {
		if (in_octet) *in_octet = inbuf.buf[inbuf.cur];
		inbuf.cur++;
		val = 1;
		if (inbuf.cur == inbuf.len) {
			postfix_cnt = 4;
			if (inbuf.len < 22) postfix_cnt = 26-inbuf.len;
		}
	}
	if (in_valid) *in_valid = val;
	if (in_count) *in_count = val ? inbuf.len + 1 - inbuf.cur : 0;
	if (udp_model_debug) {
		if (val) {
			unsigned o = (unsigned int)((*in_octet)&0xff);
			fprintf(stderr, "UDP model %2.2x to Verilog\n", o);
		} else {
			fprintf(stderr, ".");
		}
	}
}

void udp_sender(int out_octet, int out_end)
{
	static struct pbuf outbuf;
	static int initialized=0;
	int udp_model_debug = 0;  /* adjustable */
	if (!initialized) {
		outbuf.cur = 0;
		outbuf.len = 0;
		initialized = 1;
	}
	if (1) {
		if (udp_model_debug) fprintf(stderr, "Trying to write %2.2x\n", out_octet);
		outbuf.buf[outbuf.cur] = out_octet;
		if (outbuf.cur < ETH_MAXLEN) outbuf.cur++;
		else fprintf(stderr, "Ethernet output packet too long\n");
	}
	if (out_end) {
		/* write output packet */
		int rc = sendto(udpfd, outbuf.buf, outbuf.cur, 0, (struct sockaddr *) &src_addr, src_addrlen);
		if (rc < 0) perror("sendto");
		fprintf(stderr, "udp_model: Tx len %d, write rc=%d\n", outbuf.cur, rc);
		outbuf.cur=0;
	}
}
