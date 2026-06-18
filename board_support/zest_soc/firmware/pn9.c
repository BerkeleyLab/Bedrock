#include <stdio.h>
#include <stdint.h>
// https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence
// PRBS9 in 16-bit parallel representation
int main(int argc, char* argv[]) {
    uint16_t start = 0x1ff;
    uint16_t p = 0;
    // XXX Step=1201, 16bit: 0x561b, state: 0x01a6
    // uint16_t start = 0x1a6; // step 1201
    // uint16_t p = 0x561b;    // step 1201
    // uint16_t start = 0x07c; // step 1601
    // uint16_t p = 0x768f;    // step 1601
    // uint16_t start = 0x0a9; // step 1617
    // uint16_t p = 0x3e6c;    // step 1617
    uint16_t sr = start;
    for (int i = 1; i <= 512*16; i++) {
        printf("XXX Step=%4d, 16bit: %#06x, state: %#06x\n", i, p, sr);
        p = ((p << 1) | ((sr>>8) & 1)); // shift to parallel
        if (i % 16 == 0) printf("Step=%4d, 16bit: %#06x, state: %#06x\n", i, p, sr);
        uint8_t newbit = (((sr >> 8) ^ (sr >> 4)) & 1);
        sr = ((sr << 1) | newbit) & 0x1ff;
        if (sr == start) printf("PRBS repeats at %d\n", i);
    }
}
