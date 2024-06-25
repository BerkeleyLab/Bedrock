# (w)ctrace Usage Instructions

`wctrace.v` is a Verilog module to readout waveforms on target FPGA hardware.
It's a simple extension of `bedrock/homeless/ctrace.v` which allows for data widths up
to `256-tw` (where `tw` is the number of bits of time accuracy, typically 24).

A more user-friendly deployment of `wctrace` is under [very sporadic development](https://gitlab.lbl.gov/kpenney/openila).
This deployment requires some hand-editing.

## Live demo

```sh
# In one terminal, build and run the Verilator "live" model
cd mimo_dsp
make Vmem_gateway_wrap
./Vmem_gateway_wrap +udp_port=3010

# In another terminal, acquire 'scope traces with ctraceparser.py and save to "test.vcd"
PYTHONPATH=../submodules/bedrock/projects/common python3 ctraceparser.py get leep://localhost:3010 -f test.vcd

# View the resulting VCD file in gtkwave
gtkwave test.vcd
```

## Customizing for your application

The live demo above logs the waveforms, which are just 8 bits of a counter. To actually log
useful data, we need to route the desired nets into ctrace.

```verilog
// Add whatever nets you need to debug
assign ctrace_data[0] = net_foo;
assign ctrace_data[3:1] = net_bar[2:0];
```

The names of these nets should be communicated to ctraceparser.py for easy debugging.
We'll come up with an easy way to do this if we end up changing nets a lot.  For now,
it can be hard-coded in [ctraceparser.py](./ctraceparser.py) by elaborating `Config.get()`
