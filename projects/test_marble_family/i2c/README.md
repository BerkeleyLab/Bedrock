# Marble Platform Support for I2CBridge Programming

## Usage:

These tools assume usage of the i2cbridge modules in `bedrock/peripheral_drivers/i2cbridge`.
See the readme there for documentation on i2cbridge ('i2c\_chunk').
While `i2cbridge` is a generic (platform-independent) tool, there is a lot of benefit to
be gained by wrapping the generic tool in a platform-specific interface such as this.

Pros:
    1. Better self-documentation
    2. Requires no knowledge of I2C addresses or bus multiplexing
    3. Code can be easily ported to another platform with a compatible support package

## Demos:

See the file `demo_marble_i2c.py`.  This is a demonstration application-specific I2C program
generator.  The function `build_prog` contains the full program instructions and is easy to
read and (hopefully) understand.  This program can generate four different output files which
can all be made my simply running `make`.

### Generate program and memory maps

|Generated File | Description |
|---------------|-------------|
|prog.dat       | Actual program bytes (in hex-ascii) for `i2c_chunk` to run                      |
|prog.vh        | Map of all values read and their locations and sizes in memory (Verilog format) |
|prog.h         | Map of all values read and their locations and sizes in memory (C format)       |
|prog.json      | Map of all values read and their locations and sizes in memory (JSON format)    |
|---------------|---------------------------------------------------------------------------------|


### Test 1: Decode the program

`make decode`

A handy tool included here is a decoder that is "platform-aware".  This decoder attempts to recognize
reads and writes to various ICs based on their I2C address.  If it is known to the Marble I2C map, it
replaces the address with the IC name in the output, making it easier to read.

### Test 2: Decode the program without platform awareness

`make generic_decode`

As a contrast to the above, the program can also be decoded with the generic decoder included with the
i2cbridge tools.  Note the difference in readability from the application perspective.

### Test 3: Test assembler violations

This last test is not truly platform-specific but shows various violations of the I2C assembler rules
using the Marble platform-aware interface.  None of the rules violated are specific to the platform.

`make violations`

See `demo_i2c_baddy.py` for examples of what to avoid.
