# SPI Boot Flash programming support in Packet Badger

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

## Write protect

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
of a Spansion/Cypress/Infineon S25FL128S
(note that Spansion merged with Cypress in 2014,
which was in turn acquired by Infineon in 2020).
See the Infineon [data sheet for S25FL128S, S25FL256S](https://www.infineon.com/dgdl/Infineon-S25FL128S_S25FL256S_128_Mb_%2816_MB%29_256_Mb_%2832_MB%29_3.0V_SPI_Flash_Memory-DataSheet-v18_00-EN.pdf?fileId=8ac78c8c7d0d8da4017d0ecfb6a64a17),
001-98283 Rev. *R, 2022-06-10.

```
fc4dff8ef4d8ebf6815c1e994812f8177c917b63c59a4913b7360eef01785af6  Infineon-S25FL128S_S25FL256S_128_Mb_(16_MB)_256_Mb_(32_MB)_3.0V_SPI_Flash_Memory-DataSheet-v19_00-EN.pdf
```

As a metric of the complexity of these chips, note that the data sheet
is 165 pages long!  I think the features discussed here are likely to show up
on other flash chips, but I can't confirm they are JEDEC-standard.

Use of the write-protect feature centers on two registers,
Status Register 1 (SR1) and Configuration Register 1 (CR1).
We demand that TBPROT is set, so the protected blocks are at low addresses.
This is important, because Xilinx FPGAs boot starting at address 0.

## Operation

Quoting p. 55 of that data sheet:
"The desired state of TBPROT must be selected during the initial configuration
of the device during system manufacture; before the first program or erase
operation on the main flash array. TBPROT must not be programmed after
programming or erasing is done in the main flash array."

Other crucial paragraphs to read are p. 52 about the Status Register
Write Disable (SRWD) bit SR1[7], and p. 56 about the Freeze Protection
(FREEZE) bit CR1[0].

The board first needs to have a Packet Badger-based bitfile loaded
over JTAG.  Ethernet must be connected and routed to your workstation,
so you can `ping $IP`.  Put your shell in the `badger/tests` directory
for the steps below.

```sh
python3 spi_test.py --ip $IP --id
```

If this comes back CONFIG_REG (CR1) = 0x00, this chip is likely
fresh-from-the-factory.  Make sure the Write Protect switch is off, then

```sh
python3 spi_test.py --ip $IP --config_init
python3 spi_test.py --ip $IP --id
```

Now it should report CONFIG_REG (CR1) = 0x21, with the TBPROT and FREEZE
bits set.  Because of the OTP (one-time-programmable) nature of bits in CR1,
this step has not been extensively tested.

To program the golden image at address zero,
make sure the Write Protect switch is off, use the --id feature
to check that the FREEZE bit is off (may require a power-cycle), and

```sh
python3 spi_test.py --ip $IP --add 0 --program $BITFILE --force_write_enable
```

and then turn the Write Protect switch on.

To program an application image in the second half of the 16 MByte
flash chip, leave the Write Protect switch on, and

```sh
python3 spi_test.py --ip $IP --add 8388608 --program $BITFILE
```

When running the golden bitfile after a power cycle or hardware reset,
reboot to that second-half bitfile with

```sh
python3 spi_test.py --ip $IP --reboot7 --add 8388608
```

If you get in trouble, make liberal use of

```sh
python3 spi_test.py --ip $IP --clear_status
python3 spi_test.py --ip $IP --id
```

## Performance

Quick comment about timing, approximate of course.
With a Kintex 7K160 and its 6693 kByte bitfile,

* 1 second boot from flash (SPI_BUSWIDTH 2, CONFIGRATE 33)
* 4 second program via USB JTAG (openocd adapter_khz 15000)
* 146 second program flash via Ethernet and spi_flash.v

So while flash is great for deploying production bitfiles, it's not
the best choice for edit/synthesize/test development cycles.
