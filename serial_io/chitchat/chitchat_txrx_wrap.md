This document provides an extended description of the chitchat_txrx_wrap module and its ports.

## Clocking
A total of 5 independent clock domains are supported; crossing between these domains is handled
by internal synchronizers. The user need not drive all of these independently.

* tx_clk - Clock domain used to drive user data in the tx_* ports.
* rx_clk - Clock domain of rx_* ports, on which return data is presented to the user.
* lb_clk - 'Register interface' clock domain on which status information is provided.
* gtx_tx_clk - Clock used for the (parallel) transmit channel of the serial transceiver.
* gtx_rx_clk - Clock used for the (parallel) receive channel of the serial transceiver.

## Transceiver connection

* gtx_tx_d - Parallel data sent to the transmit side of the serial transceiver.
* gtx_tx_k - Comma flag sent to the transmit side of the serial transceiver. While this
             2-bit signal can flag a comma in the lower and upper byte of gtx_tx_d, only
             the former is used. I.e., gtx_tx_k[1] is always 0.
* gtx_rx_d - Incoming parallel data from the receiver side of the serial transceiver.
* gtx_rx_k - Incoming comma flag from the receiver side of the serial transceiver. Only
             the LSB (least significant bit) will ever be non-zero.

## Data flow
The chitchat_txrx_wrap module cannot transmit data at full-rate, as it takes several cycles
to assemble a transmit packet and send it over the link. As a result, the input data stream
must be presented at a low enough rate, if dropped data elements are to be avoided.

* tx_transmit_en - Enables data transmission. Can be held high throughout.
* tx_valid{0,1} - Qualifies tx_data{0,1} as valid and causes it to be latched internally and
             transmitted on the next packet.
* rx_valid - Signals that valid return data is present in rx_data{0,1} and ready to be sampled.
* tx_extra_data - 128b of extra data
             transmitted 2 Byte per frame according to local_frame_counter[2:0] in 8 consecutive packets.
* rx_extra_data_valid - Signals that valid extra data is present in rx_extra_data and ready to be sampled.

## Status/Debug signals
All of the following qualify as status/debug signals and convey useful link information and statistics.

* txrx_latency
* rx_frame_counter
* rx_protocol_ver
* rx_gateware_type
* rx_location
* rx_rev_id
* ccrx_fault
* ccrx_fault_cnt
* ccrx_los
* ccrx_frame_drop
