
import logging
_log = logging.getLogger(__name__)

import json
import zlib
import re

import numpy

# flags for _wait_acq
IGNORE = "IGNORE"
WARN = "WARN"
ERROR = "ERROR"

def open(addr, **kws):
    """Access to a single LEEP Device.

    Device addresses take the form of "ca://<prefix>" or "leep://<ip>[:<port>]".

    "ca://" addresses take a Process Variable (PV) name prefix string.

    "leep://" addresses are a hostname or IP address, with an optional port number.

    >>> from leep import open
    >>> dev = open('leep://localhost')

    or

    >>> dev = open('ca://TST:')

    :param str addr: Device Address.
    :param float timeout: Communications timeout.
    :param list instance: List of instance identifiers.
    :returns: :py:class:`base.DeviceBase`
    """
    if addr.startswith('ca://'):
        try:
            from cothread.catools import caget
        except ImportError:
            raise RuntimeError('ca:// not available, cothread module not found in PYTHONPATH')
        from .ca import CADevice
        return CADevice(addr[5:], **kws)

    elif addr.startswith('leep://'):
        from .raw import LEEPDevice
        return LEEPDevice(addr[7:], **kws)

    elif addr.startswith('file://'):
        from .file import FileDevice
        return FileDevice(addr[7:], **kws)

    else:
        raise ValueError("Unknown '%s' must begin with ca://, leep://, or file://" % addr)

class DeviceBase(object):
    backend = None  # 'ca' or 'leep'

    def __init__(self, instance=[]):
        self.instance = instance[:]  # shallow copy

    def close(self):
        pass

    def __enter__(self):
        return self

    def __exit__(self, A, B, C):
        self.close()

    def expand_regname(self, name, instance=[]):
        """Return a full register name from the short name and optionally instance number(s)

        >>> D.expand_regname('XXX', instance=[0])
        'tget_0_delay_pc_XXX'
        """

        # check for full register name,
        # or shortcut to disable mapping
        if name in self.regmap or instance is None:
            return name

        # build a regexp
        # from a list of name fragments
        I = self.instance + instance + [name]
        # match when consecutive fragments are seperated by
        #  1. a single '_'.  ['A', 'B'] matches 'A_B'.
        #  2. two '_' with anything inbetween.  'A_blah_B' or 'A_x_y_z_B'.
        I = r'_(?:.*_)?'.join([re.escape(str(i)) for i in I])
        R = re.compile('^.*%s$' % I)

        ret = [x for x in self.regmap if R.match(x)]
        if len(ret) == 1:
            return ret[0]
        elif len(ret) > 1:
            raise RuntimeError('%s Matches more than one register: %s' % (R.pattern, ' '.join(ret)))
        else:
            raise RuntimeError('No match for register pattern %s' % R.pattern)

    def reg_write(self, ops, instance=[]):
        """Write to registers.

        :param list ops: A list of tuples of register name and value.
        :param list instance: List of instance identifiers.

        Register names are expanded using self.instance and the instance lists.

        >>> D.reg_write([
            ('reg_a', 5),
            ('reg_b', 6),
        ])
        """
        raise NotImplementedError

    def reg_read(self, names, instance=[]):
        """Read from registers.

        :param list names: A list of register names.
        :param list instance: List of instance identifiers.
        :returns: A :py:class:`numpy.ndarray` for each register name.

        >>> A, B = D.reg_read(['reg_a', 'reg_b'])
        """
        raise NotImplementedError

    def __setitem__(self, key, value):
        self.reg_write([(key, value)])
    def __getitem__(self, key):
        return self.reg_read([key])[0]

    def get_reg_info(self, name, instance=[]):
        """Return a dict describing the named register.
        This dictionary is passed through from the information read from the device ROM.

        Common dict keys are:

        * access
        * base_addr
        * addr_width
        * data_width
        * sign
        * description

        :param str name: A register name
        :param list instance: List of instance identifiers.
        :returns: A dict with string keys.
        """
        if instance is not None:
            name = self.expand_regname(name, instance=instance)
        return self.regmap[name]

    def set_channel_mask(self, chans=None, instance=[]):
        """Enabled specified channels.
        chans may be a bit mask or a list of channel numbers (zero indexed).

        :param list chans: A list of channel integer numbers (zero indexed).
        :param list instance: List of instance identifiers.
        """
        raise NotImplementedError

    def wait_for_acq(self, tag=False, timeout=5.0, instance=[]):
        """Wait for next waveform acquisition to complete.
        If tag=True, then wait for the next acquisition which includes the
        side-effects of all preceding register writes

        ;param bool tag: Whether to use the tag mechanism to wait for a update
        :param float timeout: How long to wait for an acquisition.  Seperate from the communications timeout.
        :param list instance: List of instance identifiers.
        """
        raise NotImplementedError

    def get_channels(self, chans=[], instance=[]):
        """:returns: a list of :py:class:`numpy.ndarray` with the numbered channels.
        chans may be a bit mask or a list of channel numbers.

        The returned arrays have been scaled.
        """
        raise NotImplementedError

    def get_timebase(self, chans=[], instance=[]):
        """Return an array of times for each sample returned by :py:meth:`get_channels`.

        Note that the number of samples may be different for some channels
        if the number of selected channels is not a power of two.
        """
        raise NotImplementedError

    def set_decimate(self, dec):
        raise NotImplementedError

    def assemble_tgen(self, prog, instance=[]):
        """Build a "program" for the TGEN sequencer.

        Programs are lists of tuples.
        Each tuple has the form ('set', 'register', value) or
        ('sleep', delay).  For example:

        >>> value = dev.assemble_tgen([
            ('set', 'proc_lim[1]', 5000), # X_low
            ('set', 'proc_lim[0]', 5000), # X_high
            ('set', 'proc_lim[3]', 0), # Y_low
            ('set', 'proc_lim[2]', 0), # Y_high
            ('sleep', 1000),
            ('set', 'proc_lim[1]', 0), # X_low
            ('set', 'proc_lim[0]', 0), # X_high
        ])

        :param list prog: A list of instruction tuples
        :returns: A value which can be passed to :py:meth:`reg_write`.
        """

        # The XXX sequencer runs "programs" of writes.
        # Each instruction is stored in 4 words/addresses.
        #
        # [0] Delay (applied _after_ write)
        # [1] Address to write
        # [2] value high word (16-bits)
        # [3] value low word (16-bits)

        ret = []

        for instn, inst in enumerate(prog):
            try:
                if inst[0] == 'set':
                    _inst, name, value = inst
                    value = int(value)

                    # eg.
                    #  name
                    #  name[offset]
                    M = re.match(r'^([^\[\]]+)(?:\[(\d+)\])?$', name)
                    if M is None:
                        raise RuntimeError('malformed name')

                    name, offset = M.groups()
                    offset = int(offset or '0', 0)

                    name = self.expand_regname(name, instance=instance)
                    info = self.regmap[name]

                    N = 2**info.get('addr_width', 0)
                    if offset >= N:
                        raise RuntimeError('offset out of bounds (%s < %s)' % (offset, N))

                    addr = info['base_addr'] + offset

                    # if addr > 0xffff:
                    #       raise RuntimeError('XXX requires registers below 16-bit limit (%x)'%addr)

                    ret.extend([
                        0,  # all delays start as zero
                        addr,
                        (value >> 16) % 0x10000,
                        value & 0xffff,
                    ])

                elif inst[0] == 'sleep':
                    _inst, delay = inst
                    exp = self.regmap["__metadata__"]["tgen_granularity_log2"]
                    if exp < 0:
                        raise RuntimeError('tgen delay scale exponent out of bounds (%s < 0)' % (exp))
                    delay = delay/(pow(2,exp))
                    delay = int(delay)

                    assert delay >= 0, inst
                    if len(ret) < 4:
                        raise RuntimeError('sleep must follow a set')
                    elif ret[-4] != 0:
                        raise RuntimeError('sleep must not follow sleep')
                    elif delay == 0:
                        continue

                    while delay > 0xffff:
                        # too long for a single instruction.
                        # repeat write with max delay until
                        # long enough.
                        delay -= 0xffff

                        ret[-4] = 0xffff
                        ret.extend(ret[-4:])

                    # set delay of previous instruction
                    ret[-4] = delay

                else:
                    raise RuntimeError('Unknown instruction')

            except Exception as e:
                raise e.__class__('Instruction %d %s: %s' % (instn, inst, e))

        # program must end with a "stop" command (set address zero)
        info = self.get_reg_info('XXX', instance=instance)
        maxcnt = 2**info['addr_width']
        assert maxcnt >= 4, info
        if len(ret) > maxcnt-4:
            raise RuntimeError('tget Sequence %d exceeds max %d' % (len(ret), maxcnt-4))
        ret.extend([0]*(maxcnt-len(ret)))
        assert len(ret) == maxcnt, (len(ret), maxcnt)
        return ret

    def tgen_reg_sequence(self, prog, instance=[]):
        """Assemble TGEN program and bank switching
        register writes
        """
        val = self.assemble_tgen(prog, instance=instance)
        next, = self.reg_read(['bank_next'])

        return [('XXX', val),
                ('bank_next', next ^ 1), ]
