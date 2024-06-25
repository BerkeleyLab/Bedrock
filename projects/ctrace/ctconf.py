# Configuration for ctraceparser.py

import re

SYNTAX_VERILOG=0
SYNTAX_PYTHON=1
SYNTAX_ANY=0xf

def _int(x):
    try:
        return int(x)
    except ValueError:
        pass
    try:
        return int(x, 16)
    except ValueError:
        return None

class Config():
    _paramdict = {
        # Generic
        "F_CLK_IN": 125.0e6,
        "CTRACE_DW": 14,
        "CTRACE_AW": 10,
        "CTRACE_TW": 24,
        "CTRACE_MEM_SIZE": (1<<10),
        # SCRAP-specific
        "CTRACE_CHAN0": 0,
        "CTRACE_OFFSET": 0x1000,
        "CTRACE_START_ADDR": 0,
        "CTRACE_RUNNING_ADDR": 1,
        "CTRACE_PCMON_ADDR": 2,
        # LEEP-specific
        "CTRACE_MEM": "ctrace_lb_dout",
        "CTRACE_START_REG": "ctrace_trigger",
        "CTRACE_RUNNING_REG": "ctrace_running",
        "CTRACE_PCMON_REG": "ctrace_pc_mon",
    }

    def __init__(self, filename=None):
        # Apply default params
        for pname, pval in self._paramdict.items():
            setattr(self, pname, pval)
        if self.CTRACE_AW is not None:
            self.CTRACE_MEM_SIZE = (1 << self.CTRACE_AW)
        self._label_dict = {}
        self.signal_map = {}
        self.loadFile(filename)

    def loadFile(self, filename):
        if filename is None:
            return
        lines = {}
        nline = 0
        with open(filename, 'r') as fd:
            line = True
            while line:
                line = fd.readline()
                nline += 1
                if line.startswith("#") or (len(line.strip()) == 0):
                    continue
                lines[nline] = line.strip()
        _pnames = [x for x in self._paramdict.keys()]
        # Parse lines
        for linenum, line in lines.items():
            fail = False
            try:
                lhs, rhs = line.split("=")
            except ValueError:
                fail = True
            if fail:
                raise Exception("Syntax error parsing {} [line {}]. Must be LHS = RHS".format(filename, linenum))
            if lhs.startswith("[") or lhs.isdigit():
                # It's a signal assignment
                # TODO - Handle signal assignments
                assigns = AssignmentParser.parseAssignment(line)
                for index, signal in assigns:
                    print(f"{index} = {signal}")
                    self.signal_map[index] = signal
            else:
                # It's a parameter
                lhs = lhs.strip()
                if lhs not in _pnames:
                    raise Exception("Invalid parameter {} (file {}, line {})".format(lhs, filename, linenum))
                val = _int(rhs.replace("_", ""))
                if val is None:
                    raise Exception("Invalid value {} (file {}, line {})".format(rhs, filename, linenum))
                print("Param: {} = {}".format(lhs, val))
                # Accept the parameter
                setattr(self, lhs, val)
        return

    def get(self, ch, default=None):
        """Get the (str) signal label associated with (int) channel 'ch'."""
        return self.signal_map.get(ch, default)

class AssignmentParser():
    LHS_TYPE_INDEX=0
    LHS_TYPE_RANGE=1

    RHS_TYPE_INDEX=0
    RHS_TYPE_SIGNAL=1
    RHS_TYPE_SIGNAL_INDEX=2
    RHS_TYPE_SIGNAL_RANGE=3
    RHS_TYPE_BITMAP=4
    RHS_TYPE_SIGNAL_INDEX_RANGE=5

    ASSIGN_TYPE_0 = (LHS_TYPE_INDEX, RHS_TYPE_INDEX)
    ASSIGN_TYPE_1 = (LHS_TYPE_INDEX, RHS_TYPE_SIGNAL)
    ASSIGN_TYPE_2 = (LHS_TYPE_INDEX, RHS_TYPE_SIGNAL_INDEX)
    ASSIGN_TYPE_3 = (LHS_TYPE_RANGE, RHS_TYPE_INDEX)
    ASSIGN_TYPE_4 = (LHS_TYPE_RANGE, RHS_TYPE_SIGNAL)
    ASSIGN_TYPE_5 = (LHS_TYPE_RANGE, RHS_TYPE_SIGNAL_INDEX)
    ASSIGN_TYPE_6 = (LHS_TYPE_RANGE, RHS_TYPE_SIGNAL_RANGE)
    ASSIGN_TYPE_7 = (LHS_TYPE_RANGE, RHS_TYPE_BITMAP)
    ASSIGN_TYPE_8 = (LHS_TYPE_RANGE, RHS_TYPE_SIGNAL_INDEX_RANGE)
    ASSIGN_TYPE = (ASSIGN_TYPE_0, ASSIGN_TYPE_1, ASSIGN_TYPE_2, ASSIGN_TYPE_3,
                   ASSIGN_TYPE_4, ASSIGN_TYPE_5, ASSIGN_TYPE_6, ASSIGN_TYPE_7,
                   ASSIGN_TYPE_8)
    reVLitHit = "([^\[\]:,.\s+-]+)"
    reVLitDec = "([0-9_]+)?"
    reVLitBase = "(\d+)?\s*('[hHbBdD])\s*([0-9a-fA-F_]+)"
    reVIndices = "^\[?\s*"+reVLitHit+"\s*([+\-]?)\s*:\s*"+reVLitHit+"\s*\]?$"
    reVIndex = "^\[?\s*"+reVLitHit+"\s*\]?$"

    rePyLit = "(0b[01]+|0x[0-9a-fA-F]+|[0-9]+)"
    rePyIndices = "^\[?\s*"+rePyLit+"\s*(:)\s*"+rePyLit+"\s*\]?$"
    rePyIndex = "^\[?\s*"+rePyLit+"\s*\]?$"

    @classmethod
    def parseLiteral(cls, string, syntax=SYNTAX_ANY):
        """Parse verilog/python integer literal (i.e. 6, 0x10, 1'b0, 8'hcc, 'd100, etc."""
        # First check for simple decimal case
        if syntax == SYNTAX_ANY:
            # Verilog first, then Python
            restrs = (cls.reVLitDec, cls.rePyLit)
        elif syntax == SYNTAX_PYTHON:
            restrs = (cls.rePyLit, )
        else:
            restrs = (cls.reVLitDec, )
        for restr in restrs:
            _match = re.match("^" + restr+ "$", string)
            if _match:
                val = _match.groups()[0]
                val = _int(val.replace('_',''))
                return (None, None, val)
        if syntax == SYNTAX_PYTHON:
            return None
        # Next try a Verilog-style literal with specified base
        _match = re.match("^" + cls.reVLitBase + "$", string)
        if _match:
            groups = _match.groups()
            size, base, val = groups
            #print(f"size = {size}, base = {base}, val = {val}")
            if size not in (None, ""):
                size = _int(size)
                if size < 1: # Invalid size
                    return None
            else:
                size = None
            if base not in (None, ""):
                base = base.lower()
                if base[-1] == 'h':
                    nbase = 16
                elif base[-1] == 'b':
                    nbase = 2
                elif base[-1] == 'd':
                    nbase = 10
                try:
                    val = int(val, nbase)
                except ValueError:
                    return None
            else:
                base = None
                val = int(size+val)
            return (size, base, val)
        return None

    @classmethod
    def splitIndices(cls, string, syntax=SYNTAX_VERILOG):
        if syntax == SYNTAX_ANY:
            rens = (cls.rePyIndices, cls.reVIndices)
            ren  = (cls.rePyIndex, cls.reVIndex)
        elif syntax == SYNTAX_PYTHON:
            rens = (cls.rePyIndices,)
            ren  = (cls.rePyIndex,)
        else:
            rens = (cls.reVIndices,)
            ren  = (cls.reVIndex,)
        #reIndices = "^\[?\s*([x0-9a-fA-F]+)\s*([+\-]?)\s*:\s*([x0-9a-fA-F]+)\s*\]?$"
        #reIndex = "^\[?\s*([x0-9a-fA-F]+)\s*\]?$"
        _match = None
        for rx in rens:
            _match = re.match(rx, string)
            if _match:
                break
        if _match:
            groups = _match.groups()
            #print(f"splitting {string}: groups = {groups}")
            i0 = cls.parseLiteral(groups[0], syntax=syntax)
            if i0 is not None:
                i0 = i0[-1]
            else:
                return (None, None)
            inc = groups[1]
            i1 = cls.parseLiteral(groups[2], syntax=syntax)
            if i1 is not None:
                i1 = i1[-1]
            else:
                return (None, None)
            if None in (i0, i1):
                low = None
                hi = None
            elif inc == "-":
                hi = i0
                low = hi-i1+1
            elif inc == "+":
                low = i0
                hi = low+i1-1
            else:
                low = min(i0, i1)
                hi = max(i0, i1)
            return (low, hi)
        # Else (did not match any of rens)
        for rx in ren:
            _match = re.match(rx, string)
            if _match:
                break
        if _match:
            groups = _match.groups()
            index = cls.parseLiteral(groups[0], syntax=syntax)
            if index is not None:
                index = index[-1]
            else:
                return (None, None)
            low = index
            hi = index
        else:
            low = None
            hi = None
        return (low, hi)

    @classmethod
    def getSignalRange(cls, string, syntax=SYNTAX_VERILOG):
        # First see if it's a simple literal
        if False:
            _match = cls.parseLiteral(string, syntax=syntax)
            if _match is not None:
                #print(f"0: _match = {_match}")
                size, base, val = _match
                low, hi = None, None
                #if size is not None:
                #    low = 0
                #    hi = low + size - 1
                return (string, low, hi)
        # Next see if it's a signal with an optional range
        reSigRange = "^\s*([a-zA-Z_~`][a-zA-Z_0-9.`]*)(\[[^\]]+\])?$"
        _match = re.match(reSigRange, string)
        if _match:
            groups = _match.groups()
            #print(f"1: groups = {groups}")
            name = groups[0]
            name = name.replace('`', '')  # Remove any macro backticks
            indices = groups[1]
            if indices is not None:
                #print(f"splitting: {indices}")
                low, hi = cls.splitIndices(indices, syntax=syntax)
            else:
                low = None
                hi = None
            return (name, low, hi)
        #print(f"No match on string {string}")
        return None

    @staticmethod
    def vetRange(vLo, vHi, sLo, sHi):
        if sLo is None and sHi is None:
            return True
        if vHi-vLo == sHi-sLo:
            return True
        return False

    @classmethod
    def LHSgetType(cls, string, debug=False):
        # Try index
        _match = cls.parseLiteral(string, syntax=SYNTAX_ANY)
        if _match is not None:
            #size, base, val = _match
            val = _match[2]
            if debug:
                print(f"LHS_TYPE_INDEX: val = {val}")
            return (cls.LHS_TYPE_INDEX, val)
        # Try range
        _match = cls.splitIndices(string, syntax=SYNTAX_PYTHON)
        if _match is not None:
            low, hi = _match
            if debug:
                print(f"LHS_TYPE_RANGE : low = {low}, hi = {hi}")
            return (cls.LHS_TYPE_RANGE, low, hi)
        return None

    @classmethod
    def RHSgetType(cls, string, debug=False):
        # RHS types:
        #   Index (Python constant)
        _match = cls.parseLiteral(string, syntax=SYNTAX_PYTHON)
        if _match is not None:
            #print(f"_match = {_match}")
            #size, base, val = _match
            val = _match[2]
            if debug:
                print(f"RHS_TYPE_INDEX: val = {val}")
            return (cls.RHS_TYPE_INDEX, val) # TODO - what else?
        #   Signal, Signal + index, Signal + range
        _match = cls.getSignalRange(string, syntax=SYNTAX_ANY)
        if _match is not None:
            name, low, hi = _match
            if low is None and hi is None:
                type_ = cls.RHS_TYPE_SIGNAL
                typeStr = "RHS_TYPE_SIGNAL"
            elif low == hi:
                type_ = cls.RHS_TYPE_SIGNAL_INDEX
                typeStr = "RHS_TYPE_SIGNAL_INDEX"
            else:
                type_ = cls.RHS_TYPE_SIGNAL_RANGE
                typeStr = "RHS_TYPE_SIGNAL_RANGE"
            if debug:
                print(f"{typeStr} name = {name}, low = {low}, hi = {hi}")
            return (type_, name, low, hi) # TODO - what else?
        #   Bitmap (Verilog constant)
        _match = cls.parseLiteral(string, syntax=SYNTAX_VERILOG)
        if _match is not None:
            size, base, val = _match
            if size is None or size > 1:
                if debug:
                    print(f"RHS_TYPE_BITMAP, val = {val}")
                return (cls.RHS_TYPE_BITMAP, val)
            else:
                # Special case of single bit still triggers index type
                if debug:
                    print(f"RHS_TYPE_INDEX (special): val = {val}")
                return (cls.RHS_TYPE_INDEX, val)
        #   Signal index range (pythonic)
        _match = cls.splitIndices(string, syntax=SYNTAX_PYTHON)
        if _match is not None:
            low, hi = _match
            if debug:
                print(f"RHS_TYPE_SIGNAL_INDEX_RANGE : low = {low}, hi = {hi}")
            return (cls.RHS_TYPE_SIGNAL_INDEX_RANGE, low, hi)
        return None

    @classmethod
    def getAssignmentType(cls, string, debug=False):
        if not '=' in string:
            return None
        lhs, rhs = string.split('=')
        _lhs = cls.LHSgetType(lhs.strip(), debug=debug)
        _rhs = cls.RHSgetType(rhs.strip(), debug=debug)
        if None in (_lhs, _rhs):
            return None
        lhs_type = _lhs[0]
        lhs_baggage = _lhs[1:]
        rhs_type = _rhs[0]
        rhs_baggage = _rhs[1:]
        return ((lhs_type, rhs_type), (lhs_baggage, rhs_baggage))

    @classmethod
    def parseAssignment(cls, string, debug=False):
        rval = cls.getAssignmentType(string, debug=debug)
        if rval is None:
            return None
        _type, baggage = rval
        handler = cls.getHandler(_type)
        assignments = handler(*baggage)
        if assignments is not None:
            return assignments # (ch_index, signal_label)
        return None

    @classmethod
    def getHandler(cls, _type):
        for n in range(len(cls.ASSIGN_TYPE)):
            if _type == cls.ASSIGN_TYPE[n]:
                return BaggageHandlers.get(n)
        return None

class BaggageHandlers():
    # Set to 1 to allow, 0 to disallow
    type_mask = (
        0, # Type 0: Single channel index = single signal index
        1, # Type 1: Single index = wire signal
        1, # Type 2: Single index = an element of an array
        0, # Type 3: Range channel indices = same signal index
        1, # Type 4: Range indicies = same signal
        0, # Type 5: Range indicies = same element of an array
        1, # Type 6: Range indices = range of an array
        0, # Type 7: Range channel indices = static bit map
        0, # Type 8: Range channel indices = Range signal indices
        )

    @classmethod
    def get(cls, assign_type):
        _handlers = (
            cls.handleBaggageType0,
            cls.handleBaggageType1,
            cls.handleBaggageType2,
            cls.handleBaggageType3,
            cls.handleBaggageType4,
            cls.handleBaggageType5,
            cls.handleBaggageType6,
            cls.handleBaggageType7,
            cls.handleBaggageType8,
        )
        atype = int(assign_type)
        if atype < len(cls.type_mask):
            return _handlers[atype]
        return lambda x, y: None

    @classmethod
    def getConfig(cls):
        raise Exception("TODO")

    @classmethod
    def _loadParseDict(cls):
        raise Exception("TODO")

    @classmethod
    def vetChIndex(cls, n, config=None):
        # TODO bypassing
        return n
        if n is None:
            return None
        if config is None:
            config = cls.getConfig()
        num_outputs = config.NUM_OUTPUTS
        if n < num_outputs:
            assert isinstance(n, int), f"{n} is not an integer"
            return n
        else:
            print(f"Channel index {n} >= {num_outputs}")
        return None

    @classmethod
    def vetSigIndex(n, config=None):
        if n is None:
            return None
        if config is None:
            config = cls.getConfig()
        num_inputs = config.NUM_INPUTS
        if n < num_inputs:
            assert isinstance(n, int), f"{n} is not an integer"
            return n
        else:
            print(f"Signal index {n} >= {num_inputs}")
        return None

    @classmethod
    def _getIndex(cls, label):
        # First check if we can find the label in the top file if supplied
        parseDict = cls._loadParseDict()
        # If file has been parsed, try to find the label in that dict
        if parseDict is not None:
            for index, entry in parseDict.items():
                if label==entry:
                    return index
        # If we get here, we didn't find the label. Try to find it using the application file (_sels.py)
        return None

    @classmethod
    def unpackVetLHSRange(cls, baggage):
        ch_index_lo, ch_index_hi = baggage
        ch_index_lo = cls.vetChIndex(ch_index_lo)
        ch_index_hi = cls.vetChIndex(ch_index_hi)
        if ch_index_lo is None or ch_index_hi is None:
            return None
        return (ch_index_lo, ch_index_hi)

    @classmethod
    def handleBaggageType0(cls, lhs_baggage, rhs_baggage, config=None):
        # TODO broken
        """Type 0: Single channel index = single signal index"""
        if not cls.type_mask[0]:
            return None
        if config is None:
            config = cls.getConfig()
        num_outputs = config.NUM_OUTPUTS
        num_inputs = config.NUM_INPUTS
        ch_index = cls.vetChIndex(lhs_baggage[0])
        if ch_index is None:
            return None
        sig_index = cls.vetSigIndex(rhs_baggage[0])
        if sig_index is None:
            return None
        if ch_index < num_outputs and sig_index < num_inputs:
            # Return assignments (set ch_index to sig_index)
            return [(ch_index, sig_index)]
        else:
            if ch_index >= num_outputs:
                print(f"Channel index {ch_index} >= {num_outputs}")
            if sig_index >= num_inputs:
                print(f"Signal index {sig_index} >= {num_inputs}")
        return None

    @classmethod
    def handleBaggageType1(cls, lhs_baggage, rhs_baggage):
        if not cls.type_mask[1]:
            return None
        """Type 1: Single index = wire signal"""
        ch_index = cls.vetChIndex(lhs_baggage[0])
        if ch_index is None:
            return None
        sig_name = rhs_baggage[0]
        return [(ch_index, sig_name)]

    @classmethod
    def handleBaggageType2(cls, lhs_baggage, rhs_baggage):
        """Type 2: Single index = an element of an array"""
        if not cls.type_mask[2]:
            return None
        ch_index = cls.vetChIndex(lhs_baggage[0])
        if ch_index is None:
            return None
        sig_name, i0, i1 = rhs_baggage # name, low, hi
        assert i0 == i1, f"LOGICAL ASERTION ERROR: i0 {i0} somehow != i1 {i1}"
        signal = f"{sig_name}[{i0}]"
        return [(ch_index, signal)]

    @classmethod
    def handleBaggageType3(cls, lhs_baggage, rhs_baggage):
        # TODO broken
        """Type 3: Range channel indices = same signal index"""
        if not cls.type_mask[3]:
            return None
        rval = cls.unpackVetLHSRange(lhs_baggage)
        if rval is None:
            return None
        ch_index_lo, ch_index_hi = rval
        sig_index = rhs_baggage[0]
        sig_index = cls.vetSigIndex(sig_index)
        if sig_index is None:
            return None
        assignments = []
        for ch_index in range(ch_index_lo, ch_index_hi+1):
            assignments.append((ch_index, sig_index))
        return assignments

    @classmethod
    def handleBaggageType4(cls, lhs_baggage, rhs_baggage):
        """Type 4: Range indicies = same signal"""
        if not cls.type_mask[4]:
            return None
        rval = cls.unpackVetLHSRange(lhs_baggage)
        if rval is None:
            return None
        ch_index_lo, ch_index_hi = rval
        sig_name = rhs_baggage[0]
        assignments = []
        sig_index = 0
        for ch_index in range(ch_index_lo, ch_index_hi+1):
            signal = f"{sig_name}[{sig_index}]"
            assignments.append((ch_index, signal))
            sig_index += 1
        return assignments

    @classmethod
    def handleBaggageType5(cls, lhs_baggage, rhs_baggage):
        # TODO broken
        """Type 5: Range indicies = same element of an array"""
        if not cls.type_mask[5]:
            return None
        rval = cls.unpackVetLHSRange(lhs_baggage)
        if rval is None:
            return None
        ch_index_lo, ch_index_hi = rval
        sig_name, i0, i1 = rhs_baggage # name, low, hi
        assert i0 == i1, f"LOGICAL ASERTION ERROR: i0 {i0} somehow != i1 {i1}"
        signal = f"{sig_name}[{i0}]"
        sig_index = cls._getIndex(signal)
        if sig_index is None:
            print(f"Could not find index of signal {signal}")
            return None
        assignments = []
        for ch_index in range(ch_index_lo, ch_index_hi+1):
            assignments.append((ch_index, sig_index))
        return assignments

    @classmethod
    def handleBaggageType6(cls, lhs_baggage, rhs_baggage):
        """Type 6: Range indices = range of an array"""
        if not cls.type_mask[6]:
            return None
        rval = cls.unpackVetLHSRange(lhs_baggage)
        if rval is None:
            return None
        ch_index_lo, ch_index_hi = rval
        sig_name, i0, i1 = rhs_baggage # name, low, hi
        assignments = []
        for offset in range(ch_index_hi-ch_index_lo+1):
            ch_index = ch_index_lo + offset
            sig_range_index = i0 + offset
            signal = f"{sig_name}[{sig_range_index}]"
            assignments.append((ch_index, signal))
        return assignments

    @classmethod
    def handleBaggageType7(cls, lhs_baggage, rhs_baggage):
        # TODO broken
        """Type 7: Range channel indices = static bit map"""
        if not cls.type_mask[7]:
            return None
        rval = unpackVetLHSRange(lhs_baggage)
        if rval is None:
            return None
        ch_index_lo, ch_index_hi = rval
        bitmap = rhs_baggage[0]
        index_1b0 = cls._getIndex("0")
        index_1b1 = cls._getIndex("1")
        if index_1b0 is None or index_1b1 is None:
            print("Need both 1'b0 and 1'b1 mapped to assignments to use bitmap feature")
            return None
        assignments = []
        for offset in range(ch_index_hi-ch_index_lo+1):
            ch_index = ch_index_lo + offset
            if (bitmap >> offset) & 1:
                assignments.append((ch_index, index_1b1))
            else:
                assignments.append((ch_index, index_1b0))
        return assignments

    @classmethod
    def handleBaggageType8(cls, lhs_baggage, rhs_baggage):
        """Type 8: Range channel indices = Range signal indices"""
        if not cls.type_mask[8]:
            return None
        rval = cls.unpackVetLHSRange(lhs_baggage)
        if rval is None:
            return None
        ch_index_lo, ch_index_hi = rval
        sig_i0, sig_i1 = rhs_baggage # low, hi
        # Ensure ranges are same length
        if abs(sig_i1 - sig_i0) != abs(ch_index_hi - ch_index_lo):
            print("Ranges are not equal in length: [{}:{}]=[{}:{}]".format(
                ch_index_lo, ch_index_hi, sig_i1, sig_i0))
            return []
        sig_lo = min(sig_i0, sig_i1)
        sig_hi = max(sig_i0, sig_i1)
        assignments = []
        for offset in range(ch_index_hi-ch_index_lo+1):
            ch_index = ch_index_lo + offset
            sig_index = sig_lo + offset
            assignments.append((ch_index, sig_index))
        return assignments

def testConfigFile():
    import sys
    if len(sys.argv) < 2:
        print("gimme file")
        return
    cfg = Config(sys.argv[1])
    return

if __name__ == "__main__":
    testConfigFile()
