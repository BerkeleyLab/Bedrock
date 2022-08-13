## SPI Boot Flash programming support in Packet Badger

Modern FPGAs typically have the ability to boot from SPI flash.
Then when operating, those flash pins are available for the fabric
to interact with.  Thus the FPGA can program its own boot flash.

Packet Badger includes a set of (synthesizable, portable) Verilog
modules to take advantage of this, and a host python program to
manipulate the system.

Verilog code:

* [spi_flash.v](spi_flash.v)
* [spi_flash_engine.v](spi_flash_engine.v)
* [reg_delay.v](../dsp/reg_delay.v)

They optionally reference Xilinx primitives ICAP_SPARTAN6 or ICAPE2.
When running on a Xilinx Spartan 6 or 7-Series FPGA, this allows
run-time selection among multiple bitfiles stored on a single flash chip.

Python (host) code:

* [spi_test.py](tests/spi_test.py)

# Write protect

Modern SPI flash chips include write-protect features.  This can be messy
and complicated.  Our goal is to make the system resistant to bricking,
by holding a "golden image" in a write-protected zone of the flash.
Two open-hardware example boards designed around that principle are

* [Marble](https://github.com/BerkeleyLab/Marble)
* [Marble-Mini](https://github.com/BerkeleyLab/Marble-Mini)

Other COTS boards like the SP605 and AC701 can also be used, but they
don't have the hardware switch on the flash chip's WP# line that can
guarantee protection of the golden image.

This discussion and software revolves around the write-protect feature
of a Cypress/Spansion S25FL128S,
as documented in the Cypress S25FL128S/S25FL256S data sheet,
128 Mb (16 MB)/256 Mb (32 MB) 3.0V SPI Flash Memory,
Document Number: 001-98283 Rev. *Q Revised April 30, 2019
```4cdc2a61d3d3125188d2840fbde574a1f41472a63febdda9698ce598af98817b  s25fl128s.pdf```
As a metric of the complexity of these chips, note that the data sheet
is 145 pages long!  I think the features discussed here are likely to show up
on other flash chips, but I can't confirm they are JEDEC-standard.

Use of the write-protect feature centers on two registers,
Status Register 1 (SR1) and Configuration Register 1 (CR1).
We demand that TBPROT is set, so the protected blocks are at low addresses.
This is important, because Xilinx FPGAs boot starting at address 0.

# Operation

Quoting p. 53 of that data sheet:
"The desired state of TBPROT must be selected during the initial configuration
of the device during system manufacture; before the first program or erase
operation on the main flash array. TBPROT must not be programmed after
programming or erasing is done in the main flash array."

The board first needs to have a Packet Badger-based bitfile loaded
over JTAG.  Ethernet must be connected and routed to your workstation,
so you can `ping $IP`.  Put your shell in the `badger/tests` directory
for the steps below.

```bash
python3 spi_test.py --ip $IP --id
```

If this comes back CONFIG_REG (CR1) = 0x00, this chip is likely
fresh-from-the-factory.  Make sure the Write Protect switch is off, then

```bash
python3 spi_test.py --ip $IP --config_init
python3 spi_test.py --ip $IP --id
```

Now it should report CONFIG_REG (CR1) = 0x20, with the TBPROT bit set.

To program the golden image at address zero,
make sure the Write Protect switch is off,

```bash
python3 spi_test.py --ip $IP --add 0 --program $BITFILE --force_write_enable
```

and then turn the Write Protect switch on.

To program an application image in the second half of the 16 MByte
flash chip, leave the Write Protect switch on, and

```bash
python3 spi_test.py --ip $IP --add 8388608 --program $BITFILE
```

When running the golden bitfile after a power cycle or hardware reset,
reboot to that second-half bitfile with

```bash
python3 spi_test.py --ip $IP --reboot7 --add 8388608
```

If you get in trouble, make liberal use of

```bash
python3 spi_test.py --ip $IP --clear_status
python3 spi_test.py --ip $IP --id
```
