# (w)ctrace Usage Instructions

`wctrace.v` is a Verilog module to readout waveforms on target FPGA hardware.
It's a simple extension of `bedrock/homeless/ctrace.v` which allows for data widths up
to `256-tw` (where `tw` is the number of bits of time accuracy, typically 24).

A more user-friendly deployment of `wctrace` is under [very sporadic development](https://gitlab.lbl.gov/kpenney/openila).
This deployment requires some hand-editing.

## Live demo

```sh
# In one terminal, build and run the Verilator "live" model
make wctrace_live
./wctrace_live +udp_port=3010

# In another terminal, acquire 'scope traces with ctracer.py and save to "test.vcd"
PYTHONPATH=../common python3 ctracer.py get leep://localhost:3010 -c config.in -o test.vcd --runtime 1

# Optionally include a generated clk of net name "dclk" in your VCD as well (can substantially increase file size)
PYTHONPATH=../common python3 ctracer.py get leep://localhost:3010 -c config.in -o test.vcd --runtime 1 --clk dclk

# View the resulting VCD file in gtkwave
gtkwave test.vcd
```

## Customizing for your application
The hand-editing mentioned above is to communicate the following to ctracer.py:
  1. The wctrace parameters
  2. The signals that are being logged
  3. How to interact with wctrace (register names or addresses)

All the above is included in a single file which is passed to `ctracer.py` via the `-c` flag to the
`get` subcommand.  The syntax of this file is super simple: see `config.in` for all the detail you'll need.
The only magic is in the parsing of the signal assignments which can be declared in a few ways.

For a one-bit signal, we can assign it to any index of the input vector (any index from `0` to `DW-1`)
where `DW` is the width of the `wctrace` `data` port.
```
# [index] = signal_name
[0] = foo
```

We can similarly map just a single bit of a vector.
```
# [index] = signal_name[bit]
[4] = bar[7]
```

Can map a range of input indices to a single vector (lengths are assumed to match).
```
# [index_high:index_low] = signal_name
[7:4] = baz
# Interprets as [7]=baz[3], [6]=baz[2], [5]=baz[1], [4]=baz[0]
```

Or map a range of input indices to slice of a vector (lengths must match).
```
# [index_high:index_low] = signal_name[index_high:index_low]
[13:12] = baz[2:1]
# Interprets as [13]=baz[2], [12]=baz[1]
```

__Note__: In all the above examples, the name of the signal can contain scope dereference
(i.e. `top.my_module.dut.foo`).  In this case, the resulting VCD will group signals by
scope in the expected way.
