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
 * UDP model used by udp-vpi.c VPI front-end.
 *
 * udp_receiver() supports two interface modes,
 * as selected by badger_client global variable:
 *    0: Raw bytes+strobe interface
 *    1: Badger-client interface, as defined in badger/clients.eps
 *
 * Written according to standards, but so far only tested on
 * Linux with Icarus Verilog and Verilator.
 */

#define ETH_MAXLEN 1500   /* maximum line length */

/* Header defines an opaque struct udp_state; this completes it. */
struct udp_state {
	int badger_client;
	struct pbuf *inbuf;
	struct pbuf *outbuf;
	int sleepctr;
	int sleepmax;
	int preamble_cnt;
	int postfix_cnt;
	int udpfd;
	struct sockaddr_in src_addr;
	socklen_t src_addrlen;
};

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

/* The following two globals are only used for the non-_r routines */
struct udp_state* static_usp;
int udp_initialized=0;
/* and maybe I can deprecate the non-_r routines someday */

void udp_receiver(int *in_octet, int *in_valid, int *in_count, int thinking)
{
	if (udp_initialized == 0) {
		static_usp = udp_setup_r(udp_port, badger_client);
		udp_initialized = 1;
	}
	udp_receiver_r(static_usp, in_octet, in_valid, in_count, thinking);
}

/* Jump through extra hoops so this file can be compiled both as C and C++
 * Aaugh.  */
#ifdef __cplusplus
#define PBUF_P (struct pbuf *)
#define US_P (struct udp_state *)
#else
#define US_P
#define PBUF_P
#endif

struct udp_state *udp_setup_r(unsigned short udp_port_, int badger_client_)
{
	struct udp_state *ust = US_P calloc(sizeof (struct udp_state), 1);
	ust->sleepctr=0;
	ust->sleepmax=10;
	fprintf(stderr, "udp_receiver initializing UDP port %u. Interface mode: ", udp_port_);
	if (badger_client_) {
		fprintf(stderr, "Badger-client\n");
	} else {
		fprintf(stderr, "Raw\n");
	}
	ust->badger_client = badger_client_;
	/* following could be combined by making second argument to calloc a 2? */
	struct pbuf *inbuf  = ust->inbuf  = PBUF_P calloc(sizeof(struct pbuf), 1);
	struct pbuf *outbuf = ust->outbuf = PBUF_P calloc(sizeof(struct pbuf), 1);
	if (!inbuf || !outbuf) {
		perror("calloc");
		exit(1);
	}
	if ((ust->udpfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
		perror("socket");
		exit(1);
	}
	setup_receive(ust->udpfd, INADDR_ANY, udp_port_);
	/* setup_transmit(udpfd, lskdjfsdlj, 2000); */
	fcntl(ust->udpfd, F_SETFL, O_NONBLOCK);
	return ust;
}

void udp_receiver_r(struct udp_state *ust, int *in_octet, int *in_valid, int *in_count, int thinking)
{
	int val = 0;
	int udp_model_debug = 0;  /* adjustable */
	struct pbuf *inbuf = ust->inbuf;  /* makes source look cleaner; maybe optimizes away */

	if (inbuf->cur == inbuf->len) {
		int rc;
		ust->src_addrlen = sizeof(ust->src_addr);
		rc = recvfrom(ust->udpfd, inbuf->buf, ETH_MAXLEN, 0, (struct sockaddr *) &(ust->src_addr), &(ust->src_addrlen));
		if (rc < 0 && errno == EAGAIN) {
			if (!thinking) ust->sleepctr++;
			/* fprintf(stderr, "foo %d %d\n", sleepctr, thinking); */
			if (/* !out_valid && */ ust->sleepctr > ust->sleepmax) {
				struct timespec minsleep = {0, 100000000};
				nanosleep(&minsleep, NULL);
			}
		} else {
			fprintf(stderr, "udp_model: Rx %d udp bytes, source port %u\n", rc, ust->src_addr.sin_port);
			if (0) {
				for (unsigned jx=0; jx<ust->src_addrlen; jx++) {
					fprintf(stderr, " %2.2x", ((char *) &(ust->src_addr))[jx]);
				}
			}
			inbuf->len = rc;
			inbuf->cur = 0;
			ust->sleepctr = 0;
			ust->preamble_cnt = 18;  /* should be 44(?) but I'm easily bored. */
			if (udp_model_debug) {
				fputs("Rx:", stderr);
				print_buf(stderr, inbuf);
			}
		}
	}
	if (ust->badger_client) { // Badger client interface
		if (ust->preamble_cnt > 0) {
			--(ust->preamble_cnt);
			if (in_valid) *in_valid = 1;
			if (in_count) *in_count = 0;
			return;
		}
		if (ust->postfix_cnt > 0) {
			--(ust->postfix_cnt);
			if (in_valid) *in_valid = 1;
			if (in_count) *in_count = 0;
			return;
		}
	}
	if (inbuf->cur < inbuf->len) {
		if (in_octet) *in_octet = inbuf->buf[inbuf->cur];
		inbuf->cur++;
		val = 1;
		if (badger_client) {
			if (inbuf->cur == inbuf->len) {
				ust->postfix_cnt = 4;
				if (inbuf->len < 22) ust->postfix_cnt = 26-inbuf->len;
			}
		}
	}
	if (in_valid) *in_valid = val;
	if (in_count) *in_count = val ? inbuf->len + 1 - inbuf->cur : 0;
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
	if (udp_initialized == 0) {
		static_usp = udp_setup_r(udp_port, badger_client);
		udp_initialized = 1;
	}
	udp_sender_r(static_usp, out_octet, out_end);
}

void udp_sender_r(struct udp_state *ust, int out_octet, int out_end)
{
	struct pbuf *outbuf = ust->outbuf;  /* makes source look cleaner; maybe optimizes away */
	int udp_model_debug = 0;  /* adjustable */
	if (1) {
		if (udp_model_debug) fprintf(stderr, "Trying to write %2.2x\n", out_octet);
		outbuf->buf[outbuf->cur] = out_octet;
		if (outbuf->cur < ETH_MAXLEN) outbuf->cur++;
		else fprintf(stderr, "Ethernet output packet too long\n");
	}
	if (out_end) {
		/* write output packet */
		outbuf->len = outbuf->cur;
		if (udp_model_debug) {
			printf("Tx:");  print_buf(stdout, outbuf);
		}
		int rc = sendto(ust->udpfd, outbuf->buf, outbuf->cur, 0, (struct sockaddr *) &(ust->src_addr), ust->src_addrlen);
		if (rc < 0) perror("sendto");
		fprintf(stderr, "udp_model: Tx len %d, write rc=%d\n", outbuf->cur, rc);
		outbuf->cur=0;
	}
}
