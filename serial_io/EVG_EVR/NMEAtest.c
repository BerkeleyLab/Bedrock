#include <stdio.h>
#include <ctype.h>
#include "NMEA.h"

static char *cp;

void
NMEAtime(unsigned int posixSeconds, unsigned int fractionalSeconds)
{
    printf("POSIX Seconds %u:%u\n", posixSeconds, fractionalSeconds);
}

void
NMEAerror(const char *message)
{
    printf("Conversion failure: %s\n", message);
}

void
NMEAcallback(const char *sentence)
{
    printf("Conversion success: \"%s\"\n", sentence);
}

int
main (int argc, char **argv)
{
    int i;

    for (i = 1 ; i < argc ; i++) {
        cp = argv[i];
        printf("\"%s\"\n", cp);
        while (*cp) {
            NMEAconsume(*cp++);
        }
    }
    return 0;
}
