
from __future__ import print_function
import numpy
from .base import DeviceBase
from datetime import datetime
import json
import zlib
import random
import socket
import sys
from functools import reduce

import logging
_log = logging.getLogger(__name__)
# special logger for use in exchange()
_spam = logging.getLogger(__name__+'.packets')
_spam.propagate = False


if sys.version_info >= (3, 0):
    unicode = str

be32 = numpy.dtype('>u4')
be16 = numpy.dtype('>u2')


def yscale(wave_samp_per=1):
    # Note that changes to the output of this function
    # need to be reflected in testsub.cpp
    try:
        from math import ceil, log

        lo_cheat = (74762*1.646760258)/2**17

        shift_base = 4
        cic_period = 33
        cic_n = wave_samp_per * cic_period

        def log2(n):
            try:
                return log(n, 2)
            except ValueError as e:
                raise ValueError("log2(%s) %s" % (n, e))

        shift_min = log2(cic_n**2 * lo_cheat)-12

        wave_shift = max(0, ceil(shift_min/2))
        adc_fs = 16 * lo_cheat * (33 * wave_samp_per)**2 * \
            4**(8 - wave_shift)/512.0/(2**shift_base)

        return wave_shift, adc_fs
    except Exception as e:
        raise RuntimeError("yscale(%s) %s" % (wave_samp_per, e))


class LEEPDevice(DeviceBase):
    backend = 'leep'
    init_rom_addr = 0x800
    max_rom_addr = 0x4000
    # TO-DO: preamble is not really bounded. See build_rom.py dev_descript arg
    preamble_max_size = 50

    def __init__(self, addr, timeout=0.1, **kws):
        DeviceBase.__init__(self, **kws)
        host, _sep, port = addr.partition(':')
        self.dest = (host, int(port or '50006'))

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        self.sock.settimeout(timeout)

        self._readrom()

    def reg_write(self, ops, instance=[]):

        assert isinstance(ops, (list, tuple))

        addrs, values = [], []
        for name, value in ops:
            if instance is not None:
                name = self.expand_regname(name, instance=instance)
            info = self.get_reg_info(name, instance=None)
            L = 2**info.get('addr_width', 0)

            base_addr = info['base_addr']
            if isinstance(base_addr, (bytes, unicode)):
                base_addr = int(base_addr, 0)

            value = numpy.asarray(value, dtype='I')

            if L > 1:
                _log.debug('reg_write %s <- %s ...', name, value[:10])
                assert value.ndim == 1 and value.shape[0] == L, (
                    'must write whole register', value.shape, L)
                # array register
                for A, V in enumerate(value, base_addr):
                    addrs.append(A)
                    values.append(V)
            else:
                assert value.ndim == 0, 'scalar register'
                _log.debug('reg_write %s <- %s', name, value)
                addrs.append(base_addr)
                values.append(value)

        addrs = numpy.asarray(addrs)
        values = numpy.asarray(values)

        self.exchange(addrs, values)

    def reg_read(self, names, instance=[]):
        addrs = []
        lens = []
        for name in names:
            if instance is not None:
                name = self.expand_regname(name, instance=instance)
            info = self.get_reg_info(name, instance=None)
            L = 2**info.get('addr_width', 0)

            lens.append((info, L))
            base_addr = info['base_addr']
            if isinstance(base_addr, (bytes, str, unicode)):
                base_addr = int(base_addr, 0)
            addrs.extend(range(base_addr, base_addr+L))

        raw = self.exchange(addrs)

        ret = []
        for i, (info, L) in enumerate(lens):
            data, raw = raw[:L], raw[L:]
            assert len(data) == L, (len(data), L)
            if info.get('sign', 'unsigned') == 'signed':
                # sign extend
                # mask of data bits excluding sign bit
                mask = (2**(info['data_width']-1))-1
                # invert to give mask of sign bit and extension bits
                mask ^= 0xffffffff
                # test sign bit
                neg = (data & mask) != 0
                # extend only negative numbers
                data[neg] |= mask
                # cast to signed
                data = data.astype('i4')
            _log.debug('reg_read %s -> %s ...', names[i], data[:10])
            # unwrap scalar from ndarray
            if info.get('addr_width', 0) == 0:
                data = data[0]
            ret.append(data)

        return ret

    def set_decimate(self, dec, instance=[]):
        wave_shift, _Ymax = yscale(dec)
        assert dec >= 1 and dec <= 255
        self.reg_write([
            ('wave_samp_per', dec),
            ('wave_shift', wave_shift),
        ], instance=instance)

    def get_decimate(self, instance=[]):
        return self.reg_read(['wave_samp_per'],
                             instance=instance)

    def set_channel_mask(self, chans=[], instance=[]):
        """Enabled specified channels.
        """
        # list of channel numbers to mask
        if isinstance(chans, list):
            chans = reduce(lambda l, r: l | r, [2**(11-n) for n in chans], 0)
        self.reg_write([('chan_keep', chans)], instance=instance)

    def get_channel_mask(self, instance=[]):
        chans, =  self.reg_read(['chan_keep'], instance=instance)
        return chans

    def wait_for_acq(self, tag=False, toggle_tag=False, timeout=5.0, instance=[]):
        """Wait for next waveform acquisition to complete.
        If tag=True, then wait for the next acquisition which includes the
        side-effects of all preceding register writes
        """
        start = datetime.utcnow()

        T, = self.reg_read(['dsp_tag'], instance=instance)
        if tag or toggle_tag:
            T = (T+1) & 0xff
            self.reg_write([('dsp_tag', T)], instance=instance)
            _log.debug('Set Tag %d', T)

        inst = self.instance + instance
        # assume that the shell_#_ number is the first
        mask = 2**int(inst[0])

        while True:
            self.reg_write([('circle_buf_flip', mask)], instance=None)

            while True:
                now = datetime.utcnow()
                delta = now-start
                delta_us = delta.seconds + delta.microseconds/1e6
                if delta_us >= timeout:
                    raise RuntimeError('Timeout')

                # TODO: use exchange() and optimize to fetch slow_data[33] as well
                ready, = self.reg_read(['llrf_circle_ready'], instance=None)

                if ready & mask:
                    break

            slow, = self.reg_read(['slow_data'], instance=instance)
            tag_old = slow[34]
            tag_new = slow[33]
            dT = (tag_old - T) & 0xff
            tag_match = dT == 0 and tag_new == tag_old

            if not tag:
                break

            if tag_match:
                break  # all done, waveform reflects latest parameter changes

            if dT != 0xff:
                raise RuntimeError(
                    'acquisition collides with another client: %d %d %d' % (tag_old, tag_new, T))

            _log.debug('Acquire retry')

        # datetimestr = now.isoformat()+'Z'
        return tag_match, slow, now

    def get_channels(self, chans=[], instance=[]):
        """:returns: a list of :py:class:`numpy.ndarray` with the numbered channels.
        chans may be a bit mask or a list of channel numbers
        """
        interested = reduce(lambda l, r: l | r, [2**(11-n) for n in chans], 0)

        keep, data, dec = self.reg_read([
            'chan_keep',
            'circle_data',
            'wave_samp_per',
        ], instance=instance)

        wave_shift, Ymax = yscale(dec)
        # assume wave_shift has been set properly
        assert Ymax != 0, dec

        if (keep & interested) != interested:
            # chans must be a strict sub-set of keep
            raise RuntimeError(
                'Requested channels (%x) not kept (%x)' % (interested, keep))

        # count number of bits set
        nbits, M = 0, keep
        while M != 0:
            if M & 1:
                nbits += 1
            M >>= 1

        cdata, M = {}, 0
        for ch in range(12):
            cmask = 2**(11-ch)
            if not (keep & cmask):
                continue
            if interested & cmask:
                cdata[ch] = data[M::nbits]/Ymax

            M += 1

        # finally, ensure the results are in the same order as args
        return list([cdata[ch] for ch in chans])

    def get_timebase(self, chans=[], instance=[]):
        info = self.get_reg_info('circle_data', instance=instance)
        totalsamp = 2**info['addr_width']

        keep, dec = self.reg_read([
            'chan_keep',
            'wave_samp_per',
        ], instance=instance)

        period = 2*33*dec/94.29e6

        # count number of bits set
        nbits, M = 0, keep
        while M != 0:
            if M & 1:
                nbits += 1
            M >>= 1

        # result is often one sample too long
        T = numpy.arange(1+totalsamp/nbits) * period

        T = T.repeat(nbits)  # [a, b, ...] w/ nbits=2 --> [a, a, b, b, ...]
        assert len(T) >= totalsamp, (len(T), totalsamp)
        T = T[:totalsamp]  # clip to actual register size

        # T now contains time of the sample read from each address

        # demux into logical channels of the appropriate length
        # eg. if chan_keep selects an odd number of channels, then
        # some will be one sample shorter.
        return [T[i::nbits] for i in range(len(chans))]

    def _exchange(self, addrs, values=None):
        """Exchange a single low level message
        """
        pad = None
        if len(addrs) < 3:
            pad = 3-len(addrs)
            addrs.extend([0]*pad)
            values.extend([None]*pad)

        msg = numpy.zeros(2+2*len(addrs), dtype=be32)
        msg[0] = random.randint(0, 0xffffffff)
        msg[1] = msg[0] ^ 0xffffffff

        for i, (A, V) in enumerate(zip(addrs, values), 1):
            A &= 0x00ffffff
            if V is None:
                A |= 0x10000000
            msg[2*i] = A
            msg[2*i+1] = V or 0

        tosend = msg.tostring()
        _spam.debug("%s Send (%d) %s", self.dest, len(tosend), repr(tosend))
        self.sock.sendto(tosend, self.dest)

        while True:
            reply, src = self.sock.recvfrom(1024)
            _spam.debug("%s Recv (%d) %s", src, len(reply), repr(reply))

            if len(reply) % 8:
                reply = reply[:-(len(reply) % 8)]

            if len(tosend) != len(reply):
                _log.error("Reply truncated %d %d", len(tosend), len(reply))
                continue

            reply = numpy.fromstring(reply, be32)
            if (msg[:2] != reply[:2]).any():
                _log.error('Ignore reply w/o matching nonce %s %s',
                           msg[:2], reply[:2])
                continue
            elif (msg[2::2] != reply[2::2]).any():
                _log.error('reply addresses are out of order')
                continue

            break

        ret = reply[3::2]
        if pad:
            ret = ret[:-pad]
        return ret

    def exchange(self, addrs, values=None):
        """Accepts a list of address and values (None to read).
        Returns a numpy.ndarray in the same order.
        """
        addrs = list(addrs)

        if values is None:
            values = [None]*len(addrs)
        else:
            values = list(values)

        ret = numpy.zeros(len(addrs), be32)
        for i in range(0, len(addrs), 127):
            A, B = addrs[i:i+127], values[i:i+127]

            P = self._exchange(A, B)
            ret[i:i+127] = P

        return ret

    def _trysize(self, start_addr):
        values = self.exchange(range(start_addr, start_addr+self.preamble_max_size))
        rom_size = self._checkrom(values, True)

        if rom_size is not None:
            values = self.exchange(range(start_addr, start_addr+self.preamble_max_size+rom_size))

        self._checkrom(values)

    def _checkrom(self, values, preamble_check=False):
        values = numpy.frombuffer(values, be16)
        _log.debug("ROM[0] %08x", values[0])
        values = values[1::2]  # discard upper bytes

        while len(values):
            type = values[0] >> 14
            size = values[0] & 0x3fff
            _log.debug("ROM Descriptor type=%d size=%d", type, size)

            if type == 0:
                break

            blob, values = values[1:size+1], values[size+1:]
            if len(blob) != size and preamble_check is False:
                raise ValueError("Truncated ROM Descriptor")

            if type == 1:
                blob = blob.tostring()
                if self.descript is None:
                    self.descript = blob
                else:
                    _log.info("Extra ROM Text '%s'", blob)
            elif type == 2:
                blob = ''.join(["%04x" % b for b in blob])
                if self.jsonhash is None:
                    self.jsonhash = blob
                elif self.codehash is None:
                    self.codehash = blob
                else:
                    _log.info("Extra ROM Hash %s", blob)

            elif type == 3 and preamble_check is False:
                if self.regmap is not None:
                    _log.error("Ignoring additional JSON blob in ROM")
                else:
                    self.regmap = json.loads(zlib.decompress(
                        blob.tostring()).decode('ascii'))

            elif type == 3 and preamble_check is True:
                return size

        if self.regmap is None and preamble_check is False:
            raise RuntimeError('ROM contains no JSON')


    def _readrom(self):
        self.descript = None
        self.codehash = None
        self.jsonhash = None
        self.regmap = None

        try:
            _log.info("Trying with init_addr %d", self.init_rom_addr)
            self._trysize(self.init_rom_addr)
        except ValueError:
            _log.info("Trying with max_addr %d", self.max_rom_addr)
            try:
                self._trysize(self.max_rom_addr)
            except ValueError:
                raise ValueError("Could not read ROM using either start addresses")
        _log.info("ROM was successfully read")