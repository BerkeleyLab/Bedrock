## newad Documentation

`newad.py` is a python script used for automatic address generation and port assignments. The main goal is to hide the complexity of dealing with registers inside FPGA and reduce the boilerplate code. 

The output (therefore functionality) of `newad.py` can be changed depending on how it is called from the CLI. 

The ports on the input verilog file can be marked as a register on the final address map. The marking is done by adding `external` comment. Additional properties of the given register can be indicated to the newad by extending the 'external comment with additional arguments. 

Users can call newad with -h option to see all of its arguments: 

```
usage: newad.py [-h] [-i INPUT_FILE] [-o OUTPUT] [-d DIR_LIST] [-a ADDR_MAP_HEADER] [-r REGMAP] [-l] [-m] [-pl] [-w LB_WIDTH]
                [-b BASE_ADDR] [-p CLK_PREFIX]

Automatic address generator: Parses verilog lines and generates addresses and decoders for registers declared external across module
instantiations

optional arguments:
  -h, --help            show this help message and exit
  -i INPUT_FILE, --input_file INPUT_FILE
                        A top level file to start the parser
  -o OUTPUT, --output OUTPUT
                        Outputs generated header file
  -d DIR_LIST, --dir_list DIR_LIST
                        A list of directories to look for verilog source files. <dir_0>[,<dir_1>]*
  -a ADDR_MAP_HEADER, --addr_map_header ADDR_MAP_HEADER
                        Outputs generated address map header file
  -r REGMAP, --regmap REGMAP
                        Outputs generated address map in json format
  -l, --low_res         When not selected generates a seperate address name for each
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

The 'main' input to the newad is essentially two arguments. The top verilog file to start the parser and the list of directories to go through. 

newad starts by parsing the top file and starts going deeper into the hierarchy. There is two main process is happening during this traverse;

1) Looking for verilog module instantiations marked `automatic`, for which newad needs to generate port assignments. When such an instantiation is found, it calls back itself recursively to look deeper into the hierarchy.

The following verilog snippet shows how instantiated verilog module is marked `auto` by a developer

```
digitizer_slowread digitizer_slowread // auto
(
        .lb_clk(lb_clk),
        .adc_clk(adc_clk),
        .adc_data(adc_data),
        .slow_snap(slow_snap),
        .slow_chain_out(slow_chain_out),
        .slow_read_lb(slow_read_lb),
        .tag_now(tag_now)
        //`AUTOMATIC_digitizer_slowread
);
```

In this example, ports marked with a macro `AUTOMATIC_digitizer_slowread` of this verilog module will be connected by newad generated wires/regs. 


2) Looking for input/output ports labeled 'external'. Record them in the port_lists dictionary for this module. Searches ports on each line of verilog code by looking at its directionality (while also catching if it is signed or not) and very specific verilog comment describing the other att


Following verilog snippet shows a single bit register defined as `external` indicating that it should be a register and it has a property of `single-cycle`

```
input prc_dds_ph_reset,  // external single-cycle
```


#### Register Attributes

Each port defined as 'external' using the comment of verilog, will end up as a register. Users can then attach additional features for this register by adding more attributes: 

Below is a list of those additional attributes for a register defined in newad: 

* single-cycle
* strobe
* we-strobe
* plus-we

% TODO: explain each of those options and how it changes the output




### Verilog Header Generation

when used with `-a` option, newad creates verilog header file for given top level object. This `.vh` file will contain following items: 

* Address Decoded lines

```
`define ADDR_HIT_digitizer_dsp_real_sim_mux_shell_0_dsp_ff_driver_mem (lb4_addr[0][`LB_HI:11]==4096) // digitizer_dsp bitwidth: 11, base_addr: 8388608

```

