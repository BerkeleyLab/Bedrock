import socket

import sys
import struct

from collections import namedtuple
from datetime import datetime
from matplotlib import pyplot as plt

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
ip = sys.argv[1]
port = int(sys.argv[2])
sock.bind((ip, port))

def recvall(sock):
    BUFF_SIZE = 1024 * 1024 * 8
    data = []
    len_part = 0
    while True:
        part = sock.recv(1472)
        data.append(part)
        len_part += len(part)
        if len_part >= BUFF_SIZE:
            # either 0 or end of data
            break
    return data

data = recvall(sock)
E = []
for packet in data:
    x = len(packet)//8
    D = list(struct.unpack(f'>{x}Q', packet[::-1]))
    D.reverse()
    D.pop(0)
    E.extend(D)
print(len(E))
for i in range(len(E) - 1):
    if E[i] + 2 != E[i+1]:
        print(E[i], E[i+1], i)
plt.plot(E, '*')
plt.show()
