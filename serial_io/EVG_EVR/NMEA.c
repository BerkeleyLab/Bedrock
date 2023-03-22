/*
 * MIT License
 *
 * Copyright (c) 2020 Osprey DCS
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * NMEA parsing
 */

#include <stdio.h>
#include <ctype.h>
#include "NMEA.h"

static int satellitesInView = -1;

/*
 * Returns number of days since civil 1970-01-01
 * Ref: http://howardhinnant.github.io/date_algorithms.html#days_from_civil
 */
static int
days_from_civil(int y, unsigned m, unsigned d)
{
    y -= m <= 2;
    const int era = (y >= 0 ? y : y-399) / 400;
    const unsigned yoe = (y - era * 400);                         // [0, 399]
    const unsigned doy = (153*(m + (m > 2 ? -3 : 9)) + 2)/5 + d-1;// [0, 365]
    const unsigned doe = yoe * 365 + yoe/4 - yoe/100 + doy;       // [0, 146096]
    return era * 146097 + doe - 719468;
}

static int
hexval(char c)
{
    if ((c >= '0') && (c <= '9')) return c - '0';
    if ((c >= 'A') && (c <= 'F')) return c - 'A' + 10;
    if ((c >= 'a') && (c <= 'f')) return c - 'a' + 10;
    NMEAerror("Bad hex char");
    return -1;
}

static int
decval(char c)
{
    if ((c >= '0') && (c <= '9')) return c - '0';
    return -1;
}

static void
parse(const char *sentence)
{
    const char *cp = sentence;
    const char *fmt = "$GPx";
    int v;
    int value;
    int width;
    int vIdx = 0;
    int vBuf[7]; /* hh, mm, ss, ms, DD, MM, YY */

    while (*fmt) {
        if (*cp == '\0') {
            NMEAerror("Sentence too short");
            return;
        }
        switch (*fmt) {
        case 'x':
            switch(*cp) {
            case 'R': fmt = "RMC,dddf,a,,,,,,,ddd";  break;
            case 'G': fmt = "GSV,,,d";               break;
            default: return;
            }
            break;

        case 'd':
        case 'f':
            value = 0;
            if (*fmt == 'f') {
                if (*cp == '.') cp++;
                width = -1;
            }
            else {
                width = 2;
            }
            fmt++;
            for (;;) {
                v = decval(*cp);
                if (v < 0) {
                    if (width < 0) break;
                    NMEAerror("Bad digit");
                    return;
                }
                value = (value * 10) + v;
                cp++;
                if ((width > 0) && (--width == 0))
                    break;
            }
            vBuf[vIdx++] = value;
            break;

        case ',':
            if (*cp++ == ',') {
                fmt++;
            }
            break;

        case 'a':
            v = *cp++;
            fmt++;
            if (v == 'V') {
                NMEAerror("RMC time/position invalid");
                return;
            }
            else if (v != 'A') {
                NMEAerror("Unexpected character");
                return;
            }
            break;

        default:
            if (*cp++ != *fmt++) {
                return;
            }
            break;
        }
    }
    switch (vIdx) {
    case 1:
        satellitesInView = vBuf[0];
        break;

    case 7:
        {
        int y = vBuf[6] + (vBuf[6] < 20 ? 2100 : 2000);
        NMEAtime(days_from_civil(y, vBuf[5], vBuf[4])*86400U +
                                            vBuf[0]*3600 + vBuf[1]*60 + vBuf[2],
                                                              vBuf[3]*4294967U);
        }
        break;
    }
}

void
NMEAconsume(int c)
{
    int v;
    static int chksum;
    static int val;
    static enum { stIdle, stStart, stPayload, stChkHi, stChkLo } state = stIdle;
    static char sentence[90];
    static int sIdx;

    if (c == '$') {
        if (state != stIdle) NMEAerror("Unexpected $");
        sIdx = 0;
        state = stStart;
    }
    if (state != stIdle) {
        if (sIdx >= (int)(sizeof(sentence)-1)) {
            NMEAerror("Sentence too long");
            state = stIdle;
            return;
        }
        sentence[sIdx++] = c;
    }
    switch (state) {
    case stIdle:
        break;

    case stStart:
        chksum = 0;
        state = stPayload;
        break;

    case stPayload:
        if (c == '*') {
            state = stChkHi;
        }
        else {
            chksum ^= c;
        }
        break;

    case stChkHi:
        if ((v = hexval(c)) < 0) {
            state = stIdle;
        }
        else {
            val = v << 4;
            state = stChkLo;
        }
        break;

    case stChkLo:
        sentence[sIdx] = '\0';
        if ((v = hexval(c)) >= 0) {
            if ((val | v) == chksum) {
                NMEAcallback(sentence);
                parse(sentence);
            }
            else {
                NMEAerror("Checksum mismatch");
            }
        }
        state = stIdle;
        break;
    }
}

int
NMEAsatellitesInView(void)
{
    return satellitesInView;
}
