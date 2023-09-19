# ChitChat Serial Protocol

ChitChat is a simple, point-to-point, generic communication protocol, designed
to transmit non timing critical data between two FPGAs over a serial link. Side-band
information such as frame numbers, protocol identifiers and loop-back latency are
included to ease system integration.

The protocol expects data to be transmitted using 8b/10b line coding and uses a
periodically sent K28.5 comma character for framing. Note that the K28.5 comma is
always sent in the lower byte of the transmitted data.

The integrity of each transmitted packet is validated by a CRC16 check.

While the protocol was original conceived to transmit data over a Fiber link, nominally
at a rate of 2.5 GBd (16-bit data + 4-bit 8b/10b overhead) * 125 MHz), it could
conceivably be run at different rates or over a different medium.

## Packet format

Each packet consists of 11x 16-bit words, 4 of which contain the 64-bit of payload.

| Word  |        |
| ----: | :----- |
| 0     | PROTOCOL_CAT[3:0], PROTOCOL_VER[3:0], COMMA[7:0]    |
| 1     | GATEWARE_TYPE[2:0], TX_LOCATION[2:0], RESERVED[9:0] |
| 2     | REVISION_ID[31:16] |
| 3     | REVISION_ID[15:0] |
| 4     | TX_DATA0[31:16] |
| 5     | TX_DATA0[15:0] |
| 6     | TX_DATA1[31:16] |
| 7     | TX_DATA1[15:0] |
| 8     | TX_FRAME_COUNT[15:0] |
| 9     | TX_LOOPBACK_FRAME_COUNT[15:0] |
| 10    | CRC_CHECKSUM[15:0] |

## Link Up detection

The receiver will only consider the link to be up after successfully decoding 4
consecutive frames without errors. This value is held in a package constant
which can be modified at compile time.

Once up, the link will go down if the next K28.5 comma is not received within the
expected time-frame.

The receiver will signal the status of the link through the `loss of sync` status
register `ccrx_los`.

## Error detection

The receiver will check and report the following error conditions during decoding:
* Failed CRC check
* Incorrect Protocol or Gateware version received
* Non-incrementing frame number received

Decoding errors will cause the frame to be dropped, which is signaled by `ccrx_frame_drop`
and the type of error to be reported in the `ccrx_fault` register.

## Throughput and latency

As a result of the packet size, the TX and RX data throughput is 64-bit/11 clock-cycles.
Additionally, as the receiver must receive a full packet to be able to check the CRC, there
will necessarily be a full-frame latency (11 clock-cycles) before data is presented to the
user logic.
