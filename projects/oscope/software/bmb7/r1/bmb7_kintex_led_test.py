#!/bin/env python

from socket import *
import string
import time
import sys

class GTX_LOOPBACK_MODES:
        NORMAL = 0
        NEAR_END_PCS = 1
        NEAR_END_PMA = 2
        FAR_END_PMA = 4
        FAR_END_PCS = 6

class interface():

        def __init__(self, target):

                self.host = target
                self.port =     50006
                self.daq_port = 50007
                self.daq_bytes = list()

                # Interface socket
                self.UDPSock = socket(AF_INET,SOCK_DGRAM)
                self.UDPSock.bind(("0.0.0.0", self.port))
                self.UDPSock.settimeout(0.05)

                #self.DAQSock = socket(AF_INET,SOCK_DGRAM)
                #self.DAQSock.bind(("0.0.0.0", self.daq_port))
                #self.DAQSock.settimeout(10)

                self.write_bytes = bytearray(2)
                self.read_bytes = bytearray(2)

                # Initialize DAQ pathway
                #self.DAQSock.sendto(str(bytearray(10)),(self.host, self.daq_port))

                # Initialize
                self.send_receive()

        def send_receive(self):
                rbytes = bytearray()
                rbytes[:] = self.write_bytes
                rbytes.reverse()
                read_bytes = str()

                while True:
                        try:
                                self.UDPSock.sendto(str(rbytes),(self.host, self.port))
                                while True:
                                        read_bytes, address = self.UDPSock.recvfrom(1450)
                                        if not read_bytes:
                                                raise Exception('No data received')
                                        if address[1] == self.port:
                                                break
                                break
                        except KeyboardInterrupt:
                                print 'Ctrl-C detected'
                                exit(0)
                        except:
                                continue

                self.read_bytes = bytearray(read_bytes)
                self.read_bytes.reverse()

        def set_leds(self, value):
                self.write_bytes[0] = 0xff & value
                self.send_receive()
#                print len(self.read_bytes),[hex(i) for i in self.read_bytes]
                print 'Values read', hex(self.read_bytes[0]), hex(self.read_bytes[1])

