#ifndef UDP_MODEL_H
#define UDP_MODEL_H
#ifdef __cplusplus
extern "C" {
#endif
extern unsigned short udp_port;  /* Global */
extern int badger_client;  /* Global */
void udp_receiver(int *in_octet, int *in_valid, int *in_count, int thinking);
void udp_sender(int out_octet, int out_end);
#ifdef __cplusplus
}
#endif
#endif
