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
   output [3:0]  ccrx_fault,     // Error during decoding [0] - Timeout,
                                 //                       [1] - Incorrect protocol,
                                 //                       [2] - CRC fail,
                                 //                       [3] - Incorrect frame number
   output [15:0] ccrx_fault_cnt,
   output        ccrx_los,        // Loss of sync - invalid input
                                  // will auto-recover after a few valid frames
   output        ccrx_frame_drop, // Signal dropped frame

   // Application-level outputs
   output        rx_valid,
   output [3:0]  rx_protocol_ver,
   output [2:0]  rx_gateware_type,
   output [2:0]  rx_location,
   output [31:0] rx_rev_id,
   output [31:0] rx_data0,
   output [31:0] rx_data1,
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

   // Error checking; LINK_UP_CNT defined in chitchat_pack.vh
   reg [7:0] link_up_cnt = 0;
   wire    link_up     = link_up_cnt == LINK_UP_CNT;
   wire    link_up_inc = (link_up_cnt < LINK_UP_CNT) ? 1 : 0;

   reg  wrong_frame = 0;
   reg  wrong_prot;
   wire crc_fault = last & ~crc_zero;

   reg         los_r   = 0;
   reg  [3:0]  fault_r = 0, fault_rr = 0;
   reg  [15:0] fault_cnt_r = 0;
   wire [3:0]  faults      = {wrong_frame, crc_fault, wrong_prot, timeout};

   always @(posedge clk) begin
      rx_valid_r   <= 0;
      frame_drop_r <= 0;
      los_r <= ~link_up;
      if (last | timeout) begin
         if (|faults) begin
            link_up_cnt  <= 0;
            frame_drop_r <= last;
            fault_r      <= faults; // Latch decoding errors
            fault_cnt_r  <= fault_cnt_r + 1;
         end else begin
            link_up_cnt  <= link_up_cnt + link_up_inc;
            rx_valid_r   <= link_up;
            frame_drop_r <= ~link_up;
            fault_r      <= 0; // Clear decoding errors
         end
      end
      // Time-align with los_r, and hold on to the last fault
      // as link_up_count increments (when there are no new faults).
      if (|faults || link_up) fault_rr <= fault_r;
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
   reg [15:0] rx_frame_counter_r = 0;
   reg [15:0] rx_loopback_frame_counter_r;

   // Notice pipelining - these are captured when word_count == 0
   wire mismatch_protocol = gtx_dd[15:15-3] != CC_PROTOCOL_CAT;
   wire mismatch_gatetype = gtx_d[15:15-2] != RX_GATEWARE_TYPE;
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
         // Word 1
         {rx_gateware_type_r, rx_location_r, reserved} <= gtx_d;
         wrong_prot <= mismatch_protocol | mismatch_gatetype;
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
      if (word_count==9) last <= 1; // Last word (CRC)
   end

   // Drive output pins
   assign ccrx_fault      = fault_rr;
   assign ccrx_los        = los_r;
   assign ccrx_fault_cnt  = fault_cnt_r;
   assign ccrx_frame_drop = frame_drop_r;

   assign rx_valid         = rx_valid_r;
   assign rx_protocol_ver  = rx_protocol_ver_r;
   assign rx_gateware_type = rx_gateware_type_r;
   assign rx_location      = rx_location_r;
   assign rx_rev_id        = rx_rev_id_r;
   assign rx_data0         = rx_data0_r;
   assign rx_data1         = rx_data1_r;
   assign rx_frame_counter = rx_frame_counter_r;
   assign rx_loopback_frame_counter = rx_loopback_frame_counter_r;

endmodule
