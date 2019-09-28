#!/usr/bin/env python
'''
Get DJB2 hash for a list of n prime numbers.
To verify the result of test.c/sieve()

usage: python3 get_hash.py 1024
where 1024 is the number of prime numbers `nPrimes`
'''
from sys import argv, exit
from sympy import nextprime


class DJB2:
    def __init__(self, initVal=5381):
        self._state = initVal

    def hash(self, val):
        x = (self._state << 5) & 0xFFFFFFFF
        x = (x + self._state) & 0xFFFFFFFF
        self._state = x ^ (val & 0xFFFFFFFF)
        return self._state


if len(argv) != 2:
    print(__doc__)
    exit(-1)

nPrimes = int(argv[1])
h = DJB2()
val = 0
for i in range(nPrimes):
    val = nextprime(val)
    # print(i + 1, val)
    h.hash(i + 1)
    h.hash(val)
print(hex(h._state))
