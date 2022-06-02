## newad Documentation

`newad.py` is a python script used to simplify creation of software-settable
registers within Verilog, typically in an FPGA context.  The amount of
boilerplate code required is marginally zero.  In the background, addresses
are generated and bus decoders are created.

The current version is based on "magic comments" (see examples below), which
imposes some limitations on its use. We have hopes to rewrite the system
someday to use Verilog attributes and a Real Verilog parser.

Ports on the input Verilog file can be marked (using an `external` comment)
as a register to show up in the final address map. Some properties of those
registers can be controlled with additional flags in the comment.

The output (therefore functionality) of `newad.py` can be changed depending on
how it is called from the CLI.  These calls are typically buried in a Makefile.
Users can call newad with -h option to see all of its arguments:

```
usage: newad.py [-h] [-i INPUT_FILE] [-o OUTPUT] [-d DIR_LIST]
                [-a ADDR_MAP_HEADER] [-r REGMAP] [-l] [-m] [-pl] [-w LB_WIDTH]
                [-b BASE_ADDR] [-p CLK_PREFIX]

Automatic address generator: Parses Verilog lines and generates addresses and
decoders for registers declared external across module instantiations

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_FILE, --input_file INPUT_FILE
                        A top level file to start the parser
  -o OUTPUT, --output OUTPUT
                        Outputs generated header file
  -d DIR_LIST, --dir_list DIR_LIST
                        A list of directories to look for Verilog source files. <dir_0>[,<dir_1>]*
  -a ADDR_MAP_HEADER, --addr_map_header ADDR_MAP_HEADER
                        Outputs generated address map header file
  -r REGMAP, --regmap REGMAP
                        Outputs generated address map in json format
  -l, --low_res         When not selected generates a separate address name for each
  -m, --gen_mirror      Generates a mirror where all registers and register arrays with size < 32are available for readback
  -pl, --plot_map       Plots the register map using a broken bar graph
  -w LB_WIDTH, --lb_width LB_WIDTH
                        Set the address width of the local bus from which the generated registers are decoded
  -b BASE_ADDR, --base_addr BASE_ADDR
                        Set the base address of the register map to be generated from here
  -p CLK_PREFIX, --clk_prefix CLK_PREFIX
                        Prefix of the clock domain in which decoding is done [currently ignored], appends _clk

```


### The workflow of newad

The main input to newad is essentially two arguments: the top Verilog file
to start the parser, and the list of directories where modules can be found.

newad starts by parsing the top file, and then starts going deeper into the
hierarchy. There are two main processes happening during this traverse:

1) Looking for input/output ports labeled `external`. These will turn into
software-settable registers. Some of its properties are deduced from the
native Verilog syntax: bit width, signed or not.  Additional options can be
set by more magic comments; see below.

The following Verilog snippet shows a 12-bit register defined as `external`.

```verilog
        input [11:0] phase_step, // external
```

2) Looking for Verilog module instantiations marked `auto` (short for automatic),
for which newad needs to generate port assignments. When such an instantiation
is found, newad recurses to look deeper into the hierarchy.

The following Verilog snippet shows how an instantiated Verilog module is
marked `auto` by a developer:

```verilog
pair_couple drive_couple // auto
        (.clk(clk), .iq(iq),
        .drive(prompt_drive), .lo_phase(lo_phase_d),
        .pair(fwd_ref),
        `AUTOMATIC_drive_couple
);
```

In this example, software-settable ports found within drive_couple will
get filled in using the machine-generated macro `AUTOMATIC_drive_couple`.
These ports will be automatically propagated outwards to the bus controller
and decoder.


#### Register Attributes

Each port defined as `external` using the comment of Verilog will end up as a
software-settable register with an automatically-assigned address. Users can
modify features of this register by adding more attributes:

* single-cycle: the register will only stay high (asserted) for a single
cycle when written.  Maps nicely to operations like "clear" and "trigger",
where no state is held in the register.
* we-strobe: reserved for special cases where the register semantics requires
access to the write-enable signal *plus* the data bus, like pushing into a FIFO.
Implementing that behavior, given the write-enable strobe, is still the job of
the HDL program.


### Verilog Header Generation

When used with `-a` argument, newad creates a Verilog header containing the
address map for given top level object. This file will have the name
`addr_map_<module_name>.vh`. Inside the file, newad will place all address
decoding for each register.

The following is an example of a decoded register address macro definition.

```verilog
`define ADDR_HIT_digitizer_dsp_real_sim_mux_shell_0_dsp_ff_driver_mem (lb4_addr[0][`LB_HI:11]==4096) // digitizer_dsp bitwidth: 11, base_addr: 8388608
```

When used with `-r` argument, newad creates an address map in `.json` format.


### Managing clock domains

By default, registers are set in the `lb_clk` domain in the top-level bus
controller module.  There are two provisions to override that.

1) In an instantiation, the default clock domain for ports for that instance
can be set.  Example:

```verilog
prc_dsp prc_dsp // auto clk1x
        (.clk(adc_clk), .qmode(qmode[1:0]), .adc_data(adc_data),
        .iq_result1(iq_cav01), .iq_result2(iq_cav23), .qmode_out(qmode_out),
        .cosd(cosa), .sind(sina), .phase_zero(phase_zero), .fwd_in(fwd_in), .rev_in(rev_in), .phs_avg_sum(phs_avg_sum),
        `AUTOMATIC_prc_dsp
);
```

Registers in the prc_dsp module will be created in the clk1x_clk domain
(happens to be equivalent to adc_clk).

2) Within a list of ports, the clock domain can be set in a sticky manner
with comments of the form ``newad-force foo domain``.  Example:

```verilog
        // newad-force lb domain
        input [0:0] trace_reset_we,  // external we-strobe
        input [0:0] trace_ack,  // -- external single-cycle
        // newad-force clk1x domain
        input [0:0] trace_reset,  // -- external single-cycle
        input [13:0] cic_period,  // external
        input [7:0] trace_keep, // external
        input [3:0] cic_shift, // external
        // newad-force lb domain
        input start_fdbk_dac_enable,  // external
        input buf_trig,  // external
        // newad-force clk2x domain
        input [15:0] amplitude,  // external
        input [19:0] ddsa_phstep_h,  // external
        input [11:0] ddsa_phstep_l,  // external
        input [11:0] ddsa_modulo,  // external
```

The result will include `cic_period` in the `clk1x_clk` domain, and `buf_trig`
in the `lb_clk` domain. The hope is that option (1) will cover most use cases.

Note also in this example that the trace_ack and trace_reset ports will *not*
be managed by newad.  The extra `--` intentionally disables the pattern-match
for the `external` keyword.

You are encouraged to occasionally cross-check the register decoder produced
by newad with its `-o` flag, typically named `<module_name>_auto.vh`, to make
sure clock domains and other behavior are emitted as intended.  Those files
can be long, but should be legible to Verilog programmers.  They even have
helpful comments at the beginning showing how newad has traversed the Verilog
hierarchy.

It is the responsibility of the bus controller to create local busses in each
of the clock domains needed by its submodules.


### Register names and uniqueness

Software-visible register names are created based on the instance hierarchy.
For example, `ssa_stim_ampstep` is a name generated for register `ampstep`
in module instance name `ssa_stim`.  The newad-generated json file contains
the mapping from name to (generated) address.  That json file is normally
compressed, held in FPGA memory, and made available to software.  Application
software can therefore always refer to registers by name.

A more exotic example is `shell_1_dsp_fdbk_core_mp_proc_sel_thresh`.  Here
the instance name hierarchy is `shell`, `dsp`, `fdbk_core`, `mp_proc`, the
register name is `sel_thresh`, and the extra `1` comes from `shell` being
created in a Verilog generate loop.  The (abbreviated) syntax for that example
is

```verilog
genvar c_n;
generate for (c_n=0; c_n < 2; c_n=c_n+1) begin: cryomodule_cavity
    llrf_shell shell // auto(c_n,2) lb4[c_n]
        (.clk(adc_clk),
        ...
        `AUTOMATIC_shell
    );
end endgenerate
```
