# RISC-V SOC

An open-source system on a chip based on the [PicoRV32](https://github.com/YosysHQ/picorv32) softcore.

# Tested hardware platforms

* Digilent Cmod A7
* Xilinx KC705 + FMC150
* Xilinx VC707 + FMC120
* Marblemini + Zest

# Projects at LBNL

* Advanced Light Source digital Low-Level-RF Control System
* DOE Early Career Research Program: Scalable Control for Coherent Laser Combining

# Tools needed

## Cross compiling tools
* Tested in Debian 11:
   * `sudo apt install iverilog gtkwave gcc-riscv64-unknown-elf picolibc-riscv64-unknown-elf`
* Tested in MacOS 12.1:
   * Equivalent to step 3 (RiscV tool chain) in [litex](https://github.com/enjoy-digital/litex) installation:
   * `pip3 install meson ninja`
   * `wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-8.3.0-2019.08.0-x86_64-apple-darwin.tar.gz`, unpack and add binary directory to `PATH`.
   * build and install `picolibc` into `/usr/local/picolibc` following its building [instructions](https://github.com/picolibc/picolibc/blob/main/doc/build.md):
```bash
mkdir -p /usr/local/picolibc
git clone https://github.com/picolibc/picolibc
cd picolibc
mkdir build-riscv64-unknown-elf
cd build-riscv64-unknown-elf
../do-riscv-configure
ninja
ninja install
```

## Synthesis tool
* Xilinx Vivado (tested between 2015.3 to 2017.4, 2018.1, 2018.3, 2020.2) suite

# Features

## System simulation

Each feature is independently tested under `test/` directory with a `PASS/FAIL` check using `iverilog` simulator.

Each project has a system level test bench `system_tb.v`. Use `make system.vcd` to generate waveforms that are viewable using `gtkwave`.

## Peripheral support

* SPI master (hardware)
* I2C master (software)
* One wire   (software)
* UART       (hardware)
* GPIO       (hardware)

## Xilinx AXI-lite bus bridge

Implemented using `picorv32_axi_adapter` as used in `vc707_fmc120` project.

## LBNL localbus bridge

LBNL localbus is a non-blocking bus that is typically controlled by UDP
Ethernet engine. When it comes to the case where a CPU wants to play as a
master as well, one has to deal with conflicts between the two masters
without lost of information.  The philosophy is to put localbus top priority
because that `picorv32` is capable of handling retries and yields.  This is
done by `gateware/lb_bridge.v`.

Details see simulations in `test/lb_bridge`, where all read/write
collision cases are tested.

## System synthesize

Within each project directory, use `make` to synthesize a bitstream file.

## FPGA config

Use `make system_config` to program the FPGA with a bitstream file, using `xc3sprog` or
Digilent Adept2, which is available from
[digilent](https://digilent.com/reference/software/adept/start).

## Reload CPU program without re-synthesizing

Once the core is running, it launches into a serial bootloader program. From there, a new firmware can be quickly loaded and verified with `make system_load`.

* For KC705/VC707, UART CTS pin is used to remote hardware reset;
* For all cases, writing 0x14 (Ctrl+T) to UART will trigger software cpu reset and start from
  bootloader.

## Memory size

Currently the program is stored in fpga block-ram.
Its size can be adjusted (in bytes) in the Makefile with the parameter `MEM_SIZE` in each project.
This gets passed to the linker (to print memory utilization), assembler (to set the C stack-pointer) and synthesizer (to set the size of the block-ram segment).

# Getting started

running all the testbenches

```bash
cd test
make clean all
```

the demo project

```bash
cd project/cmod_a7
```

Simulate it (needs iverilog). Note that the Makefile will compile the C program automatically and generate a 32 bit .hex file which is loaded by system.v in memory. The testbench contains a virtual UART, which receives serial data from system.v and prints it to the console.

```bash
make clean system.vcd
```

Show waveforms

```bash
make clean system_view
```

Synthesize

```bash
make clean system_synth.bit
```

Configure FPGA with bit-file (needs xc3sprog).

```bash
make system_config
```

At this point the demo-program should run and it should be possible to interact with it through serial at 115200 baud. For example through miniterm.py, assuming the usb serial port appears at /dev/ttyUSB0

```bash
miniterm.py /dev/ttyUSB0 115200
```

The serial bootloader can be used to change the program (stored in ram) quickly without the need to re-synthesize.

```bash
make clean system_load
```
