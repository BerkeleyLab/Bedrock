#ifndef COMMON_H
#define COMMON_H

#include <stdint.h>
#include <stddef.h>

// Read a single bit
#define CHECK_BIT(var,pos) ((var) & (1<<(pos)))

// Read / write a byte from / to the MEM bus
#define GET_REG8(reg)      (*((volatile uint8_t*)(reg)))
#define SET_REG8(reg,val)  {*((volatile uint8_t*)(reg)) = (val);}

// Read / write a 16 bit word from / to the MEM bus
#define GET_REG16(reg)     (*((volatile uint16_t*)(reg)))
#define SET_REG16(reg,val) {*((volatile uint16_t*)(reg)) = (val);}

// Read / write a 32 bit word from / to the MEM bus
#define GET_REG(reg)       (*((volatile uint32_t*)(reg)))
#define SET_REG(reg,val)   {*((volatile uint32_t*)(reg)) = (val);}

// misc. useful stuff
#define MAX(a,b) ((a)>(b)?(a):(b))
#define MIN(a,b) ((a)<(b)?(a):(b))

// Swap endian-ness
#define SWAP16(x) (                                                   (((x)<<8)&0x0000ff00) | (((x)>> 8)&0x000000ff) )
#define SWAP32(x) ( (((x)<<24)&0xff000000) | (((x)<<8)&0x00ff0000)  | (((x)>>8)&0x0000ff00) | (((x)>>24)&0x000000ff) ) //Clearly needs more brackets :p

// string.h replacements
void *memcpy(void *dest, const void *src, size_t n);
void *memset(void *s, int c, size_t n);
int   memcmp(const void *s1, const void *s2, size_t n);

#endif
