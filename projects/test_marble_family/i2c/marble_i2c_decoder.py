#! /usr/bin/python3

# Marble-specific wrapper around i2cbridge/decode.py

import sys
_decode_path = "../../../peripheral_drivers/i2cbridge"

try:
    import decode as _decode
except ImportError:
    try:
        from i2cbridge import decode as _decode
    except ImportError:
        try:
            sys.path.append(_decode_path)
            import decode as _decode
        except ImportError:
            print("Cannot import module 'decode'. Set PYTHONPATH to bedrock/peripheral_drivers/i2cbridge")
            sys.exit(1)

_int = _decode._int

import marble_i2c

# Bus select is done by writing bitmask to U5 (TCA9548) (I2C address 0xE0)
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
bus_mux = marble.get_mux_dict()

bus_bitmask = 0


def _selected(bitmask=0):
    """Return string of selected busses in bitmask"""
    # Store this for later
    global bus_bitmask
    bus_bitmask = bitmask
    _l = []
    for ch, branch in bus_mux.items():
        name = branch[0]
        if (1 << ch) & bitmask:
            _l.append(name)
    return ', '.join(_l)


def marble_write(devaddr, nbytes, cmd_table):
    # Catch the special case of a bus mux write
    msg = None
    inc = 0
    for muxname, address in marble.get_muxes():
        if devaddr == address:
            bitmask = _int(next(cmd_table))
            seltext = _selected(bitmask)
            inc += 1
            msg = f"Busmux - bitmask: 0b{bitmask:08b} Selected {seltext}"
    if msg is None:
        data = []
        for _l in marble._a:
            ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = _l
            if devaddr == ic_addr and ((1 << ch) & bus_bitmask):
                for n in range(nbytes):
                    data.append(_int(next(cmd_table)))
                    inc += 1
                msg = "Write to {} - data: {}".format(ic_name, [hex(m) for m in data])
    return msg, inc


def marble_read(devaddr, nbytes, cmd_table):
    msg = None
    inc = 0
    devaddr = devaddr & 0xfe  # Mask out the read/write bit
    for muxname, address in marble.get_muxes():
        if devaddr == address:
            msg = "Busmux - Readback"
    for _l in marble._a:
        ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = _l
        if devaddr == ic_addr and ((1 << ch) & bus_bitmask):
            s = "" if nbytes == 1 else "s"
            msg = "Read {} byte{} from {}".format(nbytes, s, ic_name)
    return msg, inc


def marble_write_rpt(devaddr, memaddr, nbytes, cmd_table):
    data = []
    msg = None
    inc = 0
    for _l in marble._a:
        ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = _l
        if devaddr == ic_addr and ((1 << ch) & bus_bitmask):
            if nbytes == 0:
                msg = "Read from {} offset 0x{:x} - START".format(ic_name, memaddr)
            else:
                for n in range(nbytes):
                    data.append(_int(next(cmd_table)))
                    inc += 1
                msg = "Write to {} offset 0x{:x} - data: {}".format(ic_name, memaddr, [hex(m) for m in data])
    return msg, inc


# ====================== Override Generic Platform Hooks ======================
_decode.platform_write = marble_write
_decode.platform_read = marble_read
_decode.platform_write_rpt = marble_write_rpt
# =============================================================================

# Expose the (now platform-specific) 'decode' function in the 'decode' module
decode = _decode.decode

if __name__ == "__main__":
    import sys
    _decode.decode_file(sys.argv)
