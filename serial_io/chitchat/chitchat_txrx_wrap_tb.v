`timescale 1ns / 1ns

// ------------------------------------
// CHITCHAT_TXRX_WRAP TESTBENCH
//
// Variant of chitchat_tb.v with support for multiple clock domains and
// checks for correct clock domain crossing. As a result, it does not insert
// random corruption into the the TX-RX channel. It is recommended that the
// base chitchat_tb is always used alongside this one.
//
// ------------------------------------

module chitchat_txrx_wrap_tb;

`include "chitchat_pack.vh"

   localparam SIM_TIME = 100000; // ns

   localparam CC_CLK_PERIOD = 10.5; // ns
   localparam GTX_TX_CLK_PERIOD = 8; // ns
   localparam GTX_RX_CLK_PERIOD = 8; // ns
   localparam LB_CLK_PERIOD = 20; // ns

   localparam MIN_OFF = 20; // Must cover gtx_k period
   localparam MAX_OFF = 70;
   localparam MIN_ON = 200;
   localparam MAX_ON = 400;

   localparam MIN_VALID_P = 3;
   localparam MAX_VALID_P = 20;

   reg cc_clk = 0;
   reg gtx_tx_clk = 0;
   reg gtx_rx_clk = 1;
   reg lb_clk = 0;

   wire tx_clk;
   wire rx_clk;

   reg fail=0;

   integer SEED;
   integer tx_cnt=0;
   integer check_count=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("chitchat_txrx_wrap.vcd");
         $dumpvars(5, chitchat_txrx_wrap_tb);
      end

      if (!$value$plusargs("seed=%d", SEED)) SEED = 123;

      while ($time < SIM_TIME) @(posedge cc_clk);

      $display("%d updates received over link", tx_cnt);
      $display("%d extra data received over link", check_count);
      if (fail || tx_cnt < 300) begin
         $display("FAIL");
         $stop(0);
      end else begin
         $display("PASS");
         $finish;
      end
   end

   always begin #(CC_CLK_PERIOD/2);     cc_clk     = ~cc_clk;     end
   always begin #(GTX_TX_CLK_PERIOD/2); gtx_tx_clk = ~gtx_tx_clk; end
   always begin #(GTX_RX_CLK_PERIOD/2); gtx_rx_clk = ~gtx_rx_clk; end
   always begin #(LB_CLK_PERIOD/2);     lb_clk     = ~lb_clk;     end

   assign tx_clk = cc_clk;
   assign rx_clk = lb_clk; // RX clock normally lb_clk

   // ----------------------
   // Generate stimulus
   // ----------------------
   reg  stim_start = 0;
   reg  tx_transmit_en = 0, tx_transmit_en_r = 0;
   wire tx_valid0, tx_valid1;

   integer cnt_off = MAX_OFF;
   integer cnt_on = 0;
   wire [1:0]  gtx_k;
   always @(posedge tx_clk) begin
      if (tx_transmit_en) begin
         if (cnt_on == 0)
            tx_transmit_en <= gtx_k[0]; // Wait for lower-byte gtx_k to ease modelling
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

      stim_start <= tx_transmit_en ? 1 : stim_start;
   end

   reg [2:0] tx_location = 0;
   integer valid_period = MIN_VALID_P;
   reg [5:0] val_cnt = 0;
   always @(posedge tx_clk) begin
      tx_transmit_en_r <= tx_transmit_en;

      if (~tx_transmit_en && tx_transmit_en_r) begin // negedge
         valid_period = MIN_VALID_P + $urandom(SEED) % MAX_VALID_P;
         tx_location <= tx_location + 1; // Change location on every new transmit window
      end

      if (tx_transmit_en)
         val_cnt <= val_cnt + 1;
   end
   assign tx_valid0 = (val_cnt!=0 & (val_cnt % valid_period)==0);
   assign tx_valid1 = (val_cnt!=0 & (val_cnt % valid_period)==5);


   reg  [7:0]  tx_data=0;
   wire [31:0] tx_data0, tx_data1;
   reg         tx_extra_data_valid = 0;
   reg  [127:0] tx_extra_data = 128'hffeeddccbbaa99887766554433221100;

   always @(posedge tx_clk) if (tx_transmit_en) tx_data <= tx_data + 1;

   assign tx_data0 = {(32/8){tx_data}};
   assign tx_data1 = ~tx_data0;

   // No corruption in this CDC-enabled testbench
   reg [15:0] corrupt=0;

   // test for the Pulse_id 128 bit transmission in the frame
   reg [15:0] tx_loopback_frame_counter=0;
   always @(posedge tx_clk) begin
      tx_loopback_frame_counter <= tx_loopback_frame_counter +1;
      tx_extra_data_valid       <= 1'b0;
      if (tx_loopback_frame_counter[9:0]==10'b1000000000) begin
         tx_extra_data          <= tx_extra_data + 1;
         tx_extra_data_valid    <= 1'b1;
      end
   end

   // ----------------------
   // DUT
   // ----------------------

   wire [15:0] local_frame_counter;
   wire [15:0] gtx_d;
   wire [15:0] rx_frame_counter;
   wire [15:0] txrx_latency;

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
   wire        rx_extra_data_valid;
   wire [127:0] rx_extra_data;

   localparam REVID = 32'hdeadbeef;
   localparam [2:0] TX_GATEW_TYPE = 2;
   localparam [2:0] RX_GATEW_TYPE = 2;

   chitchat_txrx_wrap #(
      .REV_ID           (REVID),
      .TX_GATEWARE_TYPE (TX_GATEW_TYPE),
      .RX_GATEWARE_TYPE (RX_GATEW_TYPE),
      .TX_TO_GTX_CDC    (1), // Selectively enable/disable CDC
      .GTX_TO_RX_CDC    (1),
      .GTX_TO_LB_CDC    (1)
   ) i_dut (
      // -------------------
      // Data Interface
      // -------------------
      .tx_clk            (tx_clk),

      .tx_transmit_en    (tx_transmit_en),
      .tx_location       (tx_location),
      .tx_valid0         (tx_valid0),
      .tx_valid1         (tx_valid1),
      .tx_data0          (tx_data0),
      .tx_data1          (tx_data1),
      .tx_extra_data_valid (tx_extra_data_valid),
      .tx_extra_data     (tx_extra_data),

      .rx_clk            (rx_clk),

      .rx_valid          (rx_valid),
      .rx_data0          (rx_data0),
      .rx_data1          (rx_data1),
      .rx_extra_data_valid (rx_extra_data_valid),
      .rx_extra_data     (rx_extra_data),
      .ccrx_frame_drop   (frame_drop),

      // -------------------
      // LB Interface
      // -------------------
      .lb_clk            (lb_clk),

      .txrx_latency      (txrx_latency),
      .rx_frame_counter  (rx_frame_counter),
      .rx_protocol_ver   (rx_protocol_ver),
      .rx_gateware_type  (rx_gateware_type),
      .rx_location       (rx_location),
      .rx_rev_id         (rx_rev_id),

      .ccrx_fault        (faults),
      .ccrx_fault_cnt    (fault_cnt),
      .ccrx_los          (los),

      // ------------------------------------
      // GTX Interface
      // ------------------------------------
      .gtx_tx_clk        (gtx_tx_clk),
      .gtx_rx_clk        (gtx_rx_clk),

      .gtx_tx_d          (gtx_d),
      .gtx_tx_k          (gtx_k),
      .gtx_rx_d          (gtx_d ^ corrupt),
      .gtx_rx_k          (gtx_k)
   );

   // ----------------------
   // Scoreboarding
   // ----------------------
   localparam SCB_BUS_WI = 32*2; // Data*2
   reg  [2:0] scb_location;
   wire [SCB_BUS_WI-1:0] scb_data_in, scb_data_out, scb_data_out_xcc;
   reg  [31:0] scb_data0_sync_r, scb_data0_sync_r2, scb_data1_sync_r, scb_data1_sync_r2;
   wire scb_write_en, scb_write_en_xcc, scb_read_en, scb_full, scb_empty;

   // Simple latching of tx_location
   always @(posedge tx_clk) if ((tx_valid0 || tx_valid1) && tx_transmit_en) scb_location <= tx_location;

   // Check TX clock crossing
   always @(posedge tx_clk) begin
      if (tx_valid0) scb_data0_sync_r <= tx_data0;
      if (tx_valid1) scb_data1_sync_r <= tx_data1;
      scb_data0_sync_r2 <= scb_data0_sync_r;
      scb_data1_sync_r2 <= scb_data1_sync_r;
   end
   always @(posedge gtx_tx_clk) begin
      if (i_dut.tx_valid0_x_tgtx) begin
         if (scb_data0_sync_r2 != i_dut.tx_data0_x_tgtx) begin
            $display("%t ERROR: TX data0 synchronization mismatch", $time);
            fail <= 1;
         end
      end
      if (i_dut.tx_valid1_x_tgtx) begin
         if (scb_data1_sync_r2 != i_dut.tx_data1_x_tgtx) begin
            $display("%t ERROR: TX data1 synchronization mismatch", $time);
            fail <= 1;
         end
      end
   end

   // Need to probe DUT due to complex synchronizer timing
   // TX synchronizer correctness checked above
   assign scb_write_en = i_dut.tx_send_x_tgtx;
   assign scb_data_in = {i_dut.tx_data1_x_tgtx, i_dut.tx_data0_x_tgtx};

   // Move from gtx_tx_clk domain to rx_clk domain
   data_xdomain # (.size(SCB_BUS_WI)) i_scb_tx_sys (
      .clk_in   (gtx_tx_clk),
      .gate_in  (scb_write_en),
      .data_in  (scb_data_in),
      .clk_out  (rx_clk),
      .gate_out (scb_write_en_xcc),
      .data_out (scb_data_out_xcc)
   );

   shortfifo #(
      .aw (4), // Must cover latency of DUT
      .dw (SCB_BUS_WI))
   i_scb_fifo (
      .clk         (rx_clk),
      .din         (scb_data_out_xcc),
      .we          (scb_write_en_xcc & stim_start),
      .dout        (scb_data_out),
      .re          (scb_read_en),
      .full        (scb_full), // Should never go high
      .empty       (scb_empty),
      .last        (),
      .count       ()
   );

   // Pop on valid or when frame is dropped on RX side
   // Need to check stim_start because CC_RX will signal frame_drop at start of day
   assign scb_read_en = (rx_valid | frame_drop) & stim_start;

   reg [15:0] prev_frame_cnt=0;
   always @(posedge rx_clk) begin
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
         if (scb_data_out != {rx_data1, rx_data0}) begin
            $display("%t, ERROR: RX data comparison failed", $time);
            fail <= 1;
         end

         // The below are technically in lb_clk domain but all slow signals

         // Check for incrementing frame counter
         if (prev_frame_cnt && (rx_frame_counter != prev_frame_cnt+1)) begin
            $display("%t, ERROR: Received non-incrementing frame counter", $time);
            fail <= 1;
         end
         // Compare fixed and slow data
         if ({rx_protocol_ver, rx_gateware_type, rx_rev_id} != {CC_PROTOCOL_VER, TX_GATEW_TYPE, REVID}) begin
            $display("%t, ERROR: Version comparison failed", $time);
            fail <= 1;
         end
         if (tx_transmit_en & (rx_location != scb_location)) begin
            $display("%t, ERROR: Location comparison failed", $time);
            fail <= 1;
         end
         if (2 < txrx_latency > 10) begin // Should converge to 4
            $display("%t, ERROR: Latency calculation failed", $time);
            fail <= 1;
         end

         prev_frame_cnt <= rx_frame_counter;
      end
      if (~tx_transmit_en) prev_frame_cnt <= 0;
      if (rx_extra_data_valid && (corrupt == 0)) begin
         check_count <= check_count + 1;
      end

   end

endmodule
