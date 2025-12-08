# EVent Generator (EVG) and EVent Receiver (EVR)

The EVG/EVR timing system is based on the [Micro-Research Finland (MRF) timing architecture](http://www.mrf.fi/dmdocuments/EVG-TREF-004.pdf).
This architecture is widely used in accelerator facilities, including:

* LBNL ALS/ALS-U synchrotron light source
* SLAC LCLS-I (LEMP timing system)

Both systems derive their timing from the MRF model, with site-specific customizations.

## Overview of EVG/EVR Operation

The EVG transmits timing information as a continuous stream of event frames.
Each frame contains:

* 8-bit Event Code - identifies the timing event
* 8-bit Distributed Data Bus - carries 8 parallel signals, sampled at the event clock rate

The Distributed Data Bus is used to transmit multiple simultaneous binary signals alongside the event code.
This allows for real-time broadcast of fast control/status flags without requiring additional event codes.

### Event Transmission Rules
* Maximum event codes: 256 (0x00-0xFF)
* Only one event code is transmitted at a time
* If there is no specific event to transmit, the EVG sends:
  * Null event code (`0x00`), or
  * Special K28.5 comma character (`0xBC`) for alignment

The K28.5 character is used by EVRs to synchronize to the correct word boundary in the serial stream.

### Standard Event Code Definitions
| Event Code  |         Description           |
|-------------|-------------------------------|
| `0x01-0x6F` |     User-defined events       |
| `0x70`      | Seconds counter, byte 0 (LSB) |
| `0x71`      |     Seconds counter, byte 1   |
| `0x72-0x79` |        User-defined events    |
| `0x7A`      |         Heartbeat             |
| `0x7B`      |      Synchronize prescalers   |
| `0x7C`      |  Timestamp counter increment  |
| `0x7D`      |    Timestamp counter reset    |
| `0x7F`      |        End of Sequence        |

## ALS/ALS-U Implementation
* EVR Hardware:
  * Marble board or Xilinx ZCU208 FPGA board
  * GTX or GTY transceivers
  * SI570 programmable on-board oscillator for reference clock generation

* Distributed Data Bus Usage:
  * Bit 0 - General-purpose signal
  * Bit 1 - Heartbeat (HB)
  * Bit 2 - 100 kHz reference signal
  * Remaining bits - Reserved or user-defined

## LCLS-I Implementation
* EVR Hardware:
  * Marble board
  * SI570 programmable on-board oscillator programmed to 119 MHz

* Reference Frequency Derivation:
  * Master Oscillator (MO) frequency: 476 MHz
  * 119 MHz = MO / 4 = 476 MHz / 4

* Timing Pattern Transmission:
  * LCLS-I sends timing pattern frames at 120 Hz
  * In some modes, 119 MHz is divided down to 360 Hz
  * `119 MHz / 360 Hz = 330,000 clock cycles` per 360 Hz period
  * Of these, 33 timing slots are used to transmit pulse ID or other control patterns

## Transceiver configuration (TODO: Make GTY also generic and add GTP)
The `gt_tcl` directory contains all the TCL scripts required for GTX/GTY transceiver configuration. **Only RX channel is enabled**
* Example usage:
  To use `evr_gtx.tcl`, you must pass the reference frequency as a parameter.
  The script will then automatically compute the line rate based on the provided reference frequency.

#### Notes on Distributed Bus Usage
The 8-bit distributed bus exists because some timing signals need to be broadcast continuously and in parallel with event codes.
Examples include:
* Machine status flags
* Fast interlocks
* Beam mode indicators
* RF synchronization markers
This allows the EVR to act on both event-based triggers and continuous state signals without extra latency.
