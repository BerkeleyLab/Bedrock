from __future__ import print_function

import logging

import json
import sys
import tempfile
import shutil
import ast
import re

from collections import defaultdict

from . import open
from . import RomError


_log = logging.getLogger(__name__)


def _int(s):
    return int(ast.literal_eval(s))


def _expandWriteVals(ss):
    """Convert string 'n,m,l,k,...' into list of ints [n, m, l, k, ...]
    Raise Exception if not all items separated by commas can be interpreted as integers."""
    if ',' not in ss:
        return _int(ss)
    vals = [_int(x) for x in ss.split(',')]
    return vals


def parseTransaction(xact):
    """
    Parse transaction string from CLI.  Returns (str/int reg, int offset, int/None size, int/None write_val)
    If 'reg' is type int, it is an explicit base address.
        If 'size' is None, size = 1
    If 'reg' is type str, it is a register name (supposedly).
        If 'size' is None, size = 2**aw (where 'aw' is the 'addr_width' from the romx JSON)
    If 'write_val' is None, it's a read transaction, else it's a write of value 'write_val'
    Viable formats for a transaction (read/write) in string form:
        Example                 Implied Transaction
        -------------------------------------------
        regname                 Read from named register (str) 'regname'
        regaddr                 Read from explicit address (int) 'regaddr'
        regname=val             Write (int) 'val' to named register (str) 'regname'
        regaddr=val             Write (int) 'val' to explicit address (int) 'regaddr'
        regname=val0,...,valN   Write (int) 'val0' through 'valN' to consecutive addresses beginning at the
                                address of named register (str) 'regname'
        regaddr=val0,...,valN   Write (int) 'val0' through 'valN' to consecutive addresses beginning at
                                address (int) 'regaddr'
        regname+offset          Read from address = romx['regname']['base_addr'] + (int) 'offset'
        regaddr+offset          Read from address = (int) 'regaddr' + (int) 'offset'
        regname:size            Read (int) 'size' elements starting from address romx['regname']['base_addr']
        regaddr:size            Read (int) 'size' elements starting from (int) 'regaddr'
        regname+offset=val      Write (int) 'val' to address romx['regname']['base_addr'] + (int) 'offset'
        regname+offset=val0,...,valN    Write (int) 'val0' through 'valN' to consecutive addresses beginning at
                                        address romx['regname']['base_addr'] + (int) 'offset'
        regaddr+offset=val      Write (int) 'val' to address (int) 'regaddr' + (int) 'offset'
        regaddr+offset=val0,...,valN    Write (int) 'val0' through 'valN' to consecutive addresses beginning at
                                        address (int) 'regaddr'
        regname+offset:size     Read (int) 'size' elements starting from address romx['regname']['base_addr'] + \
                                (int) 'offset'
        regaddr+offset:size     Read (int) 'size' elements starting from (int) 'regaddr' + (int) 'offset'
    I'm not sure what use case the "regaddr+offset" syntax supports, but it does no harm to include it.
    NOTE! Deliberately not supporting "regname-offset" (negative offsets) as it's use case is unclear
    and a '_' to '-' typo could potentially collide with legitimate transactions.
    """
    restr = r"(\w+)\s*([=+:])?\s*([0-9a-fA-Fx,\-]+)?\s*([=:])?\s*([0-9a-fA-Fx,\-]+)?"
    _match = re.match(restr, xact)
    offset = 0
    wval = None
    size = None
    if _match:
        groups = _match.groups()
        regstr = groups[0]  # Always starts with 'regname' or 'regaddr'
        if groups[1] == '=':
            wval = _expandWriteVals(groups[2])
        elif groups[1] == '+':
            offset = _int(groups[2])
        elif groups[1] == ':':
            size = _int(groups[2])
        if groups[3] == '=':
            if groups[1] == '=':
                raise Exception("Malformed transaction: {}".format(xact))
            wval = _expandWriteVals(groups[4])
        elif groups[3] == ':':
            if size is not None:
                raise Exception("Malformed transaction: {}".format(xact))
            size = _int(groups[4])
    else:
        raise Exception("Failed to match: {}".format(xact))
    try:
        reg = _int(regstr)
    except ValueError:
        reg = regstr
    if size is None:
        if wval is None:
            size = None
        else:
            size = 0
    return (reg, offset, size, wval)


def readwrite(args, dev):
    for xact in args.reg:
        reg, offset, size, wvals = parseTransaction(xact)
        if wvals is not None:
            dev.reg_write_offset([(reg, wvals, offset)])
        else:
            value, = dev.reg_read_size(((reg, size, offset),))
            try:
                _ = iter(value)
                print("%s \t%s" % (reg, ' '.join(['%x' % v for v in value])))
            except TypeError:
                print("%s \t%x" % (reg, value))


def listreg(args, dev):
    regs = list(dev.regmap)
    regs.sort()
    for reg in regs:
        print(reg)


def acquire(args, dev):
    if args.plot:
        from matplotlib import pylab
        pylab.figure()
    dev.set_channel_mask(args.channels)
    if dev.backend == 'ca':
        dev.pv_write('circle_data', 'acqmode', 'Normal', wait=False)
    dev.wait_for_acq(tag=args.tag, toggle_tag=args.toggle)
    for T, ch in zip(dev.get_timebase(args.channels),
                     dev.get_channels(args.channels)):
        if args.plot:
            pylab.plot(T, ch)
            pylab.hold(True)
        else:
            print(' '.join(map(str, ch)))
    if args.plot:
        pylab.show()


def decimate(args, dev):
    dev.set_decimate(args.div)


def dumpaddrs(args, dev):
    regs = []
    for reg, info in dev.regmap.items():
        if 'r' in info.get('access', ''):
            regs.append(reg)

    values = dev.reg_read(regs, instance=None)
    addrs = []
    for name, value in zip(regs, values):
        info = dev.get_reg_info(name, instance=None)
        base = info['base_addr']
        if isinstance(base, (bytes, str)):
            base = int(base, 0)
        if info.get('addr_width', 0) == 0:
            # scalar
            addrs.append((base, value & 0xffffffff))
        else:
            # vector
            for pair in enumerate(value & 0xffffffff, base):
                addrs.append(pair)

    # sort by address increasing
    addrs.sort(key=lambda pair: pair[0])

    for addr, value in addrs:
        if value == 0 and args.ignore_zeros:
            continue
        print("%08x %08x" % (addr, value))


def dumpjson(args, dev):
    json.dump(dev.regmap, sys.stdout, indent=2)
    sys.stdout.write('\n')


def dumpgitid(args, dev):
    print(dev.codehash)


def dumpdescript(args, dev):
    print(dev.descript)


def dumpdrv(args, dev):
    if dev.backend != 'ca':
        _log.error("Only 'ca' backend supports, not '%s'", dev.backend)
        sys.exit(1)
    json.dump(dev._info, sys.stdout, indent=2)
    sys.stdout.write('\n')


class MapDirect(object):

    def __call__(self, name):
        return 'reg_' + name


class MapPlain(object):

    def __call__(self, name):
        return name


class MapShort(object):

    def __init__(self):
        self._next = 0

    def __call__(self, name):
        N, self._next = self._next, self._next + 1
        return 'REG%x' % N


def gentemplate(args, dev):
    mapper = {
        'short': MapShort,
        'long': MapDirect,
        'plain': MapPlain,
    }[args.mode]()

    files = defaultdict(list)
    for name, info in dev.regmap.items():
        if len(name) == 0:
            _log.warn("Zero length register name")
            continue
        elif name == '__metadata__':
            continue
        components = {
            'access': info.get('access', ''),
            'type': 'scalar' if info.get('addr_width', 0) == 0 else 'array',
        }
        values = {
            'name': name,
            'pv': mapper(name),
            'size': 1 << info.get('addr_width', 0),
        }
        values.update(info)

        name = 'feed_reg_%(access)s_%(type)s.template' % components

        files[name].append(values)

    # sort to get stable output order
    files = list(files.items())
    files.sort(key=lambda i: i[0])

    out = tempfile.NamedTemporaryFile('r+')
    out.write('''# Generated from
# FW: %s
# JSON: %s
# Code: %s
# Name Mode: -M %s

''' % (dev.descript, dev.jsonhash, dev.codehash, args.mode))

    out.write('file "feed_base.template"\n{\n{PREF="$(CHAS):CTRL_"}\n}\n\n')

    for fname, infos in files:
        out.write('file "%s"\n{\n' % fname)

        infos.sort(key=lambda i: i['pv'])

        for info in infos:
            s = '{PREF="$(CHAS):%(pv)s",'
            s += '\tREG="%(name)s",'
            s += '\tSIZE="%(size)s"}\n'
            out.write(s % info)

        out.write('}\n\n')

    out.flush()
    out.seek(0)
    if args.output == '-':
        sys.stdout.write(out.read())
    else:
        shutil.copyfile(out.name, args.output)


def getargs():
    from argparse import ArgumentParser
    P = ArgumentParser()
    P.add_argument('-d', '--debug', action='store_const',
                   const=logging.DEBUG, default=logging.INFO)
    P.add_argument('-q', '--quiet', action='store_const',
                   const=logging.WARN, dest='debug')
    P.add_argument('-t', '--timeout', type=float, default=5.0)
    P.add_argument('-i', '--inst', action='append', default=[])
    P.add_argument('dest', metavar="URI",
                   help="Server address.  ca://Prefix or leep://host[:port]")
    P.set_defaults(func=lambda args, dev: None)

    SP = P.add_subparsers()

    S = SP.add_parser('reg', help='read/write registers')
    S.set_defaults(func=readwrite)
    S.add_argument('reg', nargs='+', help="register[=newvalue]")

    S = SP.add_parser('acquire', help='Waveform acquisition')
    S.set_defaults(func=acquire)
    S.add_argument('-t', '--tag', action='store_true', default=False,
                   help='Increment tag and wait for acquisition w/ new tag')
    S.add_argument('-T', '--toggle', action='store_true', default=False,
                   help='Increment tag and wait for acquisition w/ new tag')
    S.add_argument('-P', '--plot', action='store_true', default=False,
                   help='Plot acquired data with matplotlib')
    S.add_argument('channels', nargs='+', type=int, help='Channel numbers')

    S = SP.add_parser('decim', help='Set decimation')
    S.add_argument('div', type=int, help='division factor [1, 255]')
    S.set_defaults(func=decimate)

    S = SP.add_parser('list', help='list registers')
    S.set_defaults(func=listreg)

    S = SP.add_parser('dump', help='dump registers')
    S.add_argument('-Z', '--ignore-zeros', action='store_true',
                   help="Only print registers with non-zero values")
    S.set_defaults(func=dumpaddrs)

    S = SP.add_parser('json', help='print json')
    S.set_defaults(func=dumpjson)

    S = SP.add_parser('gitid', help='print gitid')
    S.set_defaults(func=dumpgitid)

    S = SP.add_parser('descript', help='print descript')
    S.set_defaults(func=dumpdescript)

    S = SP.add_parser('drvinfo', help='print drive info json (ca:// only)')
    S.set_defaults(func=dumpdrv)

    S = SP.add_parser('template', help='Generate MSI substitutions file')
    S.set_defaults(func=gentemplate)
    S.add_argument('output', help='Output file')
    S.add_argument('-M', '--mode', default='long',
                   help='Record naming mode: long (default), short, plain')
    S.add_argument('--short', action='store_const', const='short',
                   dest='mode', help='Alias for -M short')

    return P.parse_args()


def main():
    args = getargs()
    logging.basicConfig(level=args.debug)
    try:
        dev = open(args.dest, timeout=args.timeout, instance=args.inst)
    except RomError as e:
        _log.error("cli.py: %s, %s. Quitting." % (args.dest, str(e)))
        return

    args.func(args, dev)


if __name__ == '__main__':
    main()
