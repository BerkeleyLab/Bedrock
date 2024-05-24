/* Converts pcap dumps into the stream of bytes accepted by
 * scanner_tb, rtefi_pipe_tb, or any other testbench that
 * uses offline.v */
#include <pcap/pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "crc32.h"

void print_stream(pcap_t *pbuf)
{
	const unsigned char *packet_data;
	struct pcap_pkthdr header;
	unsigned int ix, total;
	/* Sorry this is hard-coded. */
	const unsigned char fpga_mac[] = "\x12\x55\x55\x11\x02\x3E";
	uint32_t p_crc;
	total = 0;
	while ((packet_data = pcap_next(pbuf, &header))) {
		/* Throw away packets that were sent _from_ the FPGA */
		if (memcmp(fpga_mac, packet_data+6, 6) == 0) continue;
		p_crc = calc_crc32(packet_data, header.len);
		if (0) {  /* debug */
			printf("got  %4d %8.8x", header.len, p_crc);
			printf("  source mac");
			for (ix=0; ix<6; ix++) printf(" %2.2X", packet_data[ix+6]);
			printf("  dest mac");
			for (ix=0; ix<6; ix++) printf(" %2.2X", packet_data[ix]);
			printf("\n");
		}
		/* GMII preamble */
		for (ix=0; ix<7; ix++) printf("55\n");
		printf("D5\n");
		/* Packet contents */
		for (ix=0; ix<header.len; ix++) {
			printf("%2.2X\n", packet_data[ix]);
		}
		/* Emit CRC32 */
		printf("%2.2X\n", (p_crc     ) & 0xff);
		printf("%2.2X\n", (p_crc>>8  ) & 0xff);
		printf("%2.2X\n", (p_crc>>16 ) & 0xff);
		printf("%2.2X\n", (p_crc>>24 ) & 0xff);
		printf("stop 04\n");
		total++;
		/* if (total > 80) break; */
	}
	printf("tests %u\n", total);
}

int main(int argc, char *argv[])
{
	char errbuf[PCAP_ERRBUF_SIZE];
	pcap_t *pbuf;
	if (argc < 2) {
		printf("usage: pcap2v pcap-file > offline-v-file.dat\n");
		exit(1);
	}
	pbuf = pcap_open_offline(argv[1], errbuf);
	if (pbuf == NULL) {
		printf("pcap_open_offline reports error %s\n", errbuf);
		exit(2);
	}
	print_stream(pbuf);
	return 0;
}
