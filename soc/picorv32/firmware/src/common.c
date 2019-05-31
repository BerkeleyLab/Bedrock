// Things which we need but are in C standard library, which we don't have

#include <common.h>

void *memcpy(void *dest, const void *src, size_t n){
    const uint8_t *a = (const uint8_t *)src;
    uint8_t *b = (uint8_t *)dest;
    while( n-- > 0 ){
        *b++ = *a++;
    }
    return dest;
}

void *memset(void *s, int c, size_t n){
    uint8_t *b = (uint8_t *)s;
    while( n-- > 0 ){
        *b++ = (uint8_t)c;
    }
    return s;
}

int memcmp(const void *s1, const void *s2, size_t n){
    const uint8_t *a = (const uint8_t *)s1;
    const uint8_t *b = (const uint8_t *)s2;
    int c = 0;
    while( n-- > 0 ){
        c = *b++ - *a++;
        if( c != 0 ) break;
    }
    return c;
}
