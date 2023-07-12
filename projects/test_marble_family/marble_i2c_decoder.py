#! /usr/bin/python3

# Marble-specific wrapper around i2cbridge/decode.py

import sys
try:
    from i2cbridge import decode
except:
    try:
        import decode
    except:
        print("Cannot import module 'decode'. Set PYTHONPATH to bedrock/peripheral_drivers/i2cbridge")
        sys.exit(1)

import marble_i2c

# Bus select is done by writing bitmask to U5 (TCA9548) (I2C address 0xE0)
BUSMUX_ADDRESS = 0xe0
TCA9548_bus = {
    0: "FMC1",
    1: "FMC2",
    2: "CLK",
    3: "SO-DIM",
    4: "QSFP1",
    5: "QSFP2",
    6: "APP",
}

marble = marble_i2c.MarbleI2C()

bus_bitmask = 0

def _selected(bitmask=0):
    """Return string of selected buses in bitmask"""
    # Store this for later
    global bus_bitmask
    bus_bitmask = bitmask
    l = []
    for ch, name in TCA9548_bus.items():
        if (1<<ch) & bitmask:
            l.append(name)
    return ', '.join(l)

def marble_write(devaddr, nbytes, cmd_table):
    # Catch the special case of a bus mux write
    busmuxes = marble.get_muxes()
    msg = None
    inc = 0
    for muxname, address in busmuxes:
        if devaddr == address:
            bitmask = int(next(cmd_table), 16)
            seltext = _selected(bitmask)
            inc += 1
            msg = f"Busmux - bitmask: 0b{bitmask:08b} Selected {seltext}"
    if msg is None:
        data = []
        for l in marble._a:
            ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = l
            if devaddr == ic_addr and ((1<<ch) & bus_bitmask):
                for n in range(nbytes):
                    data.append(int(next(cmd_table), 16))
                    inc += 1
                msg = "Write to {} - data: {}".format(ic_name, [hex(m) for m in data])
    return msg, inc

def marble_read(devaddr, nbytes, cmd_table):
    data = []
    msg = None
    inc = 0
    devaddr = devaddr & 0xfe # Mask out the read/write bit
    for l in marble._a:
        ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = l
        if devaddr == ic_addr and ((1<<ch) & bus_bitmask):
            s = "" if nbytes == 1 else "s"
            msg = "Read {} byte{} from {}".format(nbytes, s, ic_name)
    return msg, inc

def marble_write_rpt(devaddr, memaddr, nbytes, cmd_table):
    data = []
    msg = None
    inc = 0
    for l in marble._a:
        ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = l
        if devaddr == ic_addr and ((1<<ch) & bus_bitmask):
            if nbytes == 0:
                msg = "Read from {} offset 0x{:x} - START".format(ic_name, memaddr)
            else:
                for n in range(nbytes):
                    data.append(int(next(cmd_table), 16))
                    inc += 1
                msg = "Write to {} offset 0x{:x} - data: {}".format(ic_name, memaddr, [hex(m) for m in data])
    return msg, inc

# ====================== Override Generic Platform Hooks ======================
decode.platform_write = marble_write
decode.platform_read = marble_read
decode.platform_write_rpt = marble_write_rpt
# =============================================================================

if __name__ == "__main__":
    import sys
    decode.decode(sys.argv)
