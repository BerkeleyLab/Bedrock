#!/usr/bin/python
import sys
import struct
import random
from bmb7.ether import c_ether


class c_mem_gateway(c_ether):
    " Ethernet IO class for PSPEPS local bus access through mem_gateway "

    def __init__(self, ip, port, min3=False):
        c_ether.__init__(self, ip, port)
        self.min3 = min3
        pass

    def __del__(self):
        pass

    def transaction_build(self, addr, data=None, write=1):
        cmd_byte = b'\00' if write else b'\x10'
        addr_bytes = struct.pack('!i', addr)[1:4]
        if not data:
            data = 0
        if data < 0:
            data_bytes = struct.pack('!i', data)
        else:
            data_bytes = struct.pack('!I', data)
        return cmd_byte + addr_bytes + data_bytes

    def packet_build(self,
                     adwlist=None,
                     adlist=None,
                     alist=None,
                     write=1,
                     dlist=None,
                     rand=True):
        inputvalid = False
        p = ''
        if alist:
            if write:
                if dlist:
                    if len(dlist) == len(alist):
                        wlist = len(alist) * [write]
                        inputvalid = True
                        pass
                    else:
                        print('alist and dlist length do not match')
                else:
                    print('write need dlist if use separated alist and dlist')
            else:
                dlist = len(alist) * [None]
                wlist = len(alist) * [write]
                inputvalid = True
        elif adlist:
            alist = [adlist[i][0] for i in range(len(adlist))]
            dlist = [adlist[i][1] for i in range(len(adlist))]
            wlist = len(adlist) * [write]
            inputvalid = True
        elif adwlist:
            #		print adwlist
            alist = [adwlist[i][0] for i in range(len(adwlist))]
            dlist = [adwlist[i][1] for i in range(len(adwlist))]
            wlist = [adwlist[i][2] for i in range(len(adwlist))]
            inputvalid = True
        else:
            print('provide adwlist [(a,d,w),(a,d,w)] or adlist [(a,d),(a,d),(a,d)] or alist [a,a,a] and dlist[d,d,d]')
        if inputvalid:
            word1 = random.getrandbits(32) if rand else 0xdeadbeef
            word2 = random.getrandbits(32) if rand else 0xfacefeed
            p = struct.pack('!I', word1)
            p += struct.pack('!I', word2)
            if self.min3:
                if len(alist) == 1:
                    alist = 3 * alist
                    dlist = 3 * dlist
                    wlist = 3 * wlist
                elif len(alist) == 2:
                    alist.append(alist[1])
                    dlist.append(dlist[1])
                    wlist.append(wlist[1])

            for ix in range(len(alist)):
                p += self.transaction_build(
                    addr=alist[ix], data=dlist[ix], write=wlist[ix])
        return p

    def readwrite(self,
                  adwlist=None,
                  write=None,
                  adlist=None,
                  alist=None,
                  dlist=None,
                  rand=True):
        p = self.packet_build(
            adwlist=adwlist,
            adlist=adlist,
            alist=alist,
            write=write,
            rand=rand,
            dlist=dlist)
        #print p.encode('hex')
        self.socket.send(p)
        readvalue, addr = self.socket.recvfrom(
            1450)  # buffer size is 1024 bytes
        if (readvalue[0:8] != p[0:8]):
            print(("header mismatch read: %s send: %s" % (
                    readvalue[0:8].encode('hex'), p[0:8].encode('hex'))))
        return readvalue

    def parse_readvalue(self, readvalue):
        lastn = int(len(readvalue) / 8) * 8
        readvalue = readvalue[
            8:
            lastn]  # some mem_gateway are buggy, need to trim off the last byte
        result = []
        while len(readvalue) > 7:
            cmd = readvalue[0]
            addr = readvalue[1:4]
            value = readvalue[4:8]
            result.append((cmd, addr, value))
            #print cmd.encode('hex'),addr.encode('hex'),value.encode('hex'),value
            readvalue = readvalue[8:]
        return result


#		print result

if __name__ == "__main__":
    opts, args = getopt.getopt(
        sys.argv[1:], 'ha:p:A:D:W:',
        ['help', 'addr=', 'port=', 'Addr=', 'Data=', 'Write='])
    ip_addr = '192.168.21.12'
    port = 50006
    Addr = 0
    Data = 0
    Write = 0
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg
        elif opt in ('-p', '--port'):
            port = int(arg)
        elif opt in ('-A', '--Addr'):
            Addr = eval(arg)
        elif opt in ('-D', '--Data'):
            Data = eval(arg)
        elif opt in ('-W', '--Write'):
            Write = eval(arg)
    min3 = port == 3000
    mg = c_mem_gateway(ip_addr, port, min3=min3)
    adw = [(Addr, Data, Write)]
    print(adw)
    result = mg.readwrite(adwlist=adw, rand=False)
    print((mg.parse_readvalue(result)[0][2].encode('hex')))

#	mg=c_mem_gateway(IP_ADDR,3000,min3=True)
#	a=eval(sys.argv[1])
#	d=eval(sys.argv[2])
#	w=eval(sys.argv[3])
#	IP_ADDR = '192.168.21.76'
#	adw=[(0,0,0),(0,0,0)]
#	alladwdata=[(5,0x0102,1)
#			,(5,0x80,1)
#			,(5,0x2,1)
#			,(5,0x192,1)
#			,(5,0x0,1)
#			,(5,0x100,1)
#			,(6,0,0)
#			]
'''
	result=mg.readwrite(alist=[6],dlist=[0x80008003],write=1)
	mg.parse_readvalue(result)
	result=mg.readwrite(alist=[0,1,2,3,4,5,6],write=0)
	mg.parse_readvalue(result)
	result=mg.readwrite(adlist=[(6,0x80008003)],write=1)
	mg.parse_readvalue(result)
	result=mg.readwrite(adwlist=[(6,0x80008003,1),(6,0x80008001,0)],write=1)
	mg.parse_readvalue(result)
'''
