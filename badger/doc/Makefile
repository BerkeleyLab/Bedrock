# Commentary in ../tests/Makefile
XCIRCUIT = xcircuit
XVFB = xvfb-run -a -s "-screen 0 1440x900x24"
PANDOC = pandoc

all: svg
.PHONY: svg html

svg: rtefi.svg stack.svg clients.svg mem_gateway.svg memory.svg tx_path.svg precog_upg.svg

html: ../index.html ../status.html

# Kind of weird to use xcircuit for this purpose, but it does work
%.svg: %.eps
	echo "page load $<; svg; exit" > .xcircuitrc; $(XVFB) $(XCIRCUIT); rm .xcircuitrc

../index.html: ../README.md
	$(PANDOC) -t html $< | sed -e 's,status\.md,status.html,g' > $@

../status.html: ../status.md
	$(PANDOC) -t html -o $@ $<

clean:
	rm -f *.svg *.html
