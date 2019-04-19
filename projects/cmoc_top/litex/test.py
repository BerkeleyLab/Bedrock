import sys

from litex.soc.tools.remote.comm_udp import CommUDP


ip = '192.168.1.50'
base_addr = 0xb0080000
base_addr = 0x40000

SIM = True if len(sys.argv) > 1 and sys.argv[1] == 'sim' else False

if SIM:
    ip = '192.168.1.51'
if len(sys.argv) == 3:
    inp = sys.argv[2]
    if inp.startswith('0x'):
        base_addr = int(inp, 16)
    else:
        base_addr = int(inp)

c = CommUDP(server=ip)
c.open()


if not SIM:
    XADC_BASE=0xe0009800
    temperature = 0
    temperature = (c.read(XADC_BASE) & 255) << 8 | (c.read(XADC_BASE+4) & 255)
    print(temperature, temperature * 503.975 / 4096 - 273.15)

for i in range(25):
    # c.write(i+base_addr, i)
    x = c.read(i+base_addr)
    print(hex(x), hex(base_addr+i))
c.close()

print(base_addr, hex(base_addr))
