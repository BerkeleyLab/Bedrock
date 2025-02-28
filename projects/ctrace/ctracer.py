#! /usr/bin/python3

import sys
import re
import math
import ctconf

COMPRESS_GETLISTS = True

_config = None


def getConfig():
    return _config


class CtraceParser:
    # Some special identifier that should hopefully never collide with a real one
    _clk_id = "zzz"

    @classmethod
    def handle_ignores(cls, signal_name):
        """Ignore any constant '0' or '1' signals."""
        ignores = {
            "0": "ZERO",
            "1": "ONE",
            r"[01]\[\d+\]": "ZERO",  # Matches 0/1 followed by an index (e.g. 0[5])
        }
        ignore = False
        # Handle replacements/ignores
        for name, replacement in ignores.items():
            if re.match(name, signal_name):
                ignore = True
                signal_name = replacement
                break
        return ignore, signal_name

    @staticmethod
    def _id(ix):
        """Convert an index to an identifier string"""
        if ix < 26:
            return chr(ord("a") + ix)
        else:
            iy = (ix // 26) - 1
            ix = ix % 26
            return chr(ord("a") + iy) + chr(ord("a") + ix)

    @staticmethod
    def _getRoot(name):
        """Return the signal name without any anteceding bit/range selection."""
        res = r"([a-zA-z_.]+)(\[[0-9:]+\]?)"
        _match = re.match(res, name)
        if _match:
            groups = _match.groups()
            return (groups[0], groups[1])
        return (name, "")

    @staticmethod
    def _width(_range):
        """Get the width associated with range '_range' (which should be a string
        '[low:high]', '[high:low]', or '[index]').
        The width assumes Verilog rules where both indices are included (i.e. [7:0]
        yields width 8) rather than Python rules where the high index is not included.
        """
        srange = str(_range)
        res = r"\[([0-9:]+)\]?"
        _match = re.match(res, srange)
        if _match:
            srng = _match.groups()[0]
            if ":" in srng:
                x, y = srng.split(":")
                x = _int(x)
                y = _int(y)
                rval = max(x, y) - min(x, y) + 1
                # print(f"  {_range} => {rval}")
                return rval
            else:
                # print(f"  {_range} => 1")
                return 1
        # print(f"  {_range} => 0")
        return 0

    @staticmethod
    def _extends(srange, sindex):
        """If the index represented by string 'sindex' extends the range represented
        by string 'srange', returns the extended range as a string.  Otherwise, returns
        None. By 'extends' we mean that for range=[high:low], index is high+1 or low-1.
        """
        res = r"\[([0-9:]+)\]"
        _match = re.match(res, sindex)
        if not _match:
            return None
        i = _int(_match.groups()[0])
        _match = re.match(res, srange)
        if (i is not None) and _match:
            srng = _match.groups()[0]
            # print(f"match: i = {i}")
            if ":" in srng:
                x, y = srng.split(":")
                x = _int(x)
                y = _int(y)
                # print(f"x = {x}, y = {y}")
                _min = min(x, y)
                _max = max(x, y)
                if i == _min - 1:
                    return "[{}:{}]".format(_max, i)
                elif i == _max + 1:
                    return "[{}:{}]".format(i, _min)
            else:
                x = _int(srng)
                # print(f"x = {x}")
                if abs(i - x) == 1:
                    return "[{}:{}]".format(max(i, x), min(i, x))
        return None

    @staticmethod
    def _extractValue(val, *args):
        """Extract a value from 'val' by summing the contributions from various bits in any order.
        args = [(valIndex, shift), ...]
        The 'valIndex' is the bit number of the value to use and 'shift' is the amount by which
        the bit should be left-shifted and summed with the rest.
        """
        result = 0
        for arg in args:
            valih, valil, shift = arg
            mask = (1 << (valih + 1)) - 1
            result += ((val & mask) >> valil) << shift
        return result

    @staticmethod
    def _index(sindex):
        """Get the index (as an int) represented by string 'sindex' in the form '[x]' where
        'x' is the resulting index."""
        srange = str(sindex)
        res = r"\[([0-9]+)\]"
        _match = re.match(res, srange)
        if _match:
            ix = _int(_match.groups()[0])
            return ix
        return 0

    def __init__(self, signals=[], timebits=24, mtime=64, dw=None, wide=False, clk_name=None):
        self.signals = signals
        self.sigdict = self._mkSigDict(signals)
        # import jbrowse
        # print(jbrowse.strDict(self.sigdict))
        if dw is not None:
            self.dw = dw
        else:
            self.dw = len(self.signals)
        self.tw = timebits
        # mtime is the time delay to assume if a dt of 0 is parsed from the data
        self.mtime = mtime
        self.ignores = []
        self._timemask = ((1 << (self.dw + self.tw)) - 1) << self.dw
        self._timeshift = self.dw
        self._datamask = (1 << self.dw) - 1
        self._datashift = 0
        self._wide = wide
        self._buswidth = self.dw + self.tw
        self._last_stage = math.ceil(self._buswidth / 32) - 1
        self._stage_width = math.ceil(math.log2(self._last_stage + 1))
        self._total_stages = 1 << self._stage_width
        self._clk_name = clk_name
        if clk_name is not None:
            self._include_clock = True
        else:
            self._include_clock = False

    def _doMergeSignals(self, signals):
        """Perform one round of merging signals with identical names and adjacent bounds
        into a larger vector.  This function should be called until its first return value
        is False (meaning no more merges can take place)."""
        _signals = []
        didMerge = False
        for signame, sigwidth, _id, getList in signals:
            # print(f"\nConsidering {signame}")
            thisRoot, thisRange = self._getRoot(signame)
            n = 0
            result = None
            _getList = []
            while n < len(_signals):
                _signame, _w, _id, _getList = _signals[n]
                thatRoot, thatRange = self._getRoot(_signame)
                if thisRoot == thatRoot:
                    # print(f"  Hit {thisRoot} with {_signame}")
                    result = self._extends(thatRange, thisRange)
                    if result is not None:
                        break
                n += 1
            if result is not None:
                # Extend the existing entry
                _width = self._width(result)
                getList.extend(_getList)
                _signals[n] = [thisRoot + result, _width, None, getList]
                # print(f"  Extending {_signame} with {result}, width = {_width}")
                didMerge = True
            else:
                # print(f"  Adding unique signal {signame}")
                # Add the signal
                _signals.append([signame, sigwidth, None, getList])
        return didMerge, _signals

    @staticmethod
    def doMergeGetList(getList):
        """Do one round of merging of bit positions and shifts into bit ranges and shifts.
        Reduces the processing time for each entry in the waveform extraction portion of
        the VCD creation.  This is not very important for the VCD file creation step
        (which is not time-sensitive), but could improve throughput for any 'live' GUI
        front-ends who display waveforms as they're fetched."""
        didMerge = False
        for n in range(len(getList)):
            if getList[n] is None:
                continue
            bith, bitl, shift = getList[n]
            width = bith - bitl + 1
            newEntry = getList[n]
            for m in range(n + 1, len(getList)):
                if getList[m] is None:
                    continue
                _bith, _bitl, _shift = getList[m]
                _width = (_bith - _bitl) + 1
                # Conditions for merging?
                condA = (_bith == bitl - 1) and (
                    shift == _shift + _width
                )  # _ is just below
                condB = (_bitl == bith + 1) and (
                    _shift == shift + width
                )  # _ is just above
                if condA:
                    newbith = bith
                    newbitl = _bitl
                    newshift = _shift
                elif condB:
                    newbith = _bith
                    newbitl = bitl
                    newshift = shift
                # else:
                #    print(f"Don't merge {m} with {n}; {_shift} == {shift-_width}? {_shift} == {shift+_width}?")
                if condA or condB:
                    # print(f"merging {m} with {n}; {_shift} == {shift-_width}? {_shift} == {shift+_width}?")
                    # modify in place
                    didMerge = True
                    newEntry = (newbith, newbitl, newshift)
                    getList[n] = newEntry
                    getList[m] = None
                    break
        n = 0
        while n < len(getList):
            if getList[n] is None:
                del getList[n]
            else:
                n += 1
        return didMerge, getList

    def _mkSigDict(self, signals=[]):
        """Make a dict structure of the ordered signal list given by 'signals'.
        Note that the index of the signal is taken by its position in arg 'signals'
        so it should not be filtered or pre-processed before this function.
        This function actually makes two structures, the first of which is returned
        and used once while the second is stored and used while processing
        signals in the data dump section.
            structure dict (returned):
                A nested dict collecting signals by scope hierarchy.  At each scope
                level, there's a dict of the form:
                    {"signals" : [], "scopes": {}}
            structure list (stored):
                A 2D list (list of lists) with each element being of the form:
                    [name, width, id, getList]
                Where 'name' is the signal name, 'width' is the number of bits in
                the signal, 'id' is the internally-used identifier string in the
                VCD file, and 'getList' is a list of bit positions and shifts used
                in extracting the signal's value from the ctrace memory entries.
        """
        # print(f"signals = {signals}")
        dd = {
            "signals": [],
            "scopes": {},
        }
        _signals = []
        self.ignores = []
        # First filter out any signals we don't want and prep the nested list
        for n in range(len(signals)):
            signame = signals[n]
            ignore, signame = self.handle_ignores(signame)
            if ignore:
                self.ignores.append(signame)
                continue
            root, _range = self._getRoot(signame)
            shift = self._index(_range)
            _signals.append([signals[n], 1, None, [(n, n, shift)]])
        # Now let's group into vectors
        merged = True
        while merged:
            merged, _signals = self._doMergeSignals(_signals)
        # Then adjust the getLists by the lowest index of the vector
        for n in range(len(_signals)):
            signal, width, _id, getList = _signals[n]
            shifts = [x[2] for x in getList]
            minShift = min(shifts)
            for m in range(len(getList)):
                bith, bitl, shift = getList[m]
                getList[m] = (bith, bitl, shift - minShift)
            if COMPRESS_GETLISTS:
                # Compress the getList as much as possible
                merged = True
                while merged:
                    merged, getList = CtraceParser.doMergeGetList(getList)
            _signals[n][3] = getList
        # Then split into scopes
        for ix in range(len(_signals)):
            signal, width, _id, getList = _signals[ix]
            _signals[ix][2] = self._id(ix)
            names = signal.split(".")
            dscope = dd
            if len(names) > 1:
                for scope in names[0:-1]:
                    if scope in dscope["scopes"].keys():
                        dscope = dscope["scopes"][scope]
                    else:
                        dscope["scopes"][scope] = {"signals": [], "scopes": {}}
                        dscope = dscope["scopes"][scope]
                # print("Adding {} ({}) to {} ===> {}".format(names[-1], ix, scope, dscope))
                dscope["signals"].append((ix, names[-1], width))
            else:
                # print("Adding {} ({}) to TOP".format(names[-1], ix))
                dscope["signals"].append((ix, names[-1], width))
        # print(_signals)
        self._sigList = _signals
        return dd

    def _walkScopeDefine(self):
        """Walk the scope dict generated by _mkSigDict() and define scopes and signals
        in VCD format."""
        ss = ["$scope module TOP $end"]
        if self._include_clock:
            ss.append("$var wire 1 {:s} {:s} $end".format(self._clk_id, self._clk_name))
        dscope = self.sigdict.copy()  # We'll do a destructive walk
        parents = []
        scopename = "TOP"
        while dscope is not None:
            for ix, name, width in dscope["signals"]:
                ignore, name = self.handle_ignores(name)
                if not ignore:
                    ss.append(
                        "$var wire {} {:s} {:s} $end".format(width, self._id(ix), name)
                    )
                else:
                    self.ignores.append(ix)
            # Done with these signals, so clobber them
            dscope["signals"] = []
            scopes = dscope["scopes"]
            if len(scopes.keys()) > 0:
                # Go down a scope
                parents.append((scopename, dscope))
                # Wasteful way to get whatever is first.  A better way?
                # We'll delete as we're finished
                scopename, dscope = [x for x in scopes.items()][0]
                ss.append("$scope module {} $end".format(scopename))
            else:
                # Go up a scope
                ss.append("$upscope $end")
                if len(parents) == 0:
                    # Done
                    break
                else:
                    new_scopename, dscope = parents.pop()
                    # Remove the parsed scope from the dict
                    try:
                        dscope["scopes"].pop(scopename)
                        # print("popped {} from {}".format(scopename, dscope))
                    except KeyError:
                        print(
                            "key {} not found in {}".format(scopename, dscope["scopes"])
                        )
                    scopename = new_scopename
        return ss

    def VCDMakeHeader(self, initVal):
        putc = [
            "$date March 27, 2020. $end",
            "$version CtraceParser $end",
            "$timescale 1ns $end",
        ]
        putc += self._walkScopeDefine()
        putc += [
            "$enddefinitions $end",
            "$dumpvars",
        ]
        for n in range(len(self._sigList)):
            signal, width, _id, getList = self._sigList[n]
            val = self._extractValue(initVal, *getList)
            self.old_vals[n] = val
            putc.append("b{:b} {:s}".format(val, _id))
        if self._include_clock:
            putc.append("b0 {:s}".format(self._clk_id))
        putc.append("$end")
        return "\n".join(putc)

    def VCDEmitStep(self, v, time):
        """Write a signal line of the dumpvars section of the VCD file."""
        putc = []
        putc.append("#{:d}".format(int(time)))
        for n in range(len(self._sigList)):
            signal, width, _id, getList = self._sigList[n]
            val = self._extractValue(v, *getList)
            old_val = self.old_vals[n]
            self.old_vals[n] = val
            if (old_val is None) or (val != old_val):
                putc.append("b{:b} {:s}".format(val, _id))
        putc = "\n".join(putc) + "\n"
        return putc

    def VCDMake(self, ofile=None, time_step_ns=8):
        """Create a VCD file with name 'ofile' using time step 'time_step_ns' (the minimum time
        difference in nanoseconds; the period of the clock used by ctrace)."""
        # 50 MHz and ns time step means multiply integer time count by 20
        t_step = float(time_step_ns)  # ns tick in simulation
        if ofile is None:
            ofile = sys.stdout
        time = 0
        self.first = True
        self.old_vals = [None] * len(self._sigList)
        # print(f"len(self.wfm) = {len(self.wfm)}")
        # print(f"len(self._sigList) = {len(self._sigList)}")
        with open(ofile, "w") as fd:
            for dt, v in self.wfm:
                if self.first:
                    putc = self.VCDMakeHeader(v)
                    self.first = False
                    fd.write(putc + "\n")
                    if self._include_clock:
                        fd.write("#0\n")  # Is there a better way to do this?
                    continue
                if dt == 0:
                    dt = self.mtime
                if self._include_clock:
                    tclk = []
                    # Insert dt toggling events for the clock
                    for n in range(int(dt)):
                        tclk.append("b1 {:s}".format(self._clk_id))
                        tclk.append("#{}".format((time + n + 0.5)*t_step))
                        tclk.append("b0 {:s}".format(self._clk_id))
                    fd.write("\n".join(tclk) + "\n")
                time += dt
                print(f"time = {time}; dt = {dt}")
                putc = self.VCDEmitStep(v, time * t_step)
                fd.write(putc)
        return

    def splitTimeData(self, datum):
        """Split one entry from ctrace memory into time and data portions."""
        datum = int(datum)
        time = (datum & self._timemask) >> self._timeshift
        data = (datum & self._datamask) >> self._datashift
        # print(f"datum = 0x{datum:x}; time = 0x{time:x}, data = 0x{data:x}")
        return time, data

    def parseDumpFile(self, delimiter=",", ishex=True):
        """Parse input plaintext file.
        Data is assumed to be separated by 'delimiter'.
        If 'ishex', data is interpreted as hexadecimal,
        otherwise as decimal. Ain't messing with binary."""
        self.wfm = []
        if ishex:
            base = 16
        else:
            base = 10
        with open(self.ifile, "r") as fd:
            line = fd.readline()
            # for line in f.read().split('\n'):
            while line:
                data = line.split(delimiter)
                for datum in data:
                    datum = int(datum, base)
                    time, data = self.splitTimeData(datum)
                    self.wfm.append([time, data])
        return

    def parseDump(self, dumplist, signals=[], storeFile=None):
        """Parse a raw ctrace memory dump into a waveform for further
        processing (e.g. making into a VCD file)."""
        self.wfm = []
        _data = 0
        # print(f"len(dumplist) = {len(dumplist)}")
        # print(f"self._last_stage = {self._last_stage}")
        # print(f"self._total_stages = {self._total_stages}")
        for n in range(len(dumplist)):
            datum = dumplist[n]
            stage = n % self._total_stages
            if stage == 0:
                _data = datum
            elif stage <= self._last_stage:
                _data += datum << (stage * 32)
            if stage == self._last_stage:
                time, data = self.splitTimeData(_data)
                self.wfm.append([time, data])
        if storeFile is not None:
            import pickle

            with open(storeFile, "wb") as fd:
                storedict = {}
                storedict["signals"] = signals
                storedict["data"] = dumplist
                pickle.dump(storedict, fd)
        return


def _int(x):
    try:
        return int(x)
    except ValueError:
        pass
    try:
        return int(x, 16)
    except ValueError:
        return None


def test_mkSigDict(argv):
    signals = [
        "foo",
        "bar[2]",
        "bar[5]",
        "bar[3]",
        "bar[4]",
    ]
    CtraceParser(signals)
    return


def test_doMergeGetList():
    # Let's say we have the following:
    #           LSb                              MSb
    #   mem = [vec[4], vec[5], vec[1], vec[2], vec[3]]
    getList = [
        # (h, l, s)
        (0, 0, 4),
        (1, 1, 5),
        (2, 2, 1),
        (3, 3, 2),
        (4, 4, 3),
    ]
    merged = True
    print(f"START: {getList}")
    while merged:
        merged, getList = CtraceParser.doMergeGetList(getList)
        if merged:
            print(f"Merge: {getList}")
    print(f"DONE:  {getList}")
    return


def testVCDMake(argv):
    if len(argv) > 1:
        import pickle

        fname = argv[1]
        with open(fname, "rb") as fd:
            testdict = pickle.load(fd)
        signals = testdict["signals"]
        testdata = testdict["data"]
        wide = True
        dw = 40
    else:
        from d import signals, testdata

        wide = True
        dw = None
    ctp = CtraceParser(signals, timebits=24, mtime=100, dw=dw, wide=wide)
    ctp.parseDump(testdata)
    outfname = "foo.vcd"
    ctp.VCDMake(outfname, time_step_ns=10)
    print("Wrote to {}".format(outfname))
    return True


def picklePy(fname):
    import pickle

    with open(fname, "rb") as fd:
        testdict = pickle.load(fd)
    signals = testdict["signals"]
    testdata = testdict["data"]
    print(f"signals={signals}")
    print(f"testdata={testdata}")
    return


def test(s):
    dw = _int(s)
    tw = 24
    _timemask = ((1 << (dw + tw)) - 1) << dw
    _timeshift = dw
    _datamask = (1 << dw) - 1
    _datashift = 0

    def splitTimeData(datum):
        """Split one entry from ctrace memory into time and data portions."""
        time = (datum & _timemask) >> _timeshift
        data = (datum & _datamask) >> _datashift
        return time, data

    _buswidth = dw + tw
    _last_stage = math.ceil(_buswidth / 32) - 1
    _stage_width = math.ceil(math.log2(_last_stage + 1))
    _total_stages = 1 << _stage_width
    print(
        f"buswidth = {_buswidth}; last_stage = {_last_stage}; stage_width = {_stage_width};" +
        f" total_stages = {_total_stages}"
    )
    data = [
        0x01020304,
        0x05060708,
        0x090A0B0C,
        0x0D0E0F00,
        0x11121314,
        0x15161718,
        0x191A1B1C,
        0x1D1E1F10,
    ]
    _data = 0
    for n in range(len(data)):
        datum = data[n]
        stage = n % _total_stages
        if stage == 0:
            _data = datum
            print(f"  {n}: {stage}: _data = datum = {_data:x}")
        elif stage < _last_stage:
            _data += datum << (stage * 32)
            print(f"  {n}: {stage}: _data += datum << 32 = {_data:x}")
        if stage == _last_stage:
            __time, __data = splitTimeData(_data)
            print(
                f"    PARSE: stage {stage} _data = {_data:x}; time = {__time}; data = {__data}"
            )
    return


PROTO_SCRAP = 0
PROTO_LEEP = 1


def _parseProtocol(s):
    # Test for explicit protocol
    if ":" in s:
        splits = s.split(":")
        proto = splits[0].lower()
        if proto == "scrap":
            return PROTO_SCRAP, "".join(splits[1:])
        elif proto == "udp":
            return PROTO_SCRAP, "".join(splits)
        elif proto == "leep" or proto == "ca":
            return PROTO_LEEP, s
    # Serial devices go to SCRAP
    if s.startswith("/dev"):
        return PROTO_SCRAP, s
    # IPs go to LEEP by default (unless prepended with 'scrap' or 'udp')
    return PROTO_LEEP, s


def _mkFilename(fname, dest):
    if fname is not None:
        return fname
    fname = fname.replace(".", "")
    fname = dest.replace(":", ".")
    fname = fname.replace("/", "_")
    return fname + ".vcd"


def getCtraceMem(dev, size):
    config = getConfig()
    if size is None:
        size = 1 << config.CTRACE_AW
    if size <= 0:
        return []
    rdata = dev.reg_read_size(((config.CTRACE_MEM, size),))[0]
    return rdata


def runCtrace(dev, runtime=10, xacts=[]):
    import time
    config = getConfig()

    # Collect intermediary transactions
    reg_vals = []
    if xacts is None:
        xacts = []
    for xact in xacts:
        # TODO - Use the transaction parsing in leep.cli
        if '=' in xact:
            reg, val = xact.split('=')[:2]
            val = _int(val)
            reg_vals.append((reg, val))
            print(f"{reg} -> {val}")
        else:
            print(f"Ignoring intermediary read: {xact}")

    # Start ctrace
    print("Running ctrace...")
    dev.reg_write([(config.CTRACE_START_REG, 1)])
    # Perform intermediary transactions
    if len(reg_vals) > 0:
        dev.reg_write(reg_vals)
    # Wait for ctrace to complete
    wait = int(runtime)
    while wait:
        rdata = dev.reg_read((config.CTRACE_RUNNING_REG,))[0]
        if not rdata:
            break
        time.sleep(1.0)
        wait -= 1
    if wait:
        # Ctrace not running (finished), read entire memory
        print("Done")
        return 1 << config.CTRACE_AW
    mem_size = dev.reg_read((config.CTRACE_PCMON_REG,))[0]
    return mem_size


def doScope(dev, ofile, run=True, runtime=10, clk_name=None, xacts=[], storeFile=None):
    config = getConfig()
    ctrace_chan0 = config.CTRACE_CHAN0
    signals = []
    for nch in range(config.CTRACE_DW):
        ch = ctrace_chan0 + nch
        label = config.get(ch, "ctrace_data[{}]".format(ch))
        signals.append(label)
    # Next run ctrace, if requested
    readout_size = 1 << config.CTRACE_AW
    if run:
        readout_size = runCtrace(dev, runtime=runtime, xacts=xacts)
        if readout_size is None:
            print("doScope runCtrace failed")
            return False
    # Next read the ctrace memory
    if readout_size == 0:
        print("ctrace memory is empty")
        return False
    print("Reading ctrace memory (size={})".format(readout_size))
    data = getCtraceMem(dev, size=readout_size)
    ctp = CtraceParser(signals, dw=config.CTRACE_DW, timebits=config.CTRACE_TW, clk_name=clk_name)
    ctp.parseDump(data, signals=signals, storeFile=storeFile)
    time_step_ns = 1.0e9 / config.F_CLK_IN
    ctp.VCDMake(ofile, time_step_ns=time_step_ns)
    print(f"Ctrace waveforms written to {ofile}")
    return True


def doGet(args):
    proto, dest = _parseProtocol(args.dest)
    filename = _mkFilename(args.outfile, dest)
    if proto == PROTO_LEEP:
        import leep
        dev = leep.open(dest, timeout=args.timeout)
    elif proto == PROTO_SCRAP:
        import scrap
        dev = scrap.SCRAPDevice(dest, silent=True)
    else:
        raise Exception("Unsupported protocol {}".format(proto))
    return doScope(dev, filename, run=True, runtime=args.runtime, clk_name=args.clk,
                   xacts=args.xact, storeFile=args.store_file)


def doParse(args):
    import pickle
    config = getConfig()
    with open(args.file, "rb") as fd:
        memdump = pickle.load(fd)
    signals = memdump["signals"]
    data = memdump["data"]
    ctp = CtraceParser(signals, dw=config.CTRACE_DW, timebits=config.CTRACE_TW, clk_name=args.clk)
    ctp.parseDump(data, signals=signals)
    time_step_ns = 1.0e9 / config.F_CLK_IN
    ctp.VCDMake(args.outfile, time_step_ns=time_step_ns)
    print(f"Ctrace waveforms written to {args.outfile}")
    return True


def main():
    import argparse

    parser = argparse.ArgumentParser("Host-side interaction with (w)ctrace module.")
    parser.set_defaults(handler=lambda args: None)
    subparsers = parser.add_subparsers(help="Subcommands")
    parserGet = subparsers.add_parser(
        "get", help="Get ctrace memory and generate VCD file"
    )
    devhelp = "Device to interface with. E.g.\n  leep://$IP[:$PORT]\n  scrap:/dev/ttyUSB3\n  scrap:$IP:$PORT"
    parserGet.add_argument("dest", help=devhelp)
    parserGet.add_argument("-c", "--config", default=None, help="Configuration file.")
    parserGet.add_argument("-x", "--xact", action="append",
                           help="Transactions to do after issuing the 'start' signal (regname=val).")
    parserGet.add_argument("--clk", default=None, help="Net name for the generated clock.")
    parserGet.add_argument("-o", "--outfile", default=None, help="Output VCD file name.")
    parserGet.add_argument("-t", "--timeout", type=float, default=5.0)
    parserGet.add_argument("-r", "--runtime", default=10, type=float,
                           help="Time (in seconds) to wait for ctrace to complete.")
    parserGet.add_argument("-s", "--store_file", default=None,
                           help="File in which to store raw dump.")
    parserGet.set_defaults(handler=doGet)
    parserParse = subparsers.add_parser(
        "parse", help="Generate VCD file from a pickled dump of ctrace memory"
    )
    parserParse.add_argument("file", help="Ctrace memory dump file (pickled)")
    parserParse.add_argument("-o", "--outfile", default=None, help="Output VCD file name.")
    parserParse.add_argument("-c", "--config", default=None, help="Configuration file.")
    parserParse.add_argument("--clk", default=None, help="Net name for the generated clock.")
    parserParse.set_defaults(handler=doParse)
    args = parser.parse_args()
    global _config
    _config = ctconf.Config(args.config)
    return args.handler(args)


if __name__ == "__main__":
    # testVCDMake(sys.argv)
    # picklePy(sys.argv[1])
    # print(CtraceParser._getRoot(sys.argv[1]))
    # test_mkSigDict(sys.argv)
    # test(sys.argv[1])
    # test_doMergeGetList()
    main()
