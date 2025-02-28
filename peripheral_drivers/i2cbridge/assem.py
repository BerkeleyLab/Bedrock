"""
Assembler for the i2cbridge program sequencer
"""

import sys
import math


class ListStream:
    """A class that behaves as both an iterator (has '__next__') and a stream in read-mode
    (has 'seek' and 'tell')."""

    def __init__(self, lst):
        self._l = lst
        self._rptr = 0
        self._max = len(self._l) - 1

    def __next__(self):
        if self._rptr > self._max:
            raise StopIteration
        else:
            rval = self._l[self._rptr]
            self._rptr += 1
            return rval

    def seek(self, offset):
        """Set read pointer to integer 'offset'.
        If offset < 0, set read pointer to end-abs(offset)."""
        offset = int(offset)
        if abs(offset) > self._max - 1:
            raise I2C_Assembler_Exception(
                f"Attempting to seek to {offset} beyond size of stream {self._max}"
            )
        if offset < 0:
            offset = self._max + offset
        if offset < self._max:
            self._rptr = offset
        return

    def tell(self):
        """Return current read pointer"""
        return self._rptr


class i2c_assem:
    # sequencer op codes
    o_oo = 0x00
    o_rd = 0x20
    o_wr = 0x40
    o_wx = 0x60
    o_p1 = 0x80
    o_p2 = 0xA0
    o_jp = 0xC0
    o_sx = 0xE0
    # add to these the number of bytes read or written.
    # Note that o_wr and o_wx will be followed by that number of bytes
    # in the instruction stream, but o_rd is only followed by one more
    # byte (the device address); the data read cycles still happen, and
    # post results to the result bus, but don't consume instruction bytes.
    n_oo_zz = 0x00
    n_oo_bf = 0x02
    n_oo_ta = 0x03
    n_oo_hw = 0x10

    # write data words to specified dadr
    @classmethod
    def write(cls, dadr, madr, data, addr_bytes=1):
        if dadr & 1:
            raise I2C_Assembler_Exception("Address error 0x%2.2x" % dadr)
        n = 1 + addr_bytes + len(data)
        if n > 31:
            raise I2C_Assembler_Exception("Write length error: %d" % n)
        if addr_bytes == 0:
            m1 = []
        elif addr_bytes == 1:
            m1 = [madr]
        elif addr_bytes == 2:
            m1 = [madr // 256, madr & 255]
        return [cls.o_wr + n, dadr] + m1 + data

    # sets the read address, then repeated start, then reads data
    @classmethod
    def read(cls, dadr, madr, dlen, addr_bytes=1):
        if dadr & 1:
            raise I2C_Assembler_Exception("Address error 0x%2.2x" % dadr)
            return []
        if dlen > 30:
            raise I2C_Assembler_Exception("Read length error: %d" % dlen)
            return []
        if addr_bytes == 0:
            # optimize away a useless [cls.o_wx+1, dadr]
            return [cls.o_rd + 1 + dlen, dadr + 1]
        elif addr_bytes == 1:
            return [cls.o_wx + 2, dadr, madr, cls.o_rd + 1 + dlen, dadr + 1]
        elif addr_bytes == 2:
            return [
                cls.o_wx + 3,
                dadr,
                int(madr / 256),
                madr & 255,
                cls.o_rd + 1 + dlen,
                dadr + 1,
            ]
        else:
            raise I2C_Assembler_Exception("Unsupported addr_byes: %d" % addr_bytes)
        return []

    # combine short and long pauses to get specified cycles
    # configured for production (q1=2, q2=7), tests will not conform
    @classmethod
    def pause(cls, n):
        r = []
        while n >= 992:
            r += [cls.o_p2 + 31]
            n -= 31 * 32
        if n > 32:
            x = int(n / 32)
            r += [cls.o_p2 + x]
            n -= x * 32
        if n > 0:
            r += [cls.o_p1 + n]
        return r

    @classmethod
    def jump(cls, n):
        n = int(n)
        if n > 31:
            raise I2C_Assembler_Exception(
                f"Invalid jump: {n} (5 bits, valid range = 0-31)"
            )
        return [cls.o_jp + n]

    @classmethod
    def set_resx(cls, n):
        n = int(n)
        if n > 31:
            raise I2C_Assembler_Exception(
                f"Invalid result index: {n} (5 bits, valid range = 0-31)"
            )
        return [cls.o_sx + n]

    @classmethod
    def buffer_flip(cls):
        return [cls.o_oo + 2]

    @classmethod
    def trig_analyz(cls):
        return [cls.o_oo + 3]

    @classmethod
    def hw_config(cls, n):
        n = int(n)
        if n > 15:
            raise I2C_Assembler_Exception(
                f"Invalid hw_config: {n} (4 bits, valid range = 0-15)"
            )
        return [cls.o_oo + 16 + n]

    # l is length of program so far
    # jump_n is jump address after padding
    @classmethod
    def pad(cls, jump_n, length):
        pad_n = 32 * jump_n - length
        if pad_n < 0:
            raise I2C_Assembler_Exception("Oops!  negative pad %d" % pad_n)
        return pad_n * [cls.o_p1]  # Pause for zero ticks

    @classmethod
    def stop(cls):
        return [cls.o_oo]


class I2CAssembler(i2c_assem):
    _ADDRESS_MAX = 1024
    _JUMP_ADDRESS_MAX = _ADDRESS_MAX - 32
    _INDEX_MAX = _ADDRESS_MAX // 32
    _JUMP_INDEX_MAX = _INDEX_MAX - 1

    @staticmethod
    def _mkRegName(dadr, madr, rc):
        """[private] Build a default register name from device address 'dadr', memory address
        'madr' and results pointer 'rc'
        """
        if madr is None:
            madr_s = ""
        else:
            madr_s = f"{madr:02x}_"
        return f"reg_{dadr:02x}_{madr_s}{rc:04x}"

    def __init__(self, advanced_mode=False):
        """Params:
        advanced_mode : Suppresses certain exceptions during program check.  Allows you
                        to shoot yourself in the foot.
        """
        super().__init__()
        self._rc = 0  # Results counter
        self._program = []
        self._memdict = {}  # {"name" : (offset, size)}
        self._advanced_mode = advanced_mode

    def _pc(self):
        """[private] Get current program counter value"""
        return len(self._program)

    def _check_pc(self):
        if len(self._program) > self._ADDRESS_MAX - 1:
            raise I2C_Assembler_Exception("Program size exceeded")
        return

    def _check_rc(self):
        if self._rc > self._ADDRESS_MAX - 1:
            raise I2C_Assembler_Exception("Result buffer size exceeded")
        return

    @classmethod
    def _get_next_instruction(cls, prog_iter):
        """[private] Get next instruction from iterator 'prog_iter'.
        Returns (op_code, n_code, [data])"""
        try:
            inst = next(prog_iter)
        except StopIteration:
            return None
        op_code = inst & 0xE0  # Mask in upper 3 bits
        n_code = inst & 0x1F  # Mask in lower 5 bits
        data = []
        if op_code == cls.o_rd:
            try:
                data.append(next(prog_iter))
            except StopIteration:
                raise I2C_Assembler_Exception(
                    "Corrupted program detected. "
                    + "Program terminates before read (rd) instruction is completed"
                )
        elif op_code == cls.o_wr:
            for n in range(n_code):
                try:
                    data.append(next(prog_iter))
                except StopIteration:
                    raise I2C_Assembler_Exception(
                        "Corrupted program detected. "
                        + "Program terminates before write (wr) instruction is completed"
                    )
        elif op_code == cls.o_wx:
            for n in range(n_code):
                try:
                    data.append(next(prog_iter))
                except StopIteration:
                    raise I2C_Assembler_Exception(
                        "Corrupted program detected. "
                        + "Program terminates before write-multi (wx) instruction is completed"
                    )
        # All other op_code values have no data
        return (op_code, n_code, data)

    @classmethod
    def check(cls, prog, verbose=False, advanced=False):
        """Check program for violations of subtle usage rules."""

        # Look for a jump backward then follow that address forward
        # Must encounter a set_resx() before a read() or violation.
        def prnt(*args, **kwargs):
            if verbose:
                print(*args, **kwargs)

        jumps = []
        backwards_jumped = False
        srx_after_jump = False
        loop_end = False
        has_read = False
        has_buffer_flip = False
        iprog = ListStream(prog)
        pc = iprog.tell()
        rval = cls._get_next_instruction(iprog)
        while rval is not None:
            op_code, n_code, data = rval
            if loop_end:  # Should not be any code after a backwards jump
                raise I2C_Assembler_Exception(
                    f"Instruction [{op_code:03b}:{n_code:05b}] "
                    + f"at address {pc} is unreachable."
                )
            if op_code == cls.o_oo:
                if n_code == cls.n_oo_bf:  # buffer_flip
                    has_buffer_flip = True
            elif op_code == cls.o_jp:  # jump
                prnt(f"Found jump at pc {pc:03x}")
                if pc not in jumps:
                    jumps.append(pc)
                    # Follow jump
                    if pc > n_code * 32:
                        prnt("  Jump is backwards")
                        backwards_jumped = True
                    pc = n_code * 32
                    prnt(f"Going to pc {pc:03x}")
                    iprog.seek(pc)
                else:  # pc is in jumps (we've already followed it)
                    if pc > n_code * 32:
                        loop_end = True
            elif op_code == cls.o_sx:  # set_resx
                prnt(f"Found set_resx at pc {pc:03x}")
                if backwards_jumped:
                    prnt("  After a backwards jump")
                    srx_after_jump = True
            elif op_code == cls.o_rd:  # read
                prnt(f"Found read at pc {pc:03x}")
                has_read = True
                if backwards_jumped:
                    prnt(
                        f"  After a backwards jump (srx_after_jump = {srx_after_jump})"
                    )
                    if not srx_after_jump:
                        raise I2C_Assembler_Exception(
                            f"Program address 0x{pc:03x}: Must use set_resx() after "
                            + "a backwards jump before any read operations for consistent address of results."
                        )
            pc = iprog.tell()
            prnt(f"pc = {pc:03x}")
            rval = cls._get_next_instruction(iprog)
        if has_read and not has_buffer_flip:
            if not advanced:
                raise I2C_Assembler_Exception(
                    "Program has read operation but no buffer flip found."
                    + " Result buffer is unreadable.  Use 'advanced mode' to suppress this exception."
                )
        return True

    def check_program(self, verbose=False):
        rval = self.check(self._program, verbose=verbose, advanced=self._advanced_mode)
        if rval and verbose:
            print("Program good")
        return

    def write(self, dadr, madr, data, addr_bytes=1):
        """Add an I2C write transaction to the program.
        Params:
            int dadr : Device I2C Address
            int madr : Memory address within device ('addr_bytes' long)
            [int] data : Data to write (List of byte-sized ints)
            int addr_bytes : Size in bytes of memory address (1 or 2)
        Returns: program instructions
        """
        if madr is None:
            addr_bytes = 0
        pval = super().write(dadr, madr, data, addr_bytes=addr_bytes)
        self._program += pval
        self._check_pc()
        return pval

    def read(self, dadr, madr, dlen, addr_bytes=1, reg_name=None):
        """Add an I2C read transaction to the program.
        Params:
            int dadr : Device I2C Address
            int madr : Memory address within device ('addr_bytes' long)
            int dlen : How many data bytes to read
            int addr_bytes : Size in bytes of memory address (1 or 2)
            str reg_name : A name to associate with result memory address
        Returns: Starting memory offset of result
        NOPE! Returns: program instructions
        """
        if madr is None:
            addr_bytes = 0
        pval = super().read(dadr, madr, dlen, addr_bytes=addr_bytes)
        self._program += pval
        self._check_pc()
        if reg_name is None:
            reg_name = self._mkRegName(dadr, madr, self._rc)
        self._memdict[reg_name] = (self._rc, dlen)
        self._rc += dlen
        self._check_rc()
        return pval

    def pause(self, n):
        """Add a pause of 'n' ticks to the program
        See README.md for discussion of tick length."""
        pval = super().pause(n)
        self._program += pval
        self._check_pc()
        return pval

    def jump(self, n):
        """Add a jump instruction to program counter n*32
        Params:
            int n : The program counter index value to jump to (jump address = 32*n).
        Gotchas:
            n must be in range 0-31.
            Raises I2C_Assembler_Exception if this would result in a 'jump here' instruction
            (a jump to the program counter value of the jump instruction).
        """
        n = int(n)
        if self._pc == n * 32:
            raise I2C_Assembler_Exception(
                "Jump would result in 'jump here' instruction"
                + "(a jump to the program counter value of the jump instruction)."
            )
        pval = super().jump(n)
        self._program += pval
        self._check_pc()
        return pval

    def jump_address(self, address):
        """Add a jump instruction to program counter 'address'
        Params:
            int address : The explicit program counter value to jump to.
        Gotchas:
            Address must be integer multiple of 32 and be in range 0-992 (0x000-0x3e0).
        """
        address = int(address)
        if (address & 0x1F) != 0:
            raise I2C_Assembler_Exception(
                f"Invalid address {address}. jump_address() expects explicit"
                + " address of jump and must be integer multiple of 32."
            )
        elif address > self._JUMP_ADDRESS_MAX:
            raise I2C_Assembler_Exception(
                f"Location {address} outside of memory range (0-1024)."
            )
        return self.jump(address >> 5)

    def jump_pad(self, n=None):
        """Add a jump instruction to program counter 32*n followed by padding until then.
        Params:
            int n : The program counter index value to jump to (jump address = 32*n).
        Gotchas:
            n must be in range 0-31.
            32*n must be > current program counter value.
        Returns: program counter index (pc/32) after pad"""
        if n is None:
            n = (self._pc() // 32) + 1  # ceil(pc/32)
        n = int(n)
        if n <= self._pc() / 32:
            raise I2C_Assembler_Exception(
                f"Cannot jump_pad to location {32*n} <="
                + " current program counter {self._pc()}."
            )
        self.jump(n)
        return self.pad(n)

    def jump_pad_address(self, address=None):
        """Add a jump instruction to program counter 'address' followed by padding until then.
        Params:
            int address : The explicit program counter value to jump to.
        Gotchas:
            Address must be integer multiple of 32 and be in range pc+1 to 992 (0x3e0).
            where 'pc' is the current program counter value.
        Returns: program counter after pad"""
        if address is None:
            address = 32 * (self._pc() // 32) + 1  # 32*ceil(pc/32)
        address = int(address)
        if (address & 0x1F) != 0:
            raise I2C_Assembler_Exception(
                f"Invalid address {address}. jump_pad_address() expects explicit"
                + " address of jump and must be integer multiple of 32."
            )
        elif address <= self._pc():
            raise I2C_Assembler_Exception(
                f"Cannot jump_pad to location {address} <= current program counter"
                + " {self._pc()}."
            )
        elif address > self._JUMP_ADDRESS_MAX:
            raise I2C_Assembler_Exception(
                f"Location {address} outside of memory range (0-1024)."
            )
        n = address // 32
        self.jump(n)
        self.pad(n)
        return self._pc()

    def set_resx(self, n=None):
        """Add a set result address pointer instruction to program.
        Sets results address to (0x800 + n*32).
        Params:
            int n : result address offset in units of 32-bytes (address = 0x800 + n*32)
                    If n is None, sets result address pointer to the next unoccupied increment
                    address 32*(int(rc/32)+1) where 'rc' is the results memory pointer.
                    This is useful just after a jump-to address to ensure data from any
                    reads in the program loop always end up in the
                    same location.
        Gotchas:
            See above for special case when n is None.
        """
        if n is None:
            n = (self._rc // 32) + 1  # ceil(rc/32)
        n = int(n)
        pval = super().set_resx(n)
        self._program += pval
        self._check_pc()
        self._rc = 32 * n
        self._check_rc()  # This should be redundant but certainly can't hurt
        return pval

    def set_resx_address(self, address=None):
        """Add a set result address pointer instruction to program.
        Sets results address to (0x800 + address).
        Params:
            int address : The explicit address offset within the results memory space to
                    which to set the results pointer.
                    If address is None, sets result address pointer to the next jumpable
                    address 32*(int(pc/32)+1).  This is useful just after a jump-to address
                    to ensure data from any reads in the program loop always end up in the
                    same location.
        Gotchas:
            The memory space offset 0x800 is implied; 'address' should be an offset from
            that point.
            See above for special case when address is None.
        """
        if address is not None:
            # Skim off memory region offset 0x800 if accidentally included
            n = (address & 0x3FF) // 32
        else:
            n = None
        return self.set_resx(n)

    def buffer_flip(self):
        """Add a buffer flip instruction to the program."""
        pval = super().buffer_flip()
        self._program += pval
        self._check_pc()
        return pval

    def trig_analyz(self):
        """Add an analyzer trigger instruction to the program."""
        pval = super().trig_analyz()
        self._program += pval
        self._check_pc()
        return pval

    def hw_config(self, n):
        """Add a hw_config set instruction to the program.
        Params:
            int n : 4-bit mask of hw_config outputs of module i2c_chunk"""
        pval = super().hw_config(n)
        self._program += pval
        self._check_pc()
        return pval

    def pad(self, *args, **kwargs):
        """Pad program memory up to location 32*n. Typically used to pad program
        to a location you can jump to.  Consider using jump_pad() for this purpose.
        Params:
            int n : Integer multiple of 32 to pad to.
        Gotchas:
            32*n must be > current program counter.  Use with no arg (n=None) to avoid
            this pitfall (pads up to next nearest multiple of 32).
        Returns: program counter index (pc/32) after pad
        NOTE! To allow drop-in compatibility, this function also operates using the
        same interface as i2c_assem.pad(n, length).  When used in this way, it returns
        a list of program instructions - the same as the old-style usage."""
        if len(args) == 2:
            # Hack to preserve API of parent class
            n = args[0]
            current_pc = args[1]
            return super().pad(n, current_pc)
        elif len(args) == 1:
            n = args[0]
        if 'n' in kwargs.keys():
            n = kwargs.get('n')
        if n is None:
            n = (self._pc() // 32) + 1  # ceil(pc/32)
        n = int(n)
        if n < self._pc() // 32:
            raise I2C_Assembler_Exception(
                f"Cannot pad to index {n} which corresponds to an address earlier than"
                + " the current program counter value {self._pc()}"
            )
        elif n > self._INDEX_MAX:
            raise I2C_Assembler_Exception(
                f"Program counter index {n} exceeds maximum {self._INDEX_MAX}"
            )
        pval = super().pad(n, self._pc())
        self._program += pval
        self._check_pc()
        return self._pc() // 32

    def pad_address(self, address=None):
        """Pad program memory up to location 'address'. Typically used to pad program
        to a location you can jump to.  Consider using jump_pad() for this purpose.
        Params:
            int address : The explicit program counter value to pad up to.
        Gotchas:
            address must be > current program counter.  Use with no arg (address=None)
            to avoid this pitfall (pads up to next nearest multiple of 32).
        Returns: program counter after pad"""
        address = int(address)
        if (address & 0x1F) != 0:
            raise I2C_Assembler_Exception(
                f"Invalid address {address}. pad_address() expects explicit"
                + " address of jump and must be integer multiple of 32."
            )
        elif address <= self._pc():
            raise I2C_Assembler_Exception(
                f"Cannot pad to location {address} <= current program counter {self._pc()}."
            )
        elif address > self._JUMP_ADDRESS_MAX:
            raise I2C_Assembler_Exception(
                f"Location {address} outside of memory range (0-1024)."
            )
        n = address // 32
        self.pad(n)
        return self._pc()

    def stop(self):
        """Add a deliberate stop character to the I2C program.  When encountered, the
        I2C program will halt and reset, requiring intervention to restart (assert
        run_cmd at the verilog module)."""
        self._program += super().stop()
        self._check_pc()
        return

    def get_program(self):
        """Get the program as a list (after checking)"""
        self.check_program()
        return self._program

    def write_program(self, fd=sys.stdout):
        """Write program contents to file descriptor 'fd'."""
        self.check_program()
        for b in self._program:
            fd.write(f"{b:02x}\n")
        return

    def write_reg_map(self, fd=sys.stdout, offset=0, style="v", filename=None):
        """Write register map to file descriptor 'fd'.
        Params:
            file descriptor fd : Stream-like interface (has 'write' method) to write output.
            int offset : Memory offset value to be added to all registers
            str style : Specify register map output style. Options:
                'v', 'V', 'Verilog', 'verilog' : Verilog style localparams
                'c', 'C' : C-style preprocessor macros
                'j', 'json', 'JSON' : JSON register map
        """
        if filename is None:
            filename = "assem_reg_map"
        else:
            filename = str(filename)
        global_offset = int(offset)
        pre = None
        post = None
        inter = ""
        style = style.lower()[0]
        if style == "v":
            # Verilog-style
            fmt = "localparam {0} = 'h{1:x};\n" + "localparam {0}_SIZE = {2};\n"
        elif style == "c":
            # C-style
            pre = "#ifndef __{0}_H\n#define __{0}_H\n".format(filename.upper())
            fmt = "#define {0} (0x{1:x})\n" + "#define {0}_SIZE ({2})\n"
            post = "#endif // __{}_H\n".format(filename.upper())
        elif style == "j":
            # JSON-style
            pre = "{\n"
            inter = ",\n"
            fmt = (
                '  "{0}": {{\n'
                + '    "access": "r",\n'
                + '    "addr_width": {3},\n'
                + '    "sign": "unsigned",\n'
                + '    "base_addr": {1},\n'
                + '    "data_width": 8\n'
                + "  }}"
            )
            post = "\n}\n"
        else:
            raise I2C_Assembler_Exception(f"Unknown register map style {style}")
        first = True
        if pre is not None:
            fd.write(pre)
        for name, v in self._memdict.items():
            offset, nbytes = v
            offset = offset + global_offset
            addr_width = math.ceil(math.log2(nbytes))
            if first:
                first = False
            else:
                fd.write(inter)
            fd.write(fmt.format(name, offset, nbytes, addr_width))
        if post is not None:
            fd.write(post)
        return

    def get_regmap(self):
        """Return dict of {regname: (results_memory_offset, number_of_bytes)}"""
        return self._memdict


class I2C_Assembler_Exception(Exception):
    def __init__(self, s):
        super().__init__(s)


def test_mkRegName(argv):
    if len(argv) < 3:
        print(f"USAGE: python3 {argv[0]} dadr madr rc")
        return
    dadr = int(argv[1])
    madr = int(argv[2])
    rc = int(argv[3])
    s = I2CAssembler._mkRegName(dadr, madr, rc)
    print(s)
    return


def check_program(argv):
    """Check an externally-compiled program for logical errors."""
    if len(argv) < 2:
        print(
            "Check an externally-compiled program for logical errors.\n"
            + f"USAGE: python3 {argv[0]} prog_file"
        )
        return
    prog = []
    with open(argv[1], "r") as fd:
        line = fd.readline()
        while line:
            vals = line.strip().split()
            prog.extend([int(v, 16) for v in vals])
            line = fd.readline()
    print("Program size: {} instructions".format(len(prog)))
    if I2CAssembler.check(prog, verbose=False):
        print("Program good")
    else:
        print("Program fail (see Exceptions)")
    return


if __name__ == "__main__":
    # test_mkRegName(sys.argv)
    check_program(sys.argv)
