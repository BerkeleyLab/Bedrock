#!/usr/bin/env python3
'''
Hardware in the loop test.
Connect to serial port and speak to CMOD-A7

usage:
python3 hw_test.py /dev/ttyUSB1

or:
python3 hw_test.py 210328A6DA44
'''
from sys import argv, exit
from serial import Serial
from serial.tools import list_ports
from time import sleep

def getPort(req):
    '''
    req can be /dev/ttyUSB1 or a
    serial number like 210328A6DA44
    '''
    for port in list_ports.comports():
        if port.device == req or port.serial_number == req:
            return port
    raise RuntimeError("Port not found: " + req)

if len(argv) != 2:
    print(__doc__)
    exit(-1)

p = getPort(argv[1])

print('hw_test.py: connecting to', p, p.serial_number)
with Serial(port=p.device, baudrate=115200, timeout=5) as s:
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
        if ln == b'FAIL\n':
            exit(-1)
