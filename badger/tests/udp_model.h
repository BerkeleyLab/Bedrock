#ifndef UDP_MODEL_H
#define UDP_MODEL_H
extern unsigned short udp_port;  /* Global */
void udp_receiver(int *in_octet, int *in_valid, int *in_count, int thinking);
void udp_sender(int out_octet, int out_end);
#endif
