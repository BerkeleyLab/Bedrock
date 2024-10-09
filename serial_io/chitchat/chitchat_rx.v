// ------------------------------------
// chitchat_tx.v
//
// TX side of the Chitchat inter-chassis communication protocol, which can be used
// to communicate cavity status information (e.g. detune, interlock) between two
// FPGA chassis over fiber.
//
// See README.md for protocol specification.
//
// NOTE: This module depends on the K28.5 comma code (inserted as frame marker
//       by chitchat_tx) being preserved in the data stream when gtx_k is
//       high.  This is because that "data" gets routed through the CRC logic.
//
// ------------------------------------

module chitchat_rx #(
   parameter [2:0] RX_GATEWARE_TYPE = 0 // Expected gateware type
) (
   input         clk,

   input  [15:0] gtx_d,
   input  [1:0]  gtx_k, // Signals per-byte comma char

   // Status outputs
   output [2:0]  ccrx_fault,     // Error during decoding [0] - Incorrect protocol,
                                 //                       [1] - CRC fail,
                                 //                       [2] - Incorrect frame number,
                                 //                       [3] - Timeout
   output [15:0] ccrx_fault_cnt,
   output        ccrx_los,        // Loss of sync - No comma characters for one period
   output        ccrx_frame_drop, // Signal dropped frame
   output        ccrx_error,      // as in the old chitchat
   // Application-level outputs
   output        rx_valid,
   output [3:0]  rx_protocol_ver,
   output [2:0]  rx_gateware_type,
   output [2:0]  rx_location,
   output [31:0] rx_rev_id,
   output [31:0] rx_data0,
   output [31:0] rx_data1,
	output        rx_extra_data_valid,
	output [255:0] rx_extra_data,
   output [15:0] rx_frame_counter,
   output [15:0] rx_loopback_frame_counter
);
`include "chitchat_pack.vh"

   wire gtx_k_lo = gtx_k[0]; // Only lower-byte comma is used

   // To set up the latency-measuring feature, route this module's
   // rx_frame_counter output to chitchat_tx's tx_loopback_frame_counter.
   // The difference between chitchat_tx's local_frame_counter and this
   // module's rx_loopback_frame_counter represents round-trip system latency.

   // Timing generator
   reg [3:0] word_count=0;
   reg last=0, rx_valid_r=0, frame_drop_r=0;

   wire timeout   = &word_count;
   wire increment = ~timeout;  // word_count stops at 15

   always @(posedge clk) begin
      word_count <= gtx_k_lo ? 0 : (word_count + increment);
   end

   // CRC calculation
   wire [15:0] crc_rx;
   wire        crc_zero = crc_rx==0;

   crc16 crc16_rx(
      .clk  (clk),
      .din  (gtx_d),
      .zero (last),
      .crc  (crc_rx)
   );

   // Error checking
   integer link_up_cnt = 0;
   wire    link_up     = link_up_cnt == LINK_UP_CNT;
   wire    link_up_inc = (link_up_cnt < LINK_UP_CNT) ? 1 : 0;

   reg  wrong_frame = 0;
   reg  wrong_prot;
   wire crc_fault = last & ~crc_zero;

   reg         los_r   = 0;
   reg  [3:0]  fault_r = 0;
   reg  [15:0] fault_cnt_r = 0;
   wire [3:0]  faults      = {wrong_frame, crc_fault, wrong_prot, timeout};

   reg [2:0] valid_count=0;
   wire valid_count_max = &valid_count;
   wire fault = |faults;
   wire valid_count_inc = ~valid_count_max;

   always @(posedge clk) begin
      rx_valid_r   <= 0;
      frame_drop_r <= 0;
      if (last | timeout) begin
         los_r <= timeout;
         if (|faults) begin
            link_up_cnt  <= 0;
            frame_drop_r <= last;
         end else begin
            link_up_cnt  <= link_up_cnt + link_up_inc;
            rx_valid_r   <= link_up;
            frame_drop_r <= ~link_up;
            fault_r      <= 0; // Clear decoding errors
         end
      end
      if (|link_up_cnt && |faults) begin
         fault_r      <= faults; // Latch decoding errors
         fault_cnt_r  <= fault_cnt_r + 1;
      end
      if (last|timeout)
         valid_count <= fault ? 0 : valid_count + valid_count_inc;
   end

   // Output value unpacking
   reg [15:0] gtx_dd       = 0;
   reg [3:0]  protocol_cat = 0;
   reg [7:0]  comma_pad    = 0;
   reg [9:0]  reserved     = 0;
   reg [15:0] next_frame_counter = 0;

   reg [3:0]  rx_protocol_ver_r;
   reg [2:0]  rx_gateware_type_r;
   reg [2:0]  rx_location_r;
   reg [31:0] rx_rev_id_r;
   reg [31:0] rx_data0_r;
   reg [31:0] rx_data1_r;
   reg rx_extra_data_valid_r;
	reg [255:0] rx_extra_data_r;

   reg [15:0] rx_extra_data_tmp = 0;
   reg [3:0] extra_word_cnt = 0;
   reg [3:0] extra_word_cnt_dly = 0;
   reg [15:0] rx_frame_counter_r = 0;
   reg [15:0] rx_loopback_frame_counter_r;

   always @(posedge clk) begin
      last               <= 0;
      gtx_dd             <= gtx_d;
      next_frame_counter <= rx_frame_counter_r + 1;

      if (gtx_k_lo) begin
         wrong_frame <= 0;
         wrong_prot  <= 0;
      end
      if (word_count==0) begin
         // Pipeline decoding of Word 0 since next gtx_k arrives before
         // current frame has been fully decoded
         {protocol_cat, rx_protocol_ver_r, comma_pad}  <= gtx_dd;
         wrong_prot <= gtx_dd[15:15-3] != CC_PROTOCOL_CAT;

         // Word 1
         {rx_gateware_type_r, rx_location_r, reserved} <= gtx_d;
         wrong_prot <= gtx_d[15:15-2] != RX_GATEWARE_TYPE;
      end

      if (word_count==2) rx_rev_id_r <= {gtx_dd, gtx_d};
      if (word_count==4) rx_data0_r  <= {gtx_dd, gtx_d};
      if (word_count==6) rx_data1_r  <= {gtx_dd, gtx_d};

      if (word_count==7) begin
         rx_frame_counter_r <= gtx_d;
         if (~|fault_r) // Skip check if last frame was bad
            wrong_frame <= gtx_d != next_frame_counter;
      end

      if (word_count==8) begin
         rx_loopback_frame_counter_r <= gtx_d;
      end
      if (word_count==9) begin
         rx_extra_data_tmp <= gtx_d;
         extra_word_cnt <= rx_frame_counter_r[3:0];
      end
         if (word_count==WORD_FRAME_CNT-1) last <= 1; // Last word (CRC)
   end

   always @(posedge clk) begin
      extra_word_cnt_dly <= extra_word_cnt;
      rx_extra_data_valid_r <= 1'b0;
      if (extra_word_cnt != extra_word_cnt_dly) begin
         case (extra_word_cnt)
         // use the received frame_counter to rebuilt the 256 bit
         // at count 7 the new value are registered to output
            4'h0: begin
                 rx_extra_data_valid_r    <= 1'b1;
                 rx_extra_data_r[15:0]    <= rx_extra_data_tmp;
                 end
            4'h1: rx_extra_data_r[31:16]   <= rx_extra_data_tmp;
            4'h2: rx_extra_data_r[47:32]   <= rx_extra_data_tmp;
            4'h3: rx_extra_data_r[63:48]   <= rx_extra_data_tmp;
            4'h4: rx_extra_data_r[79:64]   <= rx_extra_data_tmp;
            4'h5: rx_extra_data_r[95:80]   <= rx_extra_data_tmp;
            4'h6: rx_extra_data_r[111:96]  <= rx_extra_data_tmp;
            4'h7: rx_extra_data_r[127:112] <= rx_extra_data_tmp;
            4'h8: rx_extra_data_r[143:128] <= rx_extra_data_tmp;
            4'h9: rx_extra_data_r[159:144] <= rx_extra_data_tmp;
            4'ha: rx_extra_data_r[175:160] <= rx_extra_data_tmp;
            4'hb: rx_extra_data_r[191:176] <= rx_extra_data_tmp;
            4'hc: rx_extra_data_r[207:192] <= rx_extra_data_tmp;
            4'hd: rx_extra_data_r[223:208] <= rx_extra_data_tmp;
            4'he: rx_extra_data_r[239:224] <= rx_extra_data_tmp;
            4'hf: rx_extra_data_r[255:240] <= rx_extra_data_tmp;
            //default:
         endcase
      end
   end

   // Drive output pins
   assign ccrx_fault      = fault_r;
   assign ccrx_los        = los_r;
   assign ccrx_fault_cnt  = fault_cnt_r;
   assign ccrx_frame_drop = frame_drop_r;
   assign ccrx_error      = ~valid_count_max;

   assign rx_valid         = rx_valid_r;
   assign rx_protocol_ver  = rx_protocol_ver_r;
   assign rx_gateware_type = rx_gateware_type_r;
   assign rx_location      = rx_location_r;
   assign rx_rev_id        = rx_rev_id_r;
   assign rx_data0         = rx_data0_r;
   assign rx_data1         = rx_data1_r;
   assign rx_extra_data_valid = rx_extra_data_valid_r;
   assign rx_extra_data    = rx_extra_data_r;
   assign rx_frame_counter = rx_frame_counter_r;
   assign rx_loopback_frame_counter = rx_loopback_frame_counter_r;

endmodule
