import time


class c_amc7823:
    def __init__(self):
        self.init()

    def init(self):
        pass

    def cmd(self, rw=1, pg=1, saddr=0x1e, eaddr=0x1e):
        return (rw << 15) + (pg << 12) + (saddr << 6) + eaddr

    def dataaddr(self, data, addr):
        res = (data << 16) + addr
        # print hex(res),
        return res

    def cmddecode(self, cmdval):
        rw = cmdval >> 15
        pg = (cmdval >> 12) & 0x3
        saddr = (cmdval >> 6) & 0x1f
        eaddr = cmdval & 0x1f
        return [rw, pg, saddr, eaddr]


if __name__ == "__main__":
    from prc import c_prc

    IP_ADDR = "192.168.1.121"
    prc = c_prc(IP_ADDR, 50006)
    # #addr=0x0a
    # #def prc.amc_write(pg,saddr,val):
    # #	#:w
    # #	print 'amc write pg',pg, 'saddr',hex(saddr), 'val',hex(val)
    # #	prc.reg_write([{"U15_spi_data_r,U15_spi_addr_r":dataaddr(val,cmd(rw=0,pg=pg,saddr=saddr,eaddr=0x00))}
    # #		,{"U15_spi_read_r,U15_spi_start_r":2}
    # #		,{"U15_spi_read_r,U15_spi_start_r":3}
    # #		])
    # #	#print 'after write',
    # #	prc.reg_read_value(["U15_sdo_addr, U15_spi_rdbk"])
    # #	time.sleep(0.2)
    # #def prc.amc_read(pg,saddr):
    # #	prc.reg_write([{"U15_spi_data_r,U15_spi_addr_r":dataaddr(0xaaa,cmd(rw=1,pg=pg,saddr=saddr,eaddr=0x00))}
    # #		,{"U15_spi_read_r,U15_spi_start_r":0}
    # #		,{"U15_spi_read_r,U15_spi_start_r":3}
    # #		])
    # #	time.sleep(0.2)
    # #	result=prc.reg_read_value(["U15_sdo_addr, U15_spi_rdbk"])[0]
    # #	[rw,pg,saddr,eaddr]=cmddecode(result>>16);
    # #	data=result&0xffff;
    # #	return [rw,pg,saddr,eaddr,data]
    # #	print val.encode('hex')#,"U15_spi_ready,U15_sdio_as_sdo","U15_spi_start,U15_spi_read_r",
    #                            "U15_spi_data_r,U15_spi_addr_r"])
    # #addr=eval(sys.argv[2])
    # #pg=eval(sys.argv[1])
    if 0:
        print([format(i, '04x') for i in prc.amc_read(1, 0xa)])
        prc.amc_write(1, 0xa, 0)
        print([format(i, '04x') for i in prc.amc_read(1, 0xa)])
        prc.amc_write(1, 0xc, 0xbb30)
        print([format(i, '04x') for i in prc.amc_read(0, 0x0a)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x08)])
        print([format(i, '04x') for i in prc.amc_read(1, 0x1e)])
        print([format(i, '04x') for i in prc.amc_read(1, 0x0b)])
        print('check 1 a status')
        print([format(i, '04x') for i in prc.amc_read(1, 0xa)])
        prc.amc_write(1, 0xa, 0)
        prc.amc_write(1, 0x0b, 0x8080)
        time.sleep(0.5)
        print([format(i, '04x') for i in prc.amc_read(1, 0xa)])
        print([format(i, '04x') for i in prc.amc_read(1, 0x0b)])
        print([format(i, '04x') for i in prc.amc_read(1, 0x0a)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x00)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x00)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x01)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x02)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x03)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x04)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x05)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x06)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x07)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x08)])
        print([format(i, '04x') for i in prc.amc_read(0, 0x00)])
        prc.amc_write(1, 0x0b, 0x0040)
        time.sleep(0.1)
    # prc.amc_write(1,0xc,0xbb30)
    # prc.amc_write(1,0xb,0x8080)
    # prc.amc_write(1,0xd,0xffff)
    addrs = list(range(0x16))
    addrs.append(0x1e)
    if 1:
        for addr in range(11):
            adcs = prc.amc_read(0, addr)
            print(([format(i, '04x') for i in adcs], '%6.3f' % (
                (adcs[4] & 0xfff) * 2.5 / 2**12)))
        for addr in addrs:
            print([format(i, '04x') for i in prc.amc_read(1, addr)])
        for addr in range(8):
            prc.amc_write(1, addr, addr << 8)
        prc.amc_write(1, 0x09, 0xbb00)
    if 0:
        prc.amc_write(1, 0xb, 0x8440)
        for i in range(100):
            print(((prc.amc_read(0, 4)[4] & 0xfff) * 2.5 / 2**12 - 1.7))
    for i in range(0):
        prc.amc_write(0, 0x0a, 0xffff)
        rb = prc.amc_read(0, 0x0a)
        print((rb, hex(rb[4])))
        time.sleep(1)
        prc.amc_write(0, 0x0a, 0xffc0)
        rb = prc.amc_read(0, 0x0a)
        print((rb, hex(rb[4])))
        time.sleep(1)

    prc.amc_write(1, 0xd, 0xffdf)
