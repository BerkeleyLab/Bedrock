
import logging

import unittest
import json
import zlib
import threading
import socket

import numpy as np
from numpy.testing import assert_equal

from ..base import open

_log = logging.getLogger(__name__)

class SimServer(object):
    regmap = {
        'sval':{
            'access':'rw',
            'addr_width':0,
            'sign':'signed',
            'base_addr':42,
            'data_width':32,
        },
        'uval':{
            'access':'rw',
            'addr_width':0,
            'sign':'unsigned',
            'base_addr':43,
            'data_width':32,
        },
        'sarr':{
            'access':'rw',
            'addr_width':1,
            'sign':'signed',
            'base_addr':100,
            'data_width':32,
        },
        'uarr':{
            'access':'rw',
            'addr_width':1,
            'sign':'unsigned',
            'base_addr':102,
            'data_width':32,
        },
    }

    def __init__(self):
        self.S = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.S.bind(('127.0.0.1', 0))
        self.url = 'leep://%s:%d'%self.S.getsockname()
        _log.info('SimServer %s starting', self.url)

        blob = zlib.compress(json.dumps(self.regmap).encode('utf-8'), 9)
        if len(blob)&1:
            blob = blob + b'\0'
        RM = np.frombuffer(blob, '>H')
        assert len(RM)<=0x3fff
        rom = np.zeros(1+len(RM), dtype='>I') # high half-word not used
        rom[0] = 0xc000 | len(RM)
        rom[1:] = RM

        self.data = dict([(0x800+i, val) for i,val in enumerate(rom)])

        self.running = True
        self.T = threading.Thread(target=self.run)
        self.T.start()
        print('start')

    def join(self):
        print('join')
        _log.info('SimServer %s joining', self.url)
        self.running = False
        try:
            self.S.shutdown(socket.SHUT_RDWR)
        except socket.error:
            pass
        self.S.close()
        self.T.join(1.0)
        assert not self.T.isAlive(), self.T
        _log.info('SimServer %s joined', self.url)

    def run(self):
        print('run')
        while self.running:
            buf, src = self.S.recvfrom(2048)
            if not self.running:
                break
            _log.debug('Request from %s', src)

            buf = np.frombuffer(buf, dtype='>I')
            buf = buf.copy()

            for i in range(2, len(buf)&~1, 2):
                addr = buf[i]&0xffffff
                if buf[i]&0x10000000:
                    # read
                    buf[i+1] = self.data.get(addr,0)
                else:
                    # write
                    if buf[i+1]==0:
                        self.data.pop(addr)
                    else:
                        self.data[addr] = buf[i+1]

            _log.debug('Reply to %s', src)
            self.S.sendto(buf.tobytes(), src)
        print('ran')

class TestRaw(unittest.TestCase):
    def setUp(self):
        self.serv = SimServer()

    def tearDown(self):
        self.serv.join()

    def test_scalar(self):
        with open(self.serv.url) as dev:
            self.serv.data[42] = self.serv.data[43] = 0x12345678
            self.assertEqual(dev.reg_read(['sval', 'uval']),
                             [0x12345678, 0x12345678])

            self.serv.data[42] = self.serv.data[43] = 0xdeadbeef
            self.assertEqual(dev.reg_read(['sval', 'uval']),
                             [-559038737, 0xdeadbeef])

            self.serv.data[100] = 0x12345678
            self.serv.data[101] = 0xdeadbeef

            self.serv.data[42] = self.serv.data[43] = 0

            dev.reg_write([('sval', 0x12345678),
                           ('uval', 0x12345678)])

            self.assertEqual(self.serv.data[42], 0x12345678)
            self.assertEqual(self.serv.data[43], 0x12345678)

            self.serv.data[42] = self.serv.data[43] = 0

            dev.reg_write([('sval', 0xdeadbeef),
                           ('uval', 0xdeadbeef)])

            self.assertEqual(self.serv.data[42], 0xdeadbeef)
            self.assertEqual(self.serv.data[43], 0xdeadbeef)

            self.serv.data[42] = self.serv.data[43] = 0

            dev.reg_write([('sval', -559038737),
                           ('uval', -559038737)])

            self.assertEqual(self.serv.data[42], 0xdeadbeef)
            self.assertEqual(self.serv.data[43], 0xdeadbeef)


    def test_array(self):
        with open(self.serv.url) as dev:
            self.serv.data[100] = self.serv.data[102] = 0x12345678
            self.serv.data[101] = self.serv.data[103] = 0xdeadbeef

            assert_equal(dev.reg_read(['uarr'])[0],
                             [0x12345678, 0xdeadbeef])

            assert_equal(dev.reg_read(['sarr'])[0],
                             [0x12345678, -559038737])

            self.serv.data[100] = self.serv.data[102] = self.serv.data[101] = self.serv.data[103] = 0

            dev.reg_write([('uarr', [0x12345679, 0xdeadbeef]),
                           ('sarr', [0x12345679, 0xdeadbeef])])

            self.assertEqual(self.serv.data[100], 0x12345679)
            self.assertEqual(self.serv.data[101], 0xdeadbeef)
            self.assertEqual(self.serv.data[102], 0x12345679)
            self.assertEqual(self.serv.data[103], 0xdeadbeef)

            self.serv.data[100] = self.serv.data[102] = self.serv.data[101] = self.serv.data[103] = 0

            dev.reg_write([('uarr', [0x12345679, -559038737]),
                           ('sarr', [0x12345679, -559038737])])

            self.assertEqual(self.serv.data[100], 0x12345679)
            self.assertEqual(self.serv.data[101], 0xdeadbeef)
            self.assertEqual(self.serv.data[102], 0x12345679)
            self.assertEqual(self.serv.data[103], 0xdeadbeef)

