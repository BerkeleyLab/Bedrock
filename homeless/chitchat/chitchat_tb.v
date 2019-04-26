`timescale 1ns / 1ns

module chitchat_tb;

`include "chitchat_pack.vh"

   reg clk;
   integer cc;
   reg fail=0;
   integer valid_total=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("chitchat.vcd");
         $dumpvars(5,chitchat_tb);
      end
      for (cc=0; cc<800; cc=cc+1) begin
         clk=0; #5;
         clk=1; #5;
      end

      $display("%d updates received over link", valid_total);
      if (fail || valid_total < 25) begin
         $display("FAIL");
         $stop;
      end else begin
         $display("PASS");
         $finish;
      end
   end

   // Instantiate transmitter
   reg  [31:0] cavity0_status = 32'h12345678;
   reg  [31:0] cavity1_status = 32'h2357bd11;
   wire [15:0] loopback_frame_counter = 16'd19;
   wire [15:0] local_frame_counter;
   wire [15:0] gtx_d;
   wire gtx_k;
   reg valid = 0;
   wire enable;

   always @(posedge clk) valid <= cc>20 & cc<460 | cc>520;

   chitchat_tx #(
      .REV_ID        (32'hdeadbeef)
   ) dut_tx (
      .clk (clk),
      .tx_valid                  (valid),
      .tx_enable                 (enable),
      .tx_location               (3'd2),
      .tx_cavity0_status         (cavity0_status),
      .tx_cavity1_status         (cavity1_status),
      .tx_loopback_frame_counter (loopback_frame_counter),
      .local_frame_counter       (local_frame_counter),
      .gtx_d (gtx_d),
      .gtx_k (gtx_k)
   );

   // Add an occasional error to the transmission
   reg [15:0] corrupt=0;

   always @(posedge clk) corrupt <= cc==315 | cc==550 ? 16'h0100 : 0;

   // Instantiate receiver
   wire [15:0] test_data;
   wire test_sync;
   wire valid_sync;
   wire [2:0] faults;
   wire [15:0] fault_cnt;
   wire       los;
   wire [3:0] protocol_ver_rb;
   wire [2:0] gateware_type_rb;
   wire [2:0] location_rb;
   wire [31:0] rev_id_rb;
   wire [31:0] cavity0_status_rb;
   wire [31:0] cavity1_status_rb;
   wire [15:0] frame_counter_rb;
   wire [15:0] loopback_frame_counter_rb;

   chitchat_rx dut_rx (
      .clk   (clk),

      .gtx_d (gtx_d^corrupt),
      .gtx_k (gtx_k),

      .ccrx_fault         (faults),
      .ccrx_fault_cnt     (fault_cnt),
      .ccrx_los           (los),

      .rx_valid          (valid_sync),
      .rx_protocol_ver   (protocol_ver_rb),
      .rx_gateware_type  (gateware_type_rb),
      .rx_location       (location_rb),
      .rx_rev_id         (rev_id_rb),
      .rx_cavity0_status (cavity0_status_rb),
      .rx_cavity1_status (cavity1_status_rb),
      .rx_frame_counter  (frame_counter_rb),
      .rx_loopback_frame_counter (loopback_frame_counter_rb)
   );

   // Detect incorrect output from receiver
   reg rb_fault=0;
   always @(posedge clk) if (valid_sync) begin
      valid_total <= valid_total + 1;
      rb_fault =
         // Of course all these magic constants are transcribed
         // from the Tx code above.
         faults            != 0 ||
         protocol_ver_rb   != CC_PROTOCOL_VER  ||
         gateware_type_rb  != CC_GATEWARE_TYPE ||
         location_rb       != 2 ||
         rev_id_rb         != 32'hdeadbeef ||
         cavity0_status_rb != 32'h12345678 ||
         cavity1_status_rb != 32'h2357bd11 ||
         loopback_frame_counter_rb != 16'd19 ||
         frame_counter_rb > local_frame_counter ||
         frame_counter_rb + 3 < local_frame_counter;
      if (rb_fault) begin
         $display("fault on cycle %d", cc);
         fail <= 1;
      end
   end

endmodule
