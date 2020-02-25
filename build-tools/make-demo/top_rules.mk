VERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)
GTKWAVE = gtkwave
VFLAGS =

%_check: %_tb
	$(VVP) -N $<

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS) -o $@ $^

%.out: %_tb
	$(VVP) -N $< > $@

%.vcd: %_tb
	$(VVP) -N $< +vcd

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^
