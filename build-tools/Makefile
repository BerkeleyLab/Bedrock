# No real work gets done in this directory.
# This Makefile is only used to build documentation.

XCIRCUIT = xcircuit
XVFB = xvfb-run -a -s "-screen 0 1440x900x24"

# Kind of weird to use xcircuit's rc file for this purpose,
# but it does work.
%.svg: %.eps
	echo "page load $<; svg; exit" > .xcircuitrc; $(XVFB) $(XCIRCUIT); rm .xcircuitrc

all: cdc_snitch.html

cdc_snitch.html: cdc_snitch.md cdc_BAD.svg cdc_OK1.svg cdc_OKX.svg
	pandoc -t html $< > $@

clean:
	rm -f cdc_snitch.html

# Our sphinx CI toolchain needs these non-source files
# checked into git, unfortunately.  Maybe that can be fixed eventually.
spotless: clean
	rm -f cdc_*.svg
