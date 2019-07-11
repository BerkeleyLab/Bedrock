`timescale 1ns / 1ns

module gmii_link_tb;

   reg clk;
   integer cc;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("gmii_link.vcd");
         $dumpvars(5,gmii_link_tb);
      end
      for (cc=0; cc<1000; cc=cc+1) begin
         clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
         clk=1; #4;
      end
      if (operate)
         if (an_status[6]) begin
            $display("FAIL: Link is up but auto-negotiation timed out.");
            $stop;
         end else begin
            $display("PASS: Link is up and auto-negotiation completed successfully.");
            $finish;
         end

      $display("FAIL: Link is not up at the end of the test.");
      $stop;
   end

   reg [7:0] tx_data=0;
   reg tx_enable=1;
   reg even=0;
   integer f;
   wire operate;  // from link negotiator
   integer oc=0;  // octet counter, only runs when negotiator says we're ready
   always @(posedge clk) begin
      if (operate) oc <= oc+1;

      f=oc%79 + (oc/178);
      tx_data <= (f>38) ? oc : (f==38) ? 8'hd5 : 8'h55 ;
      even <= ~even;
   end

   wire [9:0] gtx_data_10;  // communication channel looped back Tx to Rx

   // Results produced by the Rx side; viewable but not checked by testbench
   wire lacr_send;
   wire [7:0] loop_d;
   wire loop_dv, loop_er;

   // Debug/diagnostics
   wire [15:0] lacr_rx;
   wire [6:0] an_status;

   // Note that the DELAY value is set _much_ lower than in real-life,
   // so we can see the process more easily in a waveform viewer.
   gmii_link #(.DELAY(50)) link(
      .RX_CLK     (clk),
      .RXD        (loop_d),
      .RX_DV      (loop_dv),
      .RX_ER      (loop_er),
      .GTX_CLK    (clk),
      .TXD        (tx_data),
      .TX_EN      (tx_enable),
      .TX_ER      (1'b0),
      .an_bypass  (1'b0),
      .txdata     (gtx_data_10),
      .rx_err_los (1'b0),
      .rxdata     (gtx_data_10),
      .operate    (operate),
      .lacr_rx    (lacr_rx),
      .an_status  (an_status)
   );

endmodule
