# LTM4673 synchronization

Applies to Marble v1.4 and higher.

I *really* don't like [EMI](https://en.wikipedia.org/wiki/Electromagnetic_interference).
As Brian Chase points out, typical accelerator instrumentation
has noise sensitivity that's more akin to a radio telescope than
it is to traditional telecom gear.
If there *is* EMI in a system, I want it at a precisely pinned frequency
so I can at least identify and possibly reject it "in software".

Switching power supplies in general are a common source of EMI,
and that's potentially true of [Marble](https://github.com/BerkeleyLab/Marble)
with its [LTM4673](https://www.analog.com/en/products/ltm4673.html).
Fortunately, the LTM4673 has a mechanism to align its switching
frequencies to an external source.

This FPGA code sends frequency (and phase!) control signals,
based on the system 125 MHz clock, to the LTM4673 using its
CLKIN0, CLKIN12, CLKIN3 pins that are directly connected to the FPGA.
See [`ltm_sync.v`](ltm_sync.v).

The feature is controlled by LEEP register `ps_sync_config`.

- 0 (default)  enable CCM (continuous conduction mode), recommended to
  reduce low-frequency EMI contributions
- 1-7  disable CCM on specified bits
- 16-31  run 12A channels 0 and 3 at `125 MHz / (10*ps_sync_config)`,
  and the 5A channels 1 and 2 at `125 MHz / (6*ps_sync_config)`.

Closest match to the design frequencies is with `ps_sync_config=21`.
The data sheet claims the regulator will sync at nominal +/- 30%,
or `17 <= ps_sync_config <= 29`.
