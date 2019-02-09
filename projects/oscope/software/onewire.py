import struct


def onewire_crc(data):
    crc = 0
    for d in reversed(data):
        for j in range(8):
            if (crc & 1) ^ (d & 1):
                crc ^= 0x118
            crc = crc >> 1
            d = d >> 1
    return crc


def string_dallas_temperature(scratch, ds2438=True):
    if onewire_crc(scratch) == 0:
        if ds2438:  # DS2438
            tempu = (scratch[6] << 8) + scratch[7]
            if tempu & 0x8000:
                tempu |= ~0xff  # sign-extend
            temp = tempu * 0.00390625
            voltu = (scratch[4] << 8) + scratch[5]
            volt = voltu * 0.01
            return "Temperature %.2f C  Voltage %.2f V" % (temp, volt)
        else:  # DS1822 or MAX31826
            tempu = (scratch[7] << 8) + scratch[8]
            if tempu & 0x8000:
                tempu |= ~0xff  # sign-extend
            temp = tempu * 0.0625
            return "Temperature %.2f C" % temp
    else:
        return "Temperature CRC failed"


def print_dallas_temperature(scratch):
    print(string_dallas_temperature(scratch))


# data is 64-byte dump of the dpram from ds1822_driver.v
def onewire_string(data, ds2438=True):
    data = list(reversed(data))  # confusing
    # print(list(data))
    if ds2438:
        dallas_id = data[31:39]
    else:
        dallas_id = data[4:12]  # DS1822 or MAX31826, unchecked
    if any(v & 0x100 for v in data):
        return "1-Wire readout process squelched"
    if all(v == 0 for v in dallas_id):
        return "1-Wire bus has no pull-up"
    if all(v == 0xff for v in dallas_id):
        return "No devices on 1-Wire bus"
    if onewire_crc(dallas_id) == 0:
        # Don't print family code or checksum
        ss = "1-Wire Serial #: " + "".join(
            ["%2.2x" % d for d in dallas_id[1:7]])
        ss += "  " + string_dallas_temperature(data[44:53])
        return ss
    else:
        return "1-Wire CRC failed"


def onewire_print(desc, data, ds2438=True):
    print(desc + " " + onewire_string(data, ds2438=ds2438))


def onewire_data(prc, addr):
    foo = prc.reg_read_alist(range(addr, addr + 64))
    return [struct.unpack('!I', x[2])[0] for x in foo]


def onewire_status(prc, addr, desc):
    # print "1-Wire at 0x%x"%addr, " ".join(["%2.2x"%u for u in uuu])
    onewire_print(desc, onewire_data(prc, addr))


if __name__ == "__main__":
    # data = [255, 0, 253, 204, 190, 209, 1, 255, 255, 240, 255, 255, 255, 121, 255, 255, 255, 0, 253, 51, 59, 109, 84, 22, 0, 0, 0, 144, 0, 253, 204, 68]  # old DS1822
    # data = [255, 0, 253, 204, 190, 209, 1, 255, 255, 240, 255, 255, 255,
    # 121, 255, 255, 255, 0, 253, 51, 59, 109, 84, 22, 0, 0, 0, 144, 0, 253,
    # 204, 68, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    # 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255,
    # 255, 255, 255, 255, 255, 255]  # wrong DS1822
    data = [
        255, 0, 253, 204, 184, 0, 0, 253, 204, 190, 0, 15, 208, 23, 73, 1, 255,
        255, 0, 73, 255, 255, 0, 253, 51, 38, 110, 75, 61, 2, 0, 0, 178, 0,
        253, 204, 68, 0, 253, 204, 180, 0, 0, 0, 0, 0, 0, 0, 0, 254, 255, 255,
        255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255
    ]  # DS2438
    onewire_print("Replay", data, ds2438=True)
    ss = onewire_string(data, ds2438=True)
    # want = "1-Wire Serial #: 00000016546d    Temperature 29.06 C"
    want = "1-Wire Serial #: 0000023d4b6e  Temperature 23.81 C  Voltage 3.29 V"
    if (ss == want):
        print("PASS")
    else:
        print("FAIL")
        exit(2)
