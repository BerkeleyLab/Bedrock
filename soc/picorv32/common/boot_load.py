#!/usr/bin/env python
#
# This is free and unencumbered software released into the public domain.
#
# Anyone is free to copy, modify, publish, use, compile, sell, or
# distribute this software, either in source code form or as a compiled
# binary, for any purpose, commercial or non-commercial, and by any
# means.
'''
    Picorv32soc serial bootloader. Resets the target (optional),
    waits to receive the start word 'Ok', then sends the content
    of a .hex file to be stored in program memory.
'''
from __future__ import print_function
import serial
import struct
import argparse


def hex_dump(xs, fName):
    with open(fName, 'w') as f:
        for i, x in enumerate(xs):
            if i % 16 == 0:
                f.write('\n{:04x}: '.format(i))
            f.write(' {:02x}'.format(x))
        f.write(' ')


def read_verilog_hex(fName):
    '''
    Read a verilog .hex file with 32 bit words.
    Returns a bytearray with the data, ready to be flashed into
    picoRV32 memory
    '''
    binBuffer = bytearray(2**16 * 4)
    currentWordAddr = 0
    with open(fName) as f:
        for hexLine in f:
            hexLine = hexLine.strip()
            if hexLine.startswith('\\'):
                continue
            if hexLine.startswith('@'):
                currentWordAddr = int(hexLine[1:], 16)
                print(hexLine)
                continue
            tempWord = int(hexLine, 16)
            binBuffer[currentWordAddr * 4 + 3] = (tempWord >> 24) & 0xFF
            binBuffer[currentWordAddr * 4 + 2] = (tempWord >> 16) & 0xFF
            binBuffer[currentWordAddr * 4 + 1] = (tempWord >> 8) & 0xFF
            binBuffer[currentWordAddr * 4 + 0] = (tempWord >> 0) & 0xFF
            currentWordAddr += 1
    return binBuffer[0: currentWordAddr * 4]


def blocking_rx(s, expectStr):
    temp = s.readline()
    while not temp.endswith(expectStr):
        print(temp.decode('ascii', errors='ignore'))
        temp = s.readline()
    print('done')


def bootload(bin_buffer, ser_port, baud_rate, byte_offset,
             reset_rts, reset_soft=True):
    '''
    connects to serial bootloader and uploads the byteArray `bin_buffer`
    to the picoRV32 memory at offset `byte_offset` (in bytes).
    Any content of `bin_buffer` before that offset is ignored
    (preserve bootloader code).
    '''
    s = serial.Serial(ser_port, baud_rate, timeout=5, xonxoff=False,
                      rtscts=False, dsrdtr=False)
    bin_buffer = bin_buffer[byte_offset:]
    print('Push reset ... ', end='')
    # Try a remote reset
    s.flush()
    if reset_rts:
        s.setRTS(1)
    if reset_soft:
        s.write(b'\x14')
    s.flushInput()
    if reset_rts:
        s.setRTS(0)
    # Wait for `ok\n` from the bootloader
    blocking_rx(s, b'ok\n')
    # Answer with `g`
    s.write(b'g')
    s.flush()
    print('Wait ... ', end='')
    # Wait for `o` from the bootloader
    blocking_rx(s, b'o\n')
    # Write memory
    nBytes = len(bin_buffer)
    s.write(struct.pack('>I', nBytes))
    s.flush()
    nSent = s.write(bin_buffer)
    s.flush()
    print('Sent 0x{:02x} / 0x{:02x} bytes'.format(nSent, nBytes))
    # Read and verify memory
    print('Verifying ... ', end='')
    readBackData = bytearray(0)
    readBackData += s.read(nBytes)
    while len(readBackData) < nBytes:
        b = s.read(nBytes - len(readBackData))
        if len(b) == 0:
            break
        readBackData += b
    s.close()
    if readBackData == bin_buffer:
        print('passed.')
    else:
        print('!!! Readback Error !!!')
        hex_dump(readBackData, 'rx.hex')
        hex_dump(bin_buffer, 'tx.hex')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('hex_file',
                        help='Verilog .hex file with program memory data')
    parser.add_argument('ser_port',
                        help='Serial port file')
    parser.add_argument('--baud_rate', default=115200, type=int,
                        help='Serial port baudrate')
    parser.add_argument('--byte_offset', default=0xe0, type=int,
                        help='Clip N bytes from beginning of hex file')
    parser.add_argument('--reset_rts', action='store_true',
                        help='Toggle RTS line to trigger hard reset')
    argsD = vars(parser.parse_args())

    binData = read_verilog_hex(argsD.pop('hex_file'))
    print('hex file length: {:}'.format(len(binData)))
    bootload(binData, **argsD)


if __name__ == '__main__':
    main()
