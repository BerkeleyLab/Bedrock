#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <netdb.h>     /* gethostbyname */
#include <errno.h>
#include <arpa/inet.h>

#define PRINT_PER_TX_PACKET 0
#define PRINT_PER_RX_PACKET 0

/* MTU = 1500, subtract 28 octets for IP and UDP header? */
#define LEN_MOD (981)
#define LEN_F(x) (492+((x)*8)%LEN_MOD)
#define NEXT(x) ((x*3+1)&0xff)
static unsigned udp_handle(char *data, unsigned data_len)
{
	unsigned u;
	unsigned key = data[0]&0xff;
	unsigned sta = key;
	unsigned want_len = LEN_F(key);
	unsigned fail=0;

	static unsigned last_key=-1;
	if (key != ((last_key+1)&0xff)) {
		fprintf(stderr, "dropped packet? key %u not %u+1\n", key, last_key);
	}
	last_key = key;

	if (data_len != want_len) {
		fprintf(stderr, "length not %u", want_len);
		fail++;
	}
	if (1) for (u=0; u<data_len; u++) {
		unsigned want_d = sta ^ (u&0xff);
		if ((data[u]&0xff) != want_d) {
			printf("data[%u]=%2.2x!=%2.2x\n", u, data[u]&0xff, want_d);
			fail++;
		}
		sta = NEXT(sta);
	}
	if (fail || PRINT_PER_RX_PACKET) printf("udp_handle  length=%u  key=%u  ", data_len, key);
	if (fail) {
		printf("%d FAIL\n", fail);
	} else {
		if (PRINT_PER_RX_PACKET) printf("PASS\n");
	}
	return fail;
}

static void send_packet(int usd, unsigned id)
{
	char foo[1500];
	unsigned u;
	unsigned key = id & 0xff;
	unsigned len = LEN_F(key);
	unsigned sta = key;
	for (u=0; u<len; u++) {
		foo[u] = sta;
		sta = NEXT(sta);
	}
	if (PRINT_PER_TX_PACKET) printf("send_packet %u, key %u len %u\n", id, key, len);
	send(usd, foo, len, 0);
}

static void primary_loop(int usd, unsigned npack, unsigned juggle)
{
	fd_set fds_r, fds_e;
	struct sockaddr sa_xmit;
	unsigned int sa_xmit_len;
	struct timeval to;
	int i, pack_len;
	int debug1=0;
	unsigned probes_sent=0, probes_recv=0, probes_fail=0;
	unsigned timeouts=0;
	static char incoming[1500];
	sa_xmit_len = sizeof sa_xmit;
	for (probes_sent=0; probes_sent<juggle; probes_sent++) {
		send_packet(usd, probes_sent);
	}
	to.tv_sec = 0;
	to.tv_usec = 0;
	for (;npack == 0 || probes_recv < npack;) {
		FD_ZERO(&fds_r);
		FD_SET(usd, &fds_r);
		FD_ZERO(&fds_e);
		FD_SET(usd, &fds_e);
		to.tv_sec = 0;
		to.tv_usec = 10000;
		i = select(usd+1, &fds_r, NULL, &fds_e, &to);
		  /* Wait on read or error */
		if (debug1) printf("select returns %d,", i);
		if ((i!=1)||(!FD_ISSET(usd, &fds_r))) {
			if (i<0) {
				if (debug1) printf(" error\n");
				if (errno != EINTR) perror("select");
				else printf("EINTR\n");
			} else if (i==0) {
				if (debug1) printf(" sending\n");
				send_packet(usd, probes_sent);
				++probes_sent;
				++timeouts;
			}
			continue;
		}
		if (debug1) printf(" receiving\n");
		pack_len = recvfrom(usd, incoming, sizeof incoming, 0,
		                  &sa_xmit, &sa_xmit_len);
		if (pack_len<0) {
			perror("recvfrom");
		} else if (pack_len>0 && (unsigned)pack_len<sizeof incoming){
			++probes_recv;
			if (udp_handle(incoming, pack_len)>0) ++probes_fail;
			if (probes_recv > probes_sent-juggle) {
				send_packet(usd, probes_sent);
				++probes_sent;
			}
		} else {
			fprintf(stderr, "Ooops.  pack_len=%d\n", pack_len);
			break;
		}
		to.tv_sec = 0;
		to.tv_usec = 0;
	}
	printf("%u packets sent, %u received, %u failed, %u timeouts\n",
		probes_sent, probes_recv, probes_fail, timeouts);
}

static void stuff_net_addr(struct in_addr *p, char *hostname)
{
	struct hostent *server;
	server = gethostbyname(hostname);
	if (server == NULL) {
		herror(hostname);
		exit(1);
	}
	if (server->h_length != 4) {
		/* IPv4 only */
		fprintf(stderr, "oops %d\n", server->h_length);
		exit(1);
	}
	memcpy(&(p->s_addr), server->h_addr_list[0], 4);
}

static void setup_receive(int usd, unsigned int interface, short port)
{
	struct sockaddr_in sa_rcvr;
	memset(&sa_rcvr, 0, sizeof sa_rcvr);
	sa_rcvr.sin_family = AF_INET;
	sa_rcvr.sin_addr.s_addr = htonl(interface);
	sa_rcvr.sin_port = htons(port);
	if(bind(usd, (struct sockaddr *) &sa_rcvr, sizeof sa_rcvr) == -1) {
		perror("bind");
		fprintf(stderr, "could not bind to udp port %d\n", port);
		exit(1);
	}
}

static void setup_transmit(int usd, char *host, short port)
{
	struct sockaddr_in sa_dest;
	memset(&sa_dest, 0, sizeof sa_dest);
	sa_dest.sin_family = AF_INET;
	stuff_net_addr(&(sa_dest.sin_addr), host);
	sa_dest.sin_port = htons(port);
	if (connect(usd, (struct sockaddr *)&sa_dest, sizeof sa_dest)==-1) {
		perror("connect");
		exit(1);
	}
}

int main(int argc, char *argv[])
{
	int usd;
	unsigned npack=0;
	unsigned juggle=1;
	if (argc<2) {
		fprintf(stderr, "Usage: %s host npack juggle\n", argv[0]);
		exit(1);
	}

	if (argc>=3) npack = atoi(argv[2]);
	if (argc>=4) juggle = atoi(argv[3]);

	usd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
	if (usd==-1) {
		perror("socket");
		exit(1);
	}

	setup_receive(usd, INADDR_ANY, 0);

	setup_transmit(usd, argv[1], 802);

	primary_loop(usd, npack, juggle);
	close(usd);
	return 0;
}
