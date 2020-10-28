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

#ifndef _NMEA_H_
#define _NMEA_H_

/**
 * Call this routine with each character from GPS receiver.
 * You must provide three callback routines, described below.
 */
void NMEAconsume(int c);

/**
 * Callback invoked when an invalid NMEA sentence is detected.
 */
void NMEAerror(const char *message);

/**
 * Callback invoked upon arrival of a valid NMEA sentence.
 */
void NMEAcallback(const char *sentence);

/**
 * Callback invoked with values extracted from valid NMEA 'RMC' sentence.
 */
void NMEAtime(unsigned int posixSeconds, unsigned int fractionalSeconds);

#endif /* _NMEA_H_ */
