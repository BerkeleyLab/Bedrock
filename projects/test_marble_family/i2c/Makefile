# A demo of Marble-specific I2C functionality

PYTHON ?= python3

TARGETS = prog.dat prog.vh prog.h prog.json

.PHONY: all
all: $(TARGETS)

.PHONY: tests
tests: check violations decode generic_decode

# ======= Simply build and check a program
PROG_FILE = demo_marble_i2c.py
.PHONY: check
check: $(PROG_FILE)
	$(PYTHON) $<

# ======= Build a program for i2c_chunk
prog.dat: $(PROG_FILE)
	$(PYTHON) $< p > $@

# ======= Build a memory map in Verilog format
prog.vh: $(PROG_FILE)
	$(PYTHON) $< v 0x800 > $@

# ======= Build a memory map in C format
prog.h: $(PROG_FILE)
	$(PYTHON) $< c 0x800 > $@

# ======= Build a memory map in JSON format
prog.json: $(PROG_FILE)
	$(PYTHON) $< j 0x800 > $@

# ======= Test a bunch of assembler violations
BAD_FILE = demo_i2c_baddy.py
.PHONY: violations
violations: $(BAD_FILE)
	$(PYTHON) $<

# ======= Decode a program in marble context
DECODE_FILE = marble_i2c_decoder.py
.PHONY: decode
decode: prog.dat
	$(PYTHON) $(DECODE_FILE) $<

# ======= Decode a program with no context (generic)
GENERIC_DECODE_FILE=../../../peripheral_drivers/i2cbridge/decode.py
.PHONY: generic_decode
generic_decode: prog.dat
	$(PYTHON) $(GENERIC_DECODE_FILE) $<

.PHONY: clean
clean:
	rm -f $(TARGETS)
