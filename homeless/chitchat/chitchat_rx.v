// ------------------------------------
// chitchat_tx.v
//
// TX side of the Chitchat inter-chassis communication protocol, which can be used
// to communicate cavity status information (e.g. detune, interlock) between two
// FPGA chassis over fiber.
//
// See interchassis_protocol.txt for an application of this protocol and lower level
// details.
//
// NOTE: This module depends on the K28.5 comma code (inserted as frame marker
//       by chitchat_tx) being preserved in the data stream when gtx_k is
//       high.  This is because that "data" gets routed through the CRC logic.
//
// ------------------------------------

module chitchat_rx(
   input         clk,

   input  [15:0] gtx_d,
   input         gtx_k, // comma detected in lower byte, see above

   output [2:0]  ccrx_fault, // Error during decoding [0] - Incorrect protocol,
                             //                       [1] - CRC fail,
                             //                       [2] - Incorrect frame number
   output [15:0] ccrx_fault_cnt,
   output        ccrx_los,   // Loss of sync - No comma characters for one period

   // Application-specific outputs
   output        rx_valid,
   output [3:0]  rx_protocol_ver,
   output [2:0]  rx_gateware_type,
   output [2:0]  rx_location,
   output [31:0] rx_rev_id,
   output [31:0] rx_cavity0_status,
   output [31:0] rx_cavity1_status,
   output [15:0] rx_frame_counter,
   output [15:0] rx_loopback_frame_counter
);
`include "chitchat_pack.vh"

   // To set up the latency-measuring feature, route this module's
   // rx_frame_counter output to chitchat_tx's tx_loopback_frame_counter.
   // The difference between chitchat_tx's local_frame_counter and this
   // module's rx_loopback_frame_counter represents round-trip system latency.

   // Timing generator
   reg [3:0] word_count=0;
   reg sync=0, sync_r=0, rx_valid_r=0;

   wire timeout   = &word_count;
   wire increment = ~timeout;  // word_count stops at 15

   always @(posedge clk) begin
      word_count <= gtx_k ? 0 : (word_count + increment);
      sync       <= word_count == 9;
      sync_r     <= sync;
   end

   // CRC calculation
   wire [15:0] crc_rx;
   wire        crc_zero = crc_rx==0;

   crc16 crc16_rx(
      .clk  (clk),
      .din  (gtx_d),
      .zero (sync),
      .crc  (crc_rx)
   );

   // Error checking
   reg [2:0] valid_count     = 0;
   wire      valid_count_max = &valid_count;
   wire      valid_count_inc = ~valid_count_max; // Stops at 7

   reg  wrong_frame = 0;
   wire wrong_prot;
   wire crc_fault = sync & ~crc_zero;

   reg         los_r   = 0;
   reg  [2:0]  fault_r = 0;
   reg  [15:0] fault_cnt_r = 0;
   wire [2:0]  faults      = {wrong_frame, crc_fault, wrong_prot};

   always @(posedge clk) begin
      if (sync | timeout) begin
         valid_count <= (|faults | timeout) ? 0 : valid_count + valid_count_inc;
         los_r   <= timeout;
      end

      rx_valid_r <= 0;
      if (sync_r && valid_count_max) begin
         rx_valid_r  <= 1;
         fault_r <= 0; // Clear decoding errors
      end
      if (|valid_count && faults) begin
         fault_r <= 1; // Latch decoding errors
         fault_cnt_r <= fault_cnt_r + 1;
      end
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
   reg [31:0] rx_cavity0_status_r;
   reg [31:0] rx_cavity1_status_r;
   reg [15:0] rx_frame_counter_r = 0;
   reg [15:0] rx_loopback_frame_counter_r;

   always @(posedge clk) begin
      gtx_dd             <= gtx_d;
      next_frame_counter <= rx_frame_counter_r + 1;

      if (gtx_k)         {protocol_cat, rx_protocol_ver_r, comma_pad}  <= gtx_d;
      if (word_count==0) {rx_gateware_type_r, rx_location_r, reserved} <= gtx_d;

      if (word_count==2) rx_rev_id_r         <= {gtx_dd, gtx_d};
      if (word_count==4) rx_cavity0_status_r <= {gtx_dd, gtx_d};
      if (word_count==6) rx_cavity1_status_r <= {gtx_dd, gtx_d};

      if (word_count==7) begin
         rx_frame_counter_r <= gtx_d;
         wrong_frame <= gtx_d != next_frame_counter;
      end

      if (word_count==8) rx_loopback_frame_counter_r <= gtx_d;
   end

   assign wrong_prot = protocol_cat != CC_PROTOCOL_CAT;

   // Drive output pins
   assign ccrx_fault     = fault_r;
   assign ccrx_los       = los_r;
   assign ccrx_fault_cnt = fault_cnt_r;

   assign rx_valid  = rx_valid_r;
   assign rx_protocol_ver   = rx_protocol_ver_r;
   assign rx_gateware_type  = rx_gateware_type_r;
   assign rx_location       = rx_location_r;
   assign rx_rev_id         = rx_rev_id_r;
   assign rx_cavity0_status = rx_cavity0_status_r;
   assign rx_cavity1_status = rx_cavity1_status_r;
   assign rx_frame_counter  = rx_frame_counter_r;
   assign rx_loopback_frame_counter = rx_loopback_frame_counter_r;

endmodule
