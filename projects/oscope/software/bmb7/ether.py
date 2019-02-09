#!/usr/bin/python
import sys
import socket
import struct
import time
import sys,getopt
import os
import random
import numpy
import datetime
from time import gmtime, strftime

class c_ether:
	" Ethernet IO class for PSPEPS local bus access through mem_gateway "
	def __init__(self, ip, port):
		self.ip = ip
		self.port = port
		self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
		self.connect()

	def connect(self):
		self.socket.connect((self.ip, self.port))

	def __del__(self):
		self.socket.close()

def usage():
	print('usage: mbtest.py [commands]')
	print('-t, --target <ip address>')
	print('-h, --help')
	print('-a, --address <address in hex>')

if __name__ == "__main__":
	ip_addr = '192.168.21.11'
	port = 50006
	target = c_ether(ip_addr, port)
	print((dir(target.socket)))
