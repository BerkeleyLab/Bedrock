/* Original yanked from wiRe's s1fwx.  Ford only knows where he got it. */

#include <stdio.h>
#include "crc32.h"

#include <stdint.h>

int crc_table_init = 0;
static uint32_t crc_table[256];

/* Generate the CRC table. Must be called before calculating the CRC value. */
void init_crc32(uint32_t poly)
{
  for(unsigned i = 0; i < 256; i++) {
    uint32_t crc = i;
    for(int j = 8; j > 0; j--) {
      if (crc & 1) crc = (crc >> 1) ^ poly;
      else crc >>= 1;
    }
    crc_table[i] = crc;
  }
  crc_table_init = 1;
}


uint32_t calc_crc32(const void *ptr, size_t size)
{
  uint32_t crc = 0xFFFFFFFF;
  unsigned const char *cp = (unsigned const char *) ptr;
  if(!crc_table_init) init_crc32(0xEDB88320L);
  for(; size > 0; size--,cp++)
    crc = (crc>>8) ^ crc_table[ (crc^*cp) & 0xFF ];
  return(crc^0xFFFFFFFF);
}

/* In these next two routines, size is the payload size
 * without checksum appended.
 */
int check_crc32(const void *ptr, size_t size)
{
  uint32_t crc;
  unsigned const char *cp = (unsigned const char *) ptr + size;
  crc = calc_crc32(ptr, size);
  if (0) printf("crc should be %8.8x\ncrc        is %2.2x%2.2x%2.2x%2.2x\n",
	crc, *(cp+3), *(cp+2), *(cp+1), *(cp+0));
  if ((*(cp+0) != (crc     & 0xff)) ||
      (*(cp+1) != (crc>>8  & 0xff)) ||
      (*(cp+2) != (crc>>16 & 0xff)) ||
      (*(cp+3) != (crc>>24 & 0xff))) return 0;  /* Fail */
  return 1;  /* success */
}

void append_crc32(void *ptr, size_t size)
{
  uint32_t crc;
  unsigned char *cp = (unsigned char *) ptr + size;
  crc = calc_crc32(ptr, size);
  *(cp+0) = crc     & 0xff;
  *(cp+1) = crc>>8  & 0xff;
  *(cp+2) = crc>>16 & 0xff;
  *(cp+3) = crc>>24 & 0xff;
}
