
import unittest

from ..base import DeviceBase


class DummyDevice(DeviceBase):
    def __init__(self, *args, **kws):
        DeviceBase.__init__(self, *args, **kws)
        self.regmap = {
            '__metadata__': {
                'tgen_granularity_log2': 0,
            },
            'XXX': {
                'base_addr': 0x10100,
                'addr_width': 4*4,  # 4 instructions
                'data_width': 16,
            },
            'test1': {
                'base_addr': 0x20200,
                'addr_width': 0,
                'data_width': 32,
            },
            'test2': {
                'base_addr': 0x30300,
                'addr_width': 1,
                'data_width': 32,
            },
        }


class TestTGEN(unittest.TestCase):
    def test_assemble(self):
        D = DummyDevice()
        prog = D.assemble_tgen([
            ('set', 'test1', 0x12345678),
            ('sleep', 0xabcd),
            ('set', 'test2[0]', 0x01020304),
            ('set', 'test2[1]', 0x05060708),
        ])

        prog, zeros = prog[:12], prog[12:]
        self.assertListEqual(zeros, [0]*len(zeros))
        self.assertListEqual(prog, [
            0xabcd, 0x20200, 0x1234, 0x5678,
            0x0000, 0x30300, 0x0102, 0x0304,
            0x0000, 0x30301, 0x0506, 0x0708,
        ])

    def test_long_sleep(self):
        D = DummyDevice()
        prog = D.assemble_tgen([
            ('set', 'test1', 0x12345678),
            ('sleep', 0x1abcd),
            ('set', 'test2[0]', 0x01020304),
            ('set', 'test2[1]', 0x05060708),
        ])

        prog, zeros = prog[:16], prog[16:]
        self.assertListEqual(zeros, [0]*len(zeros))
        self.assertListEqual(prog, [
            0xffff, 0x20200, 0x1234, 0x5678,
            0xabce, 0x20200, 0x1234, 0x5678,
            0x0000, 0x30300, 0x0102, 0x0304,
            0x0000, 0x30301, 0x0506, 0x0708,
        ])
