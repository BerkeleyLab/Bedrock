## newad Documentation

`newad.py` is a python script used for automatic address generation. It does so by scanning the given verilog file and parses the port declaration. The output from newad.py is a `.json` file which includes all registers along with their specific properties.

The ports on the input verilog file can be 'marked' as a register on the final address map. The marking is done by adding `external` comment. Additional properties of the given register can be indicated to the newad by extending the 'external comment with additional arguments. 

Following verilog sniplet shows a single bit register defined as `external` indicating that it should be a register and it has a property of `single-cycle`

```
input prc_dds_ph_reset,  // external single-cycle
```


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

### Port Decleration Options

Each port defined as 'external' using the comment of verilog, will end up as a register. Users can then attach additional features for this register by adding more attributes: 

Below is a list of those additional attributes for a register defined in newad: 

* single-cycle
* strobe
* we-strobe
* plus-we

% TODO: explain each of those options and how it changes the output


### 