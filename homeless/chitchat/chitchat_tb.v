`timescale 1ns / 1ns

// ------------------------------------
// CHITCHAT TESTBENCH
//
// Testbench for chitchat_tx + chitchat_rx. Integrity of transferred data
// is checked and random transmission errors are added to the TX-RX channel
// to exercise CRC and other error detection functionality.
//
// See also: chitchat_txrx_wrap_tb.v
//
// ------------------------------------

module chitchat_tb;

`include "chitchat_pack.vh"

   localparam SIM_TIME = 100000; // ns
   localparam CC_CLK_PERIOD = 10;

   localparam MIN_OFF = 20; // Must cover gtx_k period
   localparam MAX_OFF = 70;
   localparam MIN_ON = 200;
   localparam MAX_ON = 400;

   reg cc_clk = 0;
   reg fail=0;

   integer SEED;
   integer tx_cnt=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("chitchat.vcd");
         $dumpvars(5, chitchat_tb);
      end

      if (!$value$plusargs("seed=%d", SEED)) SEED = 123;

      while ($time < SIM_TIME) @(posedge cc_clk);

      $display("%d updates received over link", tx_cnt);
      if (fail || tx_cnt < 300) begin
         $display("FAIL");
         $stop;
      end else begin
         $display("PASS");
         $finish;
      end
   end

   always begin
      cc_clk = ~cc_clk; #(CC_CLK_PERIOD/2);
   end

   // ----------------------
   // Generate stimulus
   // ----------------------
   reg  tx_transmit_en = 0;
   wire tx_send;

   integer cnt_off = MAX_OFF;
   integer cnt_on = 0;
   always @(posedge cc_clk) begin
      if (tx_transmit_en) begin
         if (cnt_on == 0)
            tx_transmit_en <= gtx_k; // Wait for gtx_k to ease modelling
         else
            cnt_on <= cnt_on - 1;
      end else begin
         if (cnt_off == 0) begin
            tx_transmit_en <= 1;
            cnt_on  = MIN_ON + $urandom(SEED) % MAX_ON;
            cnt_off = MIN_OFF + $urandom(SEED) % MAX_OFF;
         end else begin
            cnt_off <= cnt_off - 1;
         end
      end
   end

   reg  [7:0] tx_data=0;
   wire [31:0] tx_data0, tx_data1;
   always @(posedge cc_clk) if (tx_transmit_en) tx_data <= tx_data + 1;

   assign tx_data0 = {(32/8){tx_data}};
   assign tx_data1 = ~tx_data0;

   // Add an occasional error to the transmission
   reg [15:0] corrupt=0;
   always @(posedge cc_clk) begin
      corrupt <= 0;
      if (tx_transmit_en && &(cnt_on[5:3]&tx_data[4:2])) // Sporadic random pattern
         corrupt <= $urandom(SEED) % 2**16;
   end

   // ----------------------
   // DUT
   // ----------------------

   wire [15:0] local_frame_counter;
   wire [15:0] gtx_d;
   wire        gtx_k;
   wire [15:0] rx_frame_counter;

   wire        rx_valid;
   wire [2:0]  faults;
   wire [15:0] fault_cnt;
   wire        los;
   wire        frame_drop;
   wire [3:0]  rx_protocol_ver;
   wire [2:0]  rx_gateware_type;
   wire [2:0]  rx_location;
   wire [31:0] rx_rev_id;
   wire [31:0] rx_data0;
   wire [31:0] rx_data1;
   wire [15:0] rx_loopback_frame_counter;

   localparam REVID = 32'hdeadbeef;

   chitchat_tx #(
      .REV_ID (REVID)
   ) i_dut_tx (
      .clk                       (cc_clk),
      .tx_transmit_en            (tx_transmit_en),
      .tx_send                   (tx_send),
      .tx_location               (tx_data0[2:0]),
      .tx_data0                  (tx_data0),
      .tx_data1                  (tx_data1),
      .tx_loopback_frame_counter (rx_frame_counter),
      .local_frame_counter       (local_frame_counter),
      .gtx_d                     (gtx_d),
      .gtx_k                     (gtx_k)
   );

   chitchat_rx i_dut_rx (
      .clk   (cc_clk),

      .gtx_d (gtx_d^corrupt),
      .gtx_k (gtx_k),

      .ccrx_fault        (faults),
      .ccrx_fault_cnt    (fault_cnt),
      .ccrx_los          (los),
      .ccrx_frame_drop   (frame_drop),

      .rx_valid          (rx_valid),
      .rx_protocol_ver   (rx_protocol_ver),
      .rx_gateware_type  (rx_gateware_type),
      .rx_location       (rx_location),
      .rx_rev_id         (rx_rev_id),
      .rx_data0          (rx_data0),
      .rx_data1          (rx_data1),
      .rx_frame_counter  (rx_frame_counter),
      .rx_loopback_frame_counter (rx_loopback_frame_counter)
   );

   // ----------------------
   // Scoreboarding
   // ----------------------
   localparam SCB_BUS_WI = 32*2 + 3 + 16*2; // Data*2 + Location + Frame*2
   wire [SCB_BUS_WI-1: 0] scb_data_in, scb_data_out;
   wire scb_write_en, scb_read_en, scb_full, scb_empty;

   assign scb_write_en = tx_send;
   assign scb_data_in = {tx_data1, tx_data0, tx_data0[2:0], rx_frame_counter, local_frame_counter};

   shortfifo #(
      .aw (4), // Must cover latency of DUT
      .dw (SCB_BUS_WI))
   i_scb_fifo (
      .clk         (cc_clk),
      .din         (scb_data_in),
      .we          (scb_write_en),
      .dout        (scb_data_out),
      .re          (scb_read_en),
      .full        (scb_full), // Should never go high
      .empty       (scb_empty),
      .last        (),
      .count       ()
   );

   // Pop on valid or when frame is dropped on RX side
   // Need to check if fifo is empty because CC_RX will signal empty at start of day
   assign scb_read_en = (rx_valid | frame_drop) & ~scb_empty;

   always @(posedge cc_clk) begin
      if (scb_full) begin
         $display("%t, ERROR: FIFO went full", $time);
         fail <= 1;
      end

      if (rx_valid) begin
         tx_cnt = tx_cnt + 1;

         if (scb_empty) begin
            $display("%t ERROR: FIFO empty when trying to pop", $time);
            fail <= 1;
         end

         // Compare data
         if (scb_data_out != {rx_data1, rx_data0, rx_location, rx_loopback_frame_counter, rx_frame_counter}) begin
            $display("%t, ERROR: RX data comparison failed", $time);
            fail <= 1;
         end
         // Compare fixed data
         if ({rx_protocol_ver, rx_gateware_type, rx_rev_id} != {CC_PROTOCOL_VER, CC_GATEWARE_TYPE, REVID}) begin
            $display("%t, ERROR: Version comparison failed", $time);
            fail <= 1;
         end

         if ((rx_frame_counter > local_frame_counter) || (rx_frame_counter + 3 < local_frame_counter)) begin
            $display("%t, ERROR: Frame comparison failed", $time);
            fail <= 1;
         end

      end
   end

endmodule
