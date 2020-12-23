#!/usr/bin/env python3
'''
Get DJB2 hash for a file.

usage: python3 bin_hash.py file.bin [1024]
where 1024 is the number of 32 bit words to process
'''
from sys import argv


class DJB2:
    def __init__(self, initVal=5381):
        self._state = initVal

    def hash(self, val):
        x = (self._state << 5) & 0xFFFFFFFF
        x = (x + self._state) & 0xFFFFFFFF
        self._state = x ^ (val & 0xFFFFFFFF)
        return self._state


if __name__ == '__main__':
    if len(argv) not in (2, 3):
        print(__doc__)
        exit(-1)

    h = DJB2()
    with open(argv[1], 'rb') as f:
        i = 0
        while True:
            if len(argv) >= 3 and i >= int(argv[2]):
                break
            bs = f.read(4)
            if len(bs) <= 0:
                break
            v = int.from_bytes(bs, 'little')
            h.hash(v)
            i += 1

    print('words: {:d}, h: {:08X}'.format(i, h._state))
