import logging

import sys
import unittest
import json
import zlib
from types import ModuleType

import numpy as np
from numpy.testing import assert_equal

from ..base import open

_log = logging.getLogger(__name__)

# hijack cothread
assert 'cothread' not in sys.modules

CM = ModuleType('cothread')
sys.modules['cothread'] = CM

CM.Event = object

CA = ModuleType('cothread.catools')
sys.modules['cothread.catools'] = CA

_PVs = {}

CA.FORMAT_TIME = 1
CA.DBR_CHAR_STR = 2


def caget(name, timeout=None):
    return _PVs[name]


CA.caget = caget
del caget


def caput(name, value, wait=False, timeout=None):
    assert name in _PVs, name
    _PVs[name] = value


CA.caput = caput
del caput

CA.camonitor = lambda X, Y, Z: object()

del CM
del CA


class TestCA(unittest.TestCase):
    jinfo = {
        'records': {
            'sval': {'input': 'TST:reg_sval_RBV', 'output': 'TST:reg_sval'},
            'uval': {'input': 'TST:reg_uval_RBV', 'output': 'TST:reg_uval'},
            'sarr': {'input': 'TST:reg_sarr_RBV', 'output': 'TST:reg_sarr'},
            'uarr': {'input': 'TST:reg_uarr_RBV', 'output': 'TST:reg_uarr'},
        },
    }
    regmap = {
        'sval': {
            'access': 'rw',
            'addr_width': 0,
            'sign': 'signed',
            'base_addr': 42,
            'data_width': 32,
        },
        'uval': {
            'access': 'rw',
            'addr_width': 0,
            'sign': 'unsigned',
            'base_addr': 43,
            'data_width': 32,
        },
        'sarr': {
            'access': 'rw',
            'addr_width': 1,
            'sign': 'signed',
            'base_addr': 100,
            'data_width': 32,
        },
        'uarr': {
            'access': 'rw',
            'addr_width': 1,
            'sign': 'unsigned',
            'base_addr': 102,
            'data_width': 32,
        },
    }

    def setUp(self):
        _PVs.clear()

        _PVs['TST:CTRL_JINFO'] = zlib.compress(
            json.dumps(self.jinfo).encode('utf-8'), 9)
        _PVs['TST:CTRL_JSON'] = zlib.compress(
            json.dumps(self.regmap).encode('utf-8'), 9)
        _PVs['TST:reg_sval_RBV.PROC'] = 0
        _PVs['TST:reg_uval_RBV.PROC'] = 0
        _PVs['TST:reg_sarr_RBV.PROC'] = 0
        _PVs['TST:reg_uarr_RBV.PROC'] = 0

    def tearDown(self):
        _PVs.clear()

    def test_scalar(self):
        with open('ca://TST:') as dev:
            _PVs['TST:reg_sval_RBV'] = 0x12345678
            _PVs['TST:reg_uval_RBV'] = 0x12345678
            self.assertEqual(dev.reg_read(['sval', 'uval']),
                             [0x12345678, 0x12345678])

            _PVs['TST:reg_sval_RBV'] = -559038737
            _PVs['TST:reg_uval_RBV'] = -559038737
            self.assertEqual(dev.reg_read(['sval', 'uval']),
                             [-559038737, 0xdeadbeef])

            _PVs['TST:reg_sval'] = _PVs['TST:reg_uval'] = 0

            dev.reg_write([('sval', 0x12345678),
                           ('uval', 0x12345678)])
            self.assertEqual(_PVs['TST:reg_sval'], 0x12345678)
            self.assertEqual(_PVs['TST:reg_uval'], 0x12345678)

            _PVs['TST:reg_sval'] = _PVs['TST:reg_uval'] = 0

            dev.reg_write([('sval', 0xdeadbeef),
                           ('uval', 0xdeadbeef)])
            self.assertEqual(_PVs['TST:reg_sval'], -559038737)
            self.assertEqual(_PVs['TST:reg_uval'], -559038737)

            _PVs['TST:reg_sval'] = _PVs['TST:reg_uval'] = 0

            dev.reg_write([('sval', -559038737),
                           ('uval', -559038737)])
            self.assertEqual(_PVs['TST:reg_sval'], -559038737)
            self.assertEqual(_PVs['TST:reg_uval'], -559038737)

    def test_array(self):
        with open('ca://TST:') as dev:
            _PVs['TST:reg_sarr_RBV'] = _PVs['TST:reg_uarr_RBV'] = np.asarray(
                [0x12345678, -559038737], dtype='i')

            assert_equal(dev.reg_read(['uarr'])[0], [0x12345678, 0xdeadbeef])

            assert_equal(dev.reg_read(['sarr'])[0], [0x12345678, -559038737])

            _PVs['TST:reg_sarr'] = _PVs['TST:reg_uarr'] = 0

            dev.reg_write([('uarr', [0x12345679, 0xdeadbeef]),
                           ('sarr', [0x12345679, 0xdeadbeef])])

            assert_equal(_PVs['TST:reg_sarr'], [0x12345679, -559038737])
            assert_equal(_PVs['TST:reg_uarr'], [0x12345679, -559038737])

            _PVs['TST:reg_sarr'] = _PVs['TST:reg_uarr'] = 0

            dev.reg_write([('uarr', [0x12345679, -559038737]),
                           ('sarr', [0x12345679, -559038737])])

            assert_equal(_PVs['TST:reg_sarr'], [0x12345679, -559038737])
            assert_equal(_PVs['TST:reg_uarr'], [0x12345679, -559038737])
