// ------------------------------------
// chitchat_tx.v
//
// TX side of the Chitchat inter-chassis communication protocol, which can be used
// to communicate cavity status information (e.g. detune, interlock) between two
// FPGA chassis over fiber.
//
/// NOTE: There's no valid/strobe input to this module, since input data is sampled
//        periodically, at a fixed rate. In order to control what data gets sent over the line,
//        latching of input data with a valid/strobe must be done externally.
//
// See README.md for protocol specification.
//
// ------------------------------------

module chitchat_tx #(
   parameter       REV_ID = 0,  // 32-bit ID (e.g. git commit)
   parameter [2:0] TX_GATEWARE_TYPE = 0 // Gateware type to send out on TX packets
) (
   input         clk,

   input         tx_transmit_en, // Keeps the TX line active (with commas + data)
                                 // RX-end only accepts data after LINK_UP_CNT
                                 // successfully decoded data/comma pairs

   output        tx_send,       // Pulsed periodically on each issued
                                 // transaction, as long as TX line is active

   input  [2:0]  tx_location, // ID of a particular transmitter
   input  [31:0] tx_data0,
   input  [31:0] tx_data1,
   input  [255:0] tx_extra_data, // 32B of extra data transmitted 2 Byte per frame according to local_frame_counter[3:0]
   input  [15:0] tx_loopback_frame_counter, // intended from chitchat_rx

   output [15:0] local_frame_counter,

   output [15:0] gtx_d,
   output [1:0]  gtx_k // Signal comma in lower byte of Tx data (MSB is unused)
);

`include "chitchat_pack.vh"

   // Timing generator
   reg start=0, sync=0, sync_r=0, last=0, last_r=0, crc_time=0;
   reg [3:0] word_count=0;
   wire increment = tx_transmit_en | (word_count!=0);

   always @(posedge clk) begin
      word_count <= word_count == WORD_FRAME_CNT ? 0 : word_count + increment;
      start      <= word_count == 1;
      sync       <= start;
      sync_r     <= sync;
      last       <= word_count == WORD_FRAME_CNT;
      last_r     <= last;
      crc_time   <= last_r;
   end

   // Frame creation
   reg  [15:0] frame_counter          = 0;
   reg  [12*16-1:0] frame             = 0;  // parallel in, 16-bit words out

   // Fixed-bit-width form of input parameters
   wire [3:0]  protocol_cat      = CC_PROTOCOL_CAT;
   wire [3:0]  protocol_ver_fix  = CC_PROTOCOL_VER;
   wire [2:0]  gateware_type_fix = TX_GATEWARE_TYPE;
   wire [31:0] rev_id_fix        = REV_ID;
   wire [7:0]  comma_pad         = CC_K28_5; // K28.5
   wire [9:0]  reserved          = 0;
   wire [15:0] crc_pad           = 0;

   // extra_data
   reg  [255:0] tx_extra_data_fix         = 0;
   reg  [15:0]  tx_extra_word_r           = 0;

   always @(posedge clk) begin
      frame_counter <= frame_counter + start;
      // one full frame is 11 x 16-bit words
      frame <= start ? { protocol_cat, protocol_ver_fix, comma_pad,
                         gateware_type_fix, tx_location, reserved,
                         rev_id_fix,
                         tx_data0,
                         tx_data1,
                         frame_counter,
                         tx_loopback_frame_counter,
                         tx_extra_word_r,
                         crc_pad } :
                       { frame[WORD_FRAME_CNT*16-1:0] , 16'b0 };
      // Note the big-endian treatment of 32-bit inputs
   end

   // Extra data serialization in the frame
   always @(posedge clk) begin
	// there are 16 word available and the frame counter 4 LSB are used to populatre them
	case(frame_counter[3:0])
	  // memorize the pulseid at the beginning of the slot if is valid
	  4'h0: begin
		tx_extra_word_r      <= tx_extra_data[15:0];
		tx_extra_data_fix    <= tx_extra_data;
	   end
	   4'h1: tx_extra_word_r <= tx_extra_data_fix[31:16];
	   4'h2: tx_extra_word_r <= tx_extra_data_fix[47:32];
	   4'h3: tx_extra_word_r <= tx_extra_data_fix[63:48];
	   4'h4: tx_extra_word_r <= tx_extra_data_fix[79:64];
	   4'h5: tx_extra_word_r <= tx_extra_data_fix[95:80];
	   4'h6: tx_extra_word_r <= tx_extra_data_fix[111:96];
	   4'h7: tx_extra_word_r <= tx_extra_data_fix[127:112];
      4'h8: tx_extra_word_r <= tx_extra_data_fix[143:128];
      4'h9: tx_extra_word_r <= tx_extra_data_fix[159:144];
      4'ha: tx_extra_word_r <= tx_extra_data_fix[175:160];
      4'hb: tx_extra_word_r <= tx_extra_data_fix[191:176];
      4'hc: tx_extra_word_r <= tx_extra_data_fix[207:192];
      4'hd: tx_extra_word_r <= tx_extra_data_fix[223:208];
      4'he: tx_extra_word_r <= tx_extra_data_fix[239:224];
      4'hf: tx_extra_word_r <= tx_extra_data_fix[255:240];
	   //default: tx_extra_word_r ;
	 endcase
  end

  // CRC generation
  wire [15:0] crc_tx;
  wire [15:0] inner_data = frame[(WORD_FRAME_CNT+1)*16-1:WORD_FRAME_CNT*16];
  reg  [15:0] outer_data = 0;

  crc16 crc16_tx(
     .clk  (clk),
     .din  (inner_data),
     .zero (sync),
     .crc  (crc_tx)
  );

  always @(posedge clk) begin
     outer_data <= crc_time ? crc_tx : inner_data;
  end

  // Assign output ports
   assign tx_send   = start;
   assign gtx_d     = outer_data;
   assign gtx_k     = {1'b0, sync_r}; // No comma in upper byte
   assign local_frame_counter = frame_counter;

endmodule
