
import numpy
import datetime
import zlib
import json
from functools import reduce
import logging
_log = logging.getLogger(__name__)

from .base import DeviceBase

caget = caput = camonitor = None
try:
    from cothread.catools import caget as _caget, caput as _caput, camonitor, FORMAT_TIME, DBR_CHAR_STR
except ImportError:
    pass
else:
    from cothread import Event


def caget(*args, **kws):
    try:
        R = _caget(*args, **kws)
    except Exception:
        _log.exception('Error caget(%s, %s)' % (args, kws))
        raise
    else:
        _log.debug('caget(%s, %s) -> %s' % (args, kws, R))
    return R


def caput(*args, **kws):
    _log.debug('caput(%s, %s' % (args, kws))
    _caput(*args, **kws)


class CADevice(DeviceBase):
    backend = 'ca'

    def __init__(self, addr, timeout=5.0, **kws):
        DeviceBase.__init__(self, **kws)
        self.timeout = timeout
        assert self.timeout > 0.1, self.timeout  # must be reasonable
        self.prefix = str(addr)  # PV prefix

        # fetch mapping from register name to info dict
        # {'records':{'reg_name':{'<info>':'<value>'}}}
        # common info tags are:
        #  'input' PV to read register
        #  'output' PV to write register
        #  'increment' PV to +1 register
        info = json.loads(zlib.decompress(caget(self.prefix+'CTRL_JINFO')))
        self._info = info['records']

        # raw JSON blob from device
        # {'reg_name:{'base_addr':0, ...}}
        self.regmap = json.loads(zlib.decompress(
            caget(self.prefix+'CTRL_JSON')))

        extra_reg = set(self._info) - set(self.regmap)
        if extra_reg:
            # inject empty info for fake/missing registers
            self.regmap.update([(K, {}) for K in extra_reg])

        self._S = None  # placeholder for subscription
        # Event acts as a cache for the last received value.
        # This cache is _cleared_ each time a value is returned by Wait()
        self._E = Event()

    def close(self):
        if self._S is not None:
            self._S.close()
            self._S = None

    def pv_name(self, name, tag, instance=[]):
        name = self.expand_regname(name, instance=instance)
        info = self._info[name]
        return str(info[tag])

    def pv_read(self, name, tag, instance=[]):
        """Read associated PV
        """
        pvname = self.pv_name(name, tag, instance=instance)
        return caget(pvname, timeout=self.timeout)

    def pv_write(self, name, tag, value, instance=[], wait=True, timeout=None):
        """Write associated PV
        """
        pvname = self.pv_name(name, tag, instance=instance)
        caput(pvname, value, wait=wait, timeout=timeout or self.timeout)

    def reg_write(self, ops, instance=[]):
        for name, value in ops:
            name = self.expand_regname(name, instance=instance)
            info = self._info[name]
            pvname = str(info['output'])

            # CA only has signed integers
            value = numpy.asarray(value, dtype='i')

            caput(pvname, value, wait=True, timeout=self.timeout)

    def reg_read(self, names, instance=[]):
        ret = [None]*len(names)
        for i, name in enumerate(names):
            name = self.expand_regname(name, instance=instance)
            info = self._info[name]
            pvname = str(info['input'])

            caput(pvname+'.PROC', 1, wait=True, timeout=self.timeout)
            # force as unsigned
            ret[i] = numpy.asanyarray(
                caget(pvname, timeout=self.timeout), dtype='i')
            # cope with lack of unsigned in CA
            info = self.regmap[name]
            if info.get('sign', 'unsigned') == 'unsigned':
                ret[i] = ret[i].view(dtype='I')

        return ret

    @property
    def descript(self):
        return caget(str(self.prefix+'CTRL_FW_DESC'), datatype=DBR_CHAR_STR)

    @property
    def codehash(self):
        return caget(str(self.prefix+'CTRL_FW_CODEHASH'), datatype=DBR_CHAR_STR)

    @property
    def jsonhash(self):
        return '<not implemented>'

    def get_decimate(self, instance=[]):
        # return list to be compatible with raw.py get_decimate
        return [self.pv_read('wave_samp_per', 'setting', instance=instance)]

    def set_decimate(self, dec, instance=[]):
        assert dec >= 1 and dec <= 255
        self.pv_write('wave_samp_per', 'setting', dec, instance=instance)

    def set_channel_mask(self, chans=None, instance=[]):
        """Enabled specified channels.
        chans may be a bit mask or a list of channel numbers
        """
        # assume that the shell_#_ number is the first

        if type(chans) is int:
            li = []
            for i in range(12):
                if chans & (1 << i):
                    li.append(11-i)
            chans = tuple(li)

        chans = set(chans)
        disable = set(range(12)) - chans
        # enable/disable for even/odd channels are actually aliases
        # so disable first, then enable
        if disable:
            [self.pv_write('circle_data', 'enable%d' % ch, 'Disable')
             for ch in disable]
        if chans:
            [self.pv_write('circle_data', 'enable%d' % ch, 'Enable')
             for ch in chans]

    def get_channel_mask(self, instance=[]):
        # make list of masks for each bit which is set.
        chans = [2**(11-n) for n in range(12)
                 if self.pv_read('circle_data', 'enable%d' % n)]
        return reduce(lambda l, r: l | r, chans, 0)

    def wait_for_acq(self, toggle_tag=False, tag=False, timeout=5.0, instance=[]):
        """Wait for next waveform acquisition to complete.
        If tag=True, then wait for the next acquisition which includes the
        side-effects of all preceding register writes
        """

        if tag or toggle_tag:
            self.pv_write('dsp_tag', 'increment', 1, instance=instance)

        T = self.pv_read('dsp_tag', 'readback')
        _log.debug('Acquire T=%d toggle=%s tag=%s', T, toggle_tag, tag)

        if self._S is None:
            # since we need to return the whole thing anyway,
            # monitor the slow data _waveform_.
            pv = self.pv_name('slow_data', 'rawinput', instance=instance)
            _log.debug('Monitoring %s', pv)
            self._S = camonitor(pv, self._E.Signal, format=FORMAT_TIME)
            # wait for, and consume, initial update
            self._E.Wait(timeout=timeout)

        while True:
            slow = self._E.Wait(timeout=timeout)
            now = datetime.datetime.utcnow()

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

        return tag_match, slow, now

    def get_channels(self, chans=[], instance=[]):
        """:returns: a list of :py:class:`numpy.ndarray` with the numbered channels.
        chans may be a bit mask or a list of channel numbers
        """
        names = [self.pv_name('circle_data', 'input%d' %
                              ch, instance=instance) for ch in chans]
        names += [self.pv_name('circle_data', 'scale%d' %
                               ch, instance=instance) for ch in chans]

        ret = caget(names, format=FORMAT_TIME)

        wfs, scales = ret[:len(chans)], ret[len(chans):]
        # print('scales', scales)
        for wf, scale in zip(wfs, scales):
            # reverse scaling applied in IOC to give [0, 1) scale
            wf /= scale

        # ensure that waveform timestamps are consistent
        if len(wfs) >= 2 and not all([wfs[0].raw_stamp == R.raw_stamp for R in wfs[1:]]):
            raise RuntimeError("Inconsistent timestamps! %s" %
                               [R.raw_stamp for R in wfs])

        return wfs

    def get_timebase(self, chans=[], instance=[]):
        ret = caget([self.pv_name('circle_data', 'time%d' %
                                  ch, instance=instance) for ch in chans], format=FORMAT_TIME)
        if len(ret) >= 2 and not all([ret[0].raw_stamp == R.raw_stamp for R in ret[1:]]):
            raise RuntimeError("Inconsistent timestamps! %s" %
                               [R.raw_stamp for R in ret])
        return ret
