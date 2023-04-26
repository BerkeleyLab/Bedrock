#ifndef UDP_MODEL_H
#define UDP_MODEL_H
#ifdef __cplusplus
extern "C" {
#endif

/* This is the original API, simple but limited to a single UDP handler per program. */
extern unsigned short udp_port;  /* Global */
extern int badger_client;  /* Global */
void udp_receiver(int *in_octet, int *in_valid, int *in_count, int thinking);
void udp_sender(int out_octet, int out_end);

/* This is a more general API, where the user program has to carry around
 * the struct udp_state * pointer.  Allows multiple UDP handlers per program. */
struct udp_state;
struct udp_state *udp_setup_r(unsigned short udp_port, int badger_client);
void udp_receiver_r(struct udp_state *ust, int *in_octet, int *in_valid, int *in_count, int thinking);
void udp_sender_r(struct udp_state *ust, int out_octet, int out_end);
#ifdef __cplusplus
}
#endif
#endif
