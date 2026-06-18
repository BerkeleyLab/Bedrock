# Marble Platform Support for I2CBridge Programming

## One-shot I2C transactions
The script `oneshot.py` is included here to allow composing and running single-transaction
`i2cbridge` programs to a live target with a (hopefully) user-friendly interface.  Without
worrying about the I2C tree on the Marble board or chip addresses, you can simply read from
or write to any register in any chip just referring to the chip by name (refdes on the
schematic).

Example: turn on LD13 via the GPIO expander U39 by writing to register 3
__WARNING__: The user LEDs are on the same port as `/CLKMUX_RST` which means we can shut down the board on accident
if we aren't very careful to ensure we always keep bit 7 asserted when writing to this register!
```sh
PYTHONPATH=../../../peripheral_drivers/i2cbridge:$PYTHONPATH python3 oneshot.py leep://$IP:$PORT U39.3=0x80
```

Example: turn off LD13
```sh
PYTHONPATH=../../../peripheral_drivers/i2cbridge:$PYTHONPATH python3 oneshot.py leep://$IP:$PORT U39.3=0x88
```

Example: read the inputs to port 0 on the GPIO expander U39 by reading from register 0
```sh
PYTHONPATH=../../../peripheral_drivers/i2cbridge:$PYTHONPATH python3 oneshot.py leep://192.168.19.40:803 U39.0
```

_(The following demos assume you have exported `PYTHONPATH` for brevity)_

We can also read more than 1 byte (very much dependent on the specifics of the IC's I2C implementation).
Example: read shunt voltage (addr 1, 16 bits) from INA219 U57
```sh
python3 oneshot.py leep://$IP:$PORT U57.1:2
# Note the ':' instead of a '=' (the latter indicates a write!)
```

Note that you can perform many transactions in one "one shot" program, including adding pauses between
transactions, as in this demo disabling and re-enabling QSFP1 channel 0:
```sh
python3 oneshot.py leep://$IP:$PORT J17.86=1 J17.86=0
```

And breaking the "one shot" model, you can tell the program to continue looping after the script exits.
This demo makes LD13 continually blink.
```sh
python3 oneshot.py leep://$IP:$PORT U39.3=0x80 pause=500 U39.3=0x88 pause=500 -l
```

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
