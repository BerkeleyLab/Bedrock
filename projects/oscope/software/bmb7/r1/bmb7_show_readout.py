def conv_n(x, n):
    if x > (2**(n - 1) - 1):
        x = x - 2**n
    return x


def format_ltc2990(adr,
                   regs1,
                   regs2,
                   id_a,
                   id_b,
                   shunt1,
                   shunt2,
                   kv1=1.0,
                   kv2=1.0):
    ss = '\n' + 'LTC2990 {}:\n'.format(adr)
    tmp = float(regs1[3] & 0x1FFF) * 0.0625 - 273.2
    ss += 'TEMPERATURE:  {:.2f} C\n'.format(tmp)
    vcc = 2.5 + float(regs1[2] & 0x3FFF) * 0.00030518
    ss += 'VCC  {:.4f} V\n'.format(vcc)
    v1 = float(conv_n(regs1[1] & 0x7FFF, 15)) * 0.00030518 * kv1
    i1 = float(conv_n(regs2[1] & 0x7FFF, 15)) * (0.00001942 * kv1 / shunt1)
    ss += id_a + '  {:.4f} V  {:.4f} A\n'.format(v1, i1)
    if id_b is not None:
        if shunt2 is None:
            tmp2 = float(regs1[0] & 0x1FFF) * 0.0625 - 273.2
            ss += id_b + ' {:.2f} C\n'.format(tmp2)
        else:
            v2 = float(conv_n(regs1[0] & 0x7FFF, 15)) * 0.00030518 * kv2
            i2 = float(conv_n(regs2[0] & 0x7FFF, 15)) * (0.00001942 * kv2 /
                                                         shunt2)
            ss += id_b + '  {:.4f} V  {:.4f} A\n'.format(v2, i2)
    return ss


def format_monitor_bytes(read_bytes):

    read_u = [(msb << 8) + lsb
              for msb, lsb in zip(read_bytes[2::2], read_bytes[1::2])]

    reg1 = int(138 / 2)
    reg2 = int(58 / 2)

    ss = format_ltc2990('A0', read_u[reg1 - 4:reg1], read_u[reg2 - 2:reg2],
                        'TOP FMC +3.3V', 'TOP FMC VADJ', 0.02, 0.02)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990('A1', read_u[reg1 - 4:reg1], read_u[reg2 - 2:reg2],
                         'MAIN +3.3V', 'STANDBY +3.3V', 0.01, 0.02)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990(
        'A2',
        read_u[reg1 - 4:reg1],
        read_u[reg2 - 2:reg2],
        'TOP FMC +12V:',
        None,
        0.02,
        0.02,
        kv1=137.4 / 37.4)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990(
        'B0',
        read_u[reg1 - 4:reg1],
        read_u[reg2 - 2:reg2],
        'BOTTOM FMC +VIO_B',
        'BOTTOM FMC +12V',
        0.02,
        0.02,
        kv2=137.4 / 37.4)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990('B1', read_u[reg1 - 4:reg1], read_u[reg2 - 2:reg2],
                         'BOOT +3.3V', 'SPARTAN-6 +1.2V', 0.02, 0.02)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990('B2', read_u[reg1 - 4:reg1], read_u[reg2 - 2:reg2],
                         'BOTTOM FMC +3.3V', 'BOTTOM FMC +VADJ', 0.02, 0.02)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990('C0', read_u[reg1 - 4:reg1], read_u[reg2 - 2:reg2],
                         'SPARTAN-6 GTP +1.2V', 'KINTEX-7 GTX +1.2V', 0.02,
                         0.02)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990('C1', read_u[reg1 - 4:reg1], read_u[reg2 - 2:reg2],
                         'STANDBY +1.2V', 'KINTEX-7 GTX +1.0V', 0.02, 0.02)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990('C2', read_u[reg1 - 4:reg1], read_u[reg2 - 2:reg2],
                         'KINTEX-7 VCCINT +1.0V', 'KINTEX-7 TEMPERATURE',
                         0.0005, None)
    reg1 -= 4
    reg2 -= 2

    ss += format_ltc2990(
        'C3',
        read_u[reg1 - 4:reg1],
        read_u[reg2 - 2:reg2],
        'KINTEX-7 +1.8V',
        '+12V',
        0.02,
        0.02,
        kv2=137.4 / 37.4)
    reg1 -= 4
    reg2 -= 2
    return ss


def print_monitor_bytes(read_bytes):
    print(format_monitor_bytes(read_bytes).rstrip())


if __name__ == "__main__":
    read_bytes = bytearray([
        1, 1, 3, 1, 2, 1, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 62, 132, 191,
        129, 34, 152, 38, 128, 222, 131, 175, 133, 149, 131, 236, 128, 148,
        128, 63, 128, 2, 129, 103, 131, 70, 128, 254, 255, 31, 128, 159, 128,
        184, 128, 178, 129, 47, 128, 2, 128, 37, 17, 210, 22, 11, 138, 40, 148,
        92, 21, 182, 12, 134, 138, 1, 148, 141, 12, 225, 14, 17, 138, 43, 148,
        115, 14, 202, 14, 13, 138, 41, 148, 204, 22, 25, 42, 136, 138, 179,
        147, 45, 15, 13, 42, 11, 138, 164, 147, 16, 17, 7, 0, 139, 138, 191,
        147, 134, 4, 7, 17, 138, 138, 154, 147, 19, 42, 141, 42, 20, 138, 135,
        147, 63, 31, 37, 42, 137, 138, 160, 147, 230, 42, 16, 87, 0, 0, 0, 0,
        217, 46, 70, 87, 0, 0, 0, 0, 138, 208, 104, 102, 176, 134, 106, 106,
        114, 171, 188, 210, 181, 220, 245, 251, 227, 28, 76, 132, 37, 221, 153,
        127, 30, 118, 124, 203, 211, 84, 176, 130
    ])
    print_monitor_bytes(read_bytes)
