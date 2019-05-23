#ifndef _CRC32_H_
#define _CRC32_H_

#include <stdint.h>

/* Generate the CRC table. Must be called before calculating the CRC value. */
void init_crc32(uint32_t poly);

uint32_t calc_crc32(const void *ptr, size_t size);
int check_crc32(const void *ptr, size_t size);
void append_crc32(void *ptr, size_t size);

#endif
