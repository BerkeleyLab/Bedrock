#!/usr/bin/env python3
'''
connect to serial port and speak to cmod
usage:
python3 hw_test.py /dev/ttyUSB1
'''
from sys import argv, exit
from serial import Serial
from time import sleep

if len(argv) != 2:
    print(__doc__)
    exit(-1)

print('hw_test.py: connecting to CMOD-A7 at', argv[1])
with Serial(port=argv[1], baudrate=115200, timeout=5) as s:
    s.write(b'\x14')  # reset picorv
    s.flush()
    sleep(0.25)
    s.write(b's\n')   # start sieve
    while True:
        ln = s.readline()
        if len(ln) == 0:
            print('hw_test.py: serial timeout!')
            exit(-1)
        print(ln.decode(), end='')
        if ln == b'PASS\n':
            exit(0)
