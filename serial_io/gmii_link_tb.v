`timescale 1ns / 1ns

module gmii_link_tb;

   localparam CLKP=8; // 125 MHz * 8bits/cycle -> 1 Gbit/sec

   reg clk;
   integer cc;
   integer data_fail=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("gmii_link.vcd");
         $dumpvars(5,gmii_link_tb);
      end
      for (cc=0; cc<5000; cc=cc+1) begin
         clk=0; #(CLKP/2);
         clk=1; #(CLKP/2);
      end
      if (operate)
         if (an_status[6]) begin
            $display("FAIL: Link is up but auto-negotiation timed out.");
            $stop();
         end else begin
            $display("PASS: Link is up and auto-negotiation completed successfully.");
            $finish();
         end

      $display("FAIL: Link is not up at the end of the test.");
      $stop();
   end

   wire operate;  // from link negotiator
   wire [9:0] gtx_txdata_10, gtx_rxdata_10; // communication channel looped back Tx to Rx

   // Results produced by the Rx side
   wire [7:0] rx_data;
   wire rx_dv, rx_err;

   // Debug/diagnostics
   wire [15:0] lacr_rx;
   wire [8:0] an_status;

   // ----------------------
   // Stimulus
   // ----------------------
   reg tx_enable=0, rx_los=0;
   reg [7:0] tx_data=0;
   reg phys_en = 0;

   // Simulate disconnected physical link
   assign gtx_rxdata_10 = phys_en ? gtx_txdata_10 : 0;

   integer oc=0;
   integer f;
   always @(posedge clk) begin
      if (operate)
         oc <= oc + 1;

      f=oc%79 + (oc/178);
      tx_data <= (f>38) ? oc : (f==38) ? 8'hd5 : 8'h55 ;
      tx_enable <= (f>=38);
   end

   // Sequence of directed tests
   initial begin
      #(CLKP*(50 + link.negotiator.WATCHDOG_TIME)) // Must be longer than WDOG timeout
      // No physical link; Don't expect any AN activity
      if (operate || an_status[6] || an_status[0] || rx_dv) begin
         $display("FAIL: %t AN unexpected when physical link is down", $time);
         $stop;
      end

      #(CLKP*10)
      wait (clk);
      phys_en <= 1;
      // Expect successful AN
      wait (operate)
      if (an_status[6] || ~an_status[0]) begin
         $display("FAIL: %t Link is up but AN failed", $time);
         $stop;
      end

      #(CLKP*1000)
      // Disable Full Duplex advertisement and restart AN by pulsing LOS
      rx_los <= 1;
      link.negotiator.FD <= 0;
      #(CLKP*4); rx_los <= 0;
      // Expect AN abort
      wait (operate)
      if (~an_status[6]) begin
         $display("FAIL: %t Link is up but AN abort not signalled", $time);
         $stop;
      end

      #(CLKP*1000)
      // Attempt a successful AN by pulsing LOS
      rx_los <= 1;
      link.negotiator.FD <= 1;
      #(CLKP*4); rx_los <= 0;
      // Expect successful AN
      wait (operate)
      if (an_status[6] || ~an_status[0]) begin
         $display("FAIL: %t Link is up but AN failed", $time);
         $stop;
      end

   end




   // Note that the DELAY value is set _much_ lower than in real-life,
   // so we can see the process more easily in a waveform viewer.
   gmii_link #(.DELAY(50)) link(
      .RX_CLK     (clk),
      .RXD        (rx_data),
      .RX_DV      (rx_dv),
      .RX_ER      (rx_err),
      .GTX_CLK    (clk),
      .TXD        (tx_data),
      .TX_EN      (tx_enable),
      .TX_ER      (1'b0),
      .an_bypass  (1'b0),
      .txdata     (gtx_txdata_10),
      .rx_err_los (rx_los),
      .rxdata     (gtx_rxdata_10),
      .operate    (operate),
      .lacr_rx    (lacr_rx),
      .an_status  (an_status)
   );

   // ----------------------
   // Scoreboarding
   // ----------------------
   wire [7:0] scb_data_out;
   wire scb_read_en, scb_full, scb_empty;
   reg operate_r=0;

   always @(posedge clk) operate_r <= operate;

   shortfifo #(
      .aw (4), // Must cover latency of DUT
      .dw (8))
   i_scb_fifo (
      .clk   (clk),
      .din   (link.tx.tx_data_p2),
      .we    (link.tx.tx_state==link.tx.TX_DATA),
      .dout  (scb_data_out),
      .re    (scb_read_en),
      .full  (scb_full), // Should never go high
      .empty (scb_empty),
      .last  (),
      .count ()
   );

   assign scb_read_en = (rx_dv==1) ? 1 : 0;

   always @(posedge clk) begin
      if (rx_err) begin
         $display("%t RX_ERR asserted", $time);
         data_fail <= data_fail + 1;
      end
      if (rx_dv) begin
         if (scb_full || scb_empty || (scb_data_out != rx_data)) begin
            $display("FAIL: %t Data transmission error", $time);
            data_fail <= data_fail + 1;
         end
      end
   end

endmodule
