from __future__ import print_function
import numpy
from datetime import datetime
import json
import zlib
import random
import socket
import sys
from functools import reduce

from . import RomError
from .base import DeviceBase, print_reg
import logging


_log = logging.getLogger(__name__)
# special logger for use in exchange()
_spam = logging.getLogger(__name__ + '.packets')
_spam.propagate = False

if sys.version_info >= (3, 0):
    unicode = str

be32 = numpy.dtype('>u4')
be16 = numpy.dtype('>u2')


def yscale_inj(wave_samp_per=1):
    try:
        from math import ceil, log

        cic_period = 22
        cic_order = 2

        # FW default shift assuming wsp = 1
        shift_base = ceil(log(cic_period ** cic_order, 2))

        # FW LO pre-scaling to cancel out non-unit CIC gain
        pre_gain = 2**shift_base / cic_period**cic_order
        pre_gain *= 0.5

        per = cic_period * wave_samp_per
        bit_g = per**cic_order  # Bit growth
        bit_g_shift = ceil(log(bit_g, 2))
        wave_shift = bit_g_shift - shift_base
        # FW accounts for cic_order when shifting
        wave_shift *= 1.0 / cic_order

        cic_gain = bit_g / 2**(cic_order * wave_shift + shift_base)

        adc_fs = 2.0**19 * cic_gain * pre_gain

        return wave_shift, adc_fs
    except Exception as e:
        raise RuntimeError("yscale_rfs(%s) %s" % (wave_samp_per, e))


def yscale_resctrl(wave_samp_per=1):
    try:
        from math import ceil, log

        cic_period = 1
        cic_order = 2
        per = cic_period * wave_samp_per

        bit_g = per**cic_order  # Bit growth
        # FW accounts for cic_order when shifting
        wave_shift = ceil(log(bit_g, 2) / cic_order)

        cic_gain = bit_g / 2**(cic_order * wave_shift)

        adc_fs = 2.0**17 * cic_gain

        return wave_shift, adc_fs
    except Exception as e:
        raise RuntimeError("yscale_rfs(%s) %s" % (wave_samp_per, e))


def yscale_rfs(wave_samp_per=1):
    # Note that changes to the output of this function
    # need to be reflected in testsub.cpp
    try:
        from math import ceil, log

        lo_cheat = (74762 * 1.646760258) / 2**17

        shift_base = 4
        cic_period = 33
        cic_n = wave_samp_per * cic_period

        def log2(n):
            try:
                return log(n, 2)
            except ValueError as e:
                raise ValueError("log2(%s) %s" % (n, e))

        shift_min = log2(cic_n**2 * lo_cheat) - 12

        wave_shift = max(0, ceil(shift_min / 2))
        adc_fs = (16 * lo_cheat * (33 * wave_samp_per)**2) * \
                 (4**(8 - wave_shift) / 512.0 / (2**shift_base))

        return wave_shift, adc_fs
    except Exception as e:
        raise RuntimeError("yscale_rfs(%s) %s" % (wave_samp_per, e))


def _int(s):
    try:
        # Catch actual ints
        return int(s)
    except ValueError:
        pass
    if hasattr(s, 'startswith'):
        try:
            if s.startswith('0x'):
                return int(s, 16)
            elif s.startswith('0b'):
                return int(s, 2)
        except ValueError:
            pass
    return None


class LEEPDevice(DeviceBase):
    backend = 'leep'
    init_rom_addr = 0x800
    max_rom_addr = 0x4000
    ''' Preamble is bound in build_rom.py by limiting description
        to 40 words (80 bytes). Each hash is 10 words.
        40 + 10 + 10 = 60. Plus 4 for each of the types.
    '''
    preamble_max_size = 64
    ''' Hash = 10 + 10 and descriptor for each type
        (hash and description) is one.
    '''
    hash_descriptor_size = 24
    size_desc = 0
    size_rom = 0
    the_rom = []

    def __init__(self, addr, timeout=0.1, **kws):
        DeviceBase.__init__(self, **kws)
        host, _sep, port = addr.partition(':')
        self.dest = (host, int(port or '50006'))

        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        self.sock.settimeout(timeout)

        self._readrom()

        app_string = "Unknown"
        if self.regmap is not None:
            try:
                app_string = self.regmap["__metadata__"]["application"]
            except KeyError:
                pass
        self.rfs = False
        self.resctrl = False
        self.injector = False
        if 'RES_CTRL' in app_string:
            self.resctrl = True
        elif 'INJECTOR' in app_string:
            self.injector = True
        else:
            self.rfs = True

    def close(self):
        self.sock.close()
        super(LEEPDevice, self).close()

    def _decode(self, reg, instance=[]):
        """Returns (name, addr, len, infodict)"""
        info = {  # Default info dict
            "addr_width": 0,  # TODO enable variable read size
            "data_width": 32,
            "sign": "unsigned",
        }
        _reg = _int(reg)
        if _reg is not None:
            return "0x{:x}".format(_reg), _reg, 1, info
        if instance is not None:
            reg = self.expand_regname(reg, instance=instance)
        info = self.get_reg_info(reg, instance=None)
        size = 2**info.get('addr_width', 0)
        base_addr = info['base_addr']
        if isinstance(base_addr, (bytes, unicode)):
            base_addr = int(base_addr, 0)
        return reg, base_addr, size, info

    @print_reg
    def reg_write_offset(self, ops, instance=[]):

        assert isinstance(ops, (list, tuple))

        addrs, values = [], []
        for op in ops:
            name, value = op[:2]
            offset = 0
            if len(op) > 2:
                offset = op[2]
            name, base_addr, size = self._decode(name, instance)[:3]
            if not hasattr(value, '__len__'):
                value = [value]
            value = numpy.array(value).astype('I')
            _log.debug('reg_write %s <- %s', name, value)
            for A, V in enumerate(value, base_addr+offset):
                addrs.append(A)
                values.append(V)

        addrs = numpy.asarray(addrs)
        values = numpy.asarray(values)

        self.exchange(addrs, values)

    def reg_write(self, ops, instance=[]):
        return self.reg_write_offset([(op[0], op[1], 0) for op in ops], instance=instance)

    def reg_read_size(self, name_sizes, instance=[]):
        """'name_sizes' is iterable of (name, size, offset) where:
            'name' can be either a string reg name or an int address
            'size' can be an int number of elements of 'data_width' to read, or None.
            'offset' can be int positive address offset or None (alias of 0)
        If 'size' is None, then (2**aw) elements will be read (where 'aw' is the
        'addr_width' of the register).
        If 'name' is an address (int) then a 'size' of None implies 'size' 1."""
        addrs = []
        lens = []
        for name_size in name_sizes:
            name, size = name_size[:2]
            offset = 0
            if len(name_size) > 2:
                offset = name_size[2]
            name, base_addr, L, info = self._decode(name, instance)
            if size is None:
                size = L
            else:
                size = int(size)
            lens.append((info, size))
            addrs.extend(range(base_addr + offset, base_addr + offset + size))

        raw = self.exchange(addrs)

        ret = []
        for i, (info, L) in enumerate(lens):
            data, raw = raw[:L], raw[L:]
            assert len(data) == L, (len(data), L)
            if info.get('sign', 'unsigned') == 'signed':
                # sign extend
                # mask of data bits excluding sign bit
                mask = (2**(info['data_width'] - 1)) - 1
                # invert to give mask of sign bit and extension bits
                mask ^= 0xffffffff
                # test sign bit
                neg = (data & mask) != 0
                # extend only negative numbers
                data[neg] |= mask
                # cast to signed
                data = data.astype('i4')
            _log.debug('reg_read %s -> %s ...', name_sizes[i][0], data[:10])
            # unwrap scalar from ndarray
            # if info.get('addr_width', 0) == 0:
            # TODO - does this break anything?
            if L <= 1:
                data = data[0]
            ret.append(data)

        return ret

    @print_reg
    def reg_read(self, names, instance=[]):
        name_sizes = [(name, None) for name in names]
        return self.reg_read_size(name_sizes, instance)

    def set_decimate(self, dec, instance=[]):
        if self.rfs:
            wave_shift, _Ymax = yscale_rfs(dec)
        elif self.resctrl:
            wave_shift, _Ymax = yscale_resctrl(dec)
        elif self.injector:
            wave_shift, _Ymax = yscale_inj(dec)

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
        info = self.get_reg_info('chan_keep', instance=instance)
        nch = info['data_width']
        # list of channel numbers to mask
        if isinstance(chans, list):
            chans = reduce(lambda ll, r: ll | r,
                           [2**(nch - 1 - n) for n in chans], 0)
        self.reg_write([('chan_keep', chans)], instance=instance)

    def get_channel_mask(self, instance=[]):
        chans, =  self.reg_read(['chan_keep'], instance=instance)
        return chans

    def wait_for_acq(self, tag=False, toggle_tag=False, timeout=5.0,
                     instance=[]):
        """Wait for next waveform acquisition to complete.
        If tag=True, then wait for the next acquisition which includes the
        side-effects of all preceding register writes
        """
        start = datetime.utcnow()

        if self.rfs:
            T, = self.reg_read(['dsp_tag'], instance=instance)
            if tag or toggle_tag:
                T = (T + 1) & 0xff
                self.reg_write([('dsp_tag', T)], instance=instance)
                _log.debug('Set Tag %d', T)

        inst = self.instance + instance
        # assume that the shell_#_ number is the first
        mask = 1
        if inst:
            mask = 2**int(inst[0])

        if self.resctrl:
            mask = 0xF  # Always re-arm 4 channels

        while True:
            if self.injector:
                self.reg_write([('circle_buf_flip', mask)], instance=[])
            else:
                self.reg_write([('circle_buf_flip', mask)], instance=None)

            while True:
                now = datetime.utcnow()
                delta = now - start
                delta_us = delta.seconds + delta.microseconds / 1e6
                if delta_us >= timeout:
                    raise RuntimeError('Timeout')

                ''' TODO:
                    use exchange() and optimize to fetch slow_data[33] as well
                '''
                if self.rfs or self.injector:
                    ready_register = 'llrf_circle_ready'
                else:
                    ready_register = 'circle_data_ready'
                ready, = self.reg_read([ready_register], instance=None)

                if ready & mask:
                    break

            if self.rfs:
                slow, = self.reg_read(['slow_data'], instance=instance)
                tag_old = slow[34]
                tag_new = slow[33]
                dT = (tag_old - T) & 0xff
                tag_match = dT == 0 and tag_new == tag_old

                if not tag:
                    break

                if tag_match:
                    # all done, waveform reflects latest parameter changes
                    break

                if dT != 0xff:
                    msg = 'acquisition collides with another client:'
                    msg += '%d %d %d' % (tag_old, tag_new, T)
                    raise RuntimeError(msg)
            else:
                return now

            _log.debug('Acquire retry')

        # datetimestr = now.isoformat()+'Z'
        return tag_match, slow, now

    def get_channels(self, chans=[], instance=[]):
        """:returns: a list of :py:class:`numpy.ndarray` with the numbered channels.
        chans may be a bit mask or a list of channel numbers
        """
        info = self.get_reg_info('chan_keep', instance=instance)
        nch = info['data_width']
        interested = reduce(lambda ll, r: ll | r,
                            [2**(nch - 1 - n) for n in chans], 0)

        if self.rfs:
            keep, dec = self.reg_read(['chan_keep', 'wave_samp_per'],
                                      instance=instance)
            data, = self.reg_read(['circle_data'], instance=instance)
            wave_shift, Ymax = yscale_rfs(dec)
        else:
            if self.resctrl:
                keep, dec = self.reg_read(['chan_keep', 'wave_samp_per'],
                                          instance=None)
                data, = self.reg_read(['circle_data_%s' % (instance[0])],
                                      instance=None)
                wave_shift, Ymax = yscale_resctrl(dec)
            elif self.injector:
                keep, dec = self.reg_read(['chan_keep', 'wave_samp_per'],
                                          instance=[])
                data, = self.reg_read(['circle_data'], instance=[])
                wave_shift, Ymax = yscale_inj(dec)

        # assume wave_shift has been set properly
        assert Ymax != 0, dec

        if (keep & interested) != interested:
            # chans must be a strict sub-set of keep
            msg = 'Requested channels (%x) not kept (%x)' % (interested, keep)
            raise RuntimeError(msg)

        # count number of bits set
        nbits, M = 0, keep
        while M != 0:
            if M & 1:
                nbits += 1
            M >>= 1

        # Lop off extra samples to get same number of samples per channel
        L = len(data)
        xtra = L % nbits
        data = numpy.delete(data, range(L - xtra, L))
        cdata, M = {}, 0
        for ch in range(nch):
            cmask = 2**(nch - 1 - ch)
            if not (keep & cmask):
                continue
            if interested & cmask:
                cdata[ch] = data[M::nbits] / Ymax

            M += 1

        # finally, ensure the results are in the same order as args
        return list([cdata[ch] for ch in chans])

    def get_timebase(self, chans=[], instance=[]):
        if self.rfs:
            info = self.get_reg_info('circle_data', instance=instance)
            keep, dec = self.reg_read([
                'chan_keep',
                'wave_samp_per',
            ], instance=instance)
            period = 2 * 33 * dec * 14 / 1320e6
        else:
            info = self.get_reg_info('circle_%s_data' % instance[0],
                                     instance=None)
            keep, dec = self.reg_read(['chan_keep', 'wave_samp_per'],
                                      instance=None)
            if self.resctrl:
                period = dec / 8e3
            elif self.injector:
                period = 22 * dec * 140 / (11 * 1300e6)

        totalsamp = 2**info['addr_width']

        # count number of bits set
        nbits, M = 0, keep
        while M != 0:
            if M & 1:
                nbits += 1
            M >>= 1
        # result is often one sample too long
        T = numpy.arange(1 + totalsamp / nbits) * period

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
            pad = 3 - len(addrs)
            addrs.extend([0] * pad)
            values.extend([None] * pad)

        msg = numpy.zeros(2 + 2 * len(addrs), dtype=be32)
        msg[0] = random.randint(0, 0xffffffff)
        msg[1] = msg[0] ^ 0xffffffff

        for i, (A, V) in enumerate(zip(addrs, values), 1):
            A &= 0x00ffffff
            if V is None:
                A |= 0x10000000
            msg[2 * i] = A
            msg[2 * i + 1] = V or 0

        tosend = msg.tobytes()
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

            reply = numpy.frombuffer(reply, be32)
            if (msg[:2] != reply[:2]).any():
                _log.error('Ignore reply w/o matching nonce %s %s',
                           msg[:2], reply[:2])
                continue
            elif (msg[2::2] != reply[2::2]).any():
                print(f"  msg[2::2] = {msg[2::2]}\n  reply[2::2] = {reply[2::2]}")
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
            values = [None] * len(addrs)
        else:
            values = list(values)

        if len(values) > len(addrs):
            base = addrs[0]
            addrs = [base+n for n in range(len(values))]

        ret = numpy.zeros(len(addrs), be32)
        for i in range(0, len(addrs), 127):
            A, B = addrs[i:i + 127], values[i:i + 127]

            P = self._exchange(A, B)
            ret[i:i + 127] = P

        return ret

    def _trysize(self, start_addr):
        end_addr = start_addr + self.preamble_max_size
        values = self.exchange(range(start_addr, end_addr))
        values_preamble = numpy.array(values)
        self._checkrom(values, True)
        if self.size_rom != 0:
            total_rom_size = (self.hash_descriptor_size +
                              self.size_desc + self.size_rom)
            stop_addr = end_addr + total_rom_size - self.preamble_max_size
            values_json = self.exchange(range(end_addr, stop_addr))
            preamble_json = numpy.concatenate((values_preamble, values_json))
            values_full = numpy.array(preamble_json, be32)
            self._checkrom(values_full)
            return values_full
        else:
            raise RomError("ROM not found, size is zero")

    def _checkrom(self, values, preamble_check=False):
        rom_bad_value = 0xdeadf00d
        if values[0] == rom_bad_value:
            raise RomError("ROM not found, bad value")
        values = numpy.frombuffer(values, be16)
        _log.debug("ROM[0] %08d", values[0])
        values = values[1::2]  # discard upper bytes
        desc_ix = 1
        desc_addr = 0

        while len(values):
            type = values[0] >> 14
            size = values[0] & 0x3fff
            pp = desc_ix, desc_addr, type, size
            _log.debug("ROM Descriptor #%d addr=%d type=%d size=%d" % pp)
            desc_ix += 1
            desc_addr += (size + 1)

            if type == 0:
                break

            blob, values = values[1:size + 1], values[size + 1:]
            if len(blob) != size and preamble_check is False:
                _log.error("Truncated: %d", len(blob))
                raise RomError("Truncated ROM Descriptor")

            if type == 1:
                blob = blob.tobytes().decode()
                self.size_desc = size
                if self.descript is None:
                    self.descript = blob
                else:
                    _log.debug("Extra ROM Text '%s'", blob)

            elif type == 2:
                blob = ''.join(["%04x" % b for b in blob])
                if self.jsonhash is None:
                    self.jsonhash = blob
                elif self.codehash is None:
                    self.codehash = blob
                else:
                    _log.debug("Extra ROM Hash %s", blob)

            elif type == 3 and preamble_check is False:
                if self.regmap is not None:
                    _log.error("Ignoring additional JSON blob in ROM")
                else:
                    _log.debug("Found JSON blob in ROM")
                    self.regmap = json.loads(zlib.decompress(
                        blob.tobytes()).decode('ascii'))

            elif type == 3:
                self.size_rom = size

        if self.regmap is None and preamble_check is False:
            raise RomError('ROM contains no JSON')

    def _readrom(self):
        self.descript = None
        self.codehash = None
        self.jsonhash = None
        self.regmap   = None
        self._has_rom = False

        # Try to read ROM at both addresses before raising error
        try:
            _log.debug("Trying with init_addr %d", self.init_rom_addr)
            self.the_rom = self._trysize(self.init_rom_addr)
        except (RuntimeError, ValueError, RomError):
            self.the_rom = []
            _log.debug("Trying with max_addr %d", self.max_rom_addr)
            try:
                self.the_rom = self._trysize(self.max_rom_addr)
            except RomError as e:
                self.the_rom = []
                _log.error("raw.py: {}. Register name decoding disabled.".format(str(e)))
            except (RuntimeError, ValueError):
                self.the_rom = []
                _log.debug("Could not read ROM using either start addresses")
        if len(self.the_rom) > 0:
            _log.debug("ROM was successfully read")
            self._has_rom = True
        return
