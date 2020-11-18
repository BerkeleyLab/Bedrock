/* F(eed)F(orward) Pulser
   Fixed-function feedfoward driver that coherently pulses a pair
   of setpoints, e.g., magnitude+phase or I+Q.
   Pulse settings are runtime-configurable but triggering options are
   deliberately left out and left to the instantiation site.

   This code assumes that all settings are set well in advance of pulse start,
   i.e., they're quasi-static.

   Pipelined uarch introduces 3-cycles of latency from start marker
*/

module ff_pulser #(
   parameter LENGTH_WI = 20,
   parameter DWI = 18
) (
   input clk,
   input start,  // Reset state and start pulsing
   output busy,

   // Common settings
   input [LENGTH_WI-1:0] length, // total pulse length, inc. rise and fall; must have non-zero flat-top
   input [DWI-2:0]       slew_limit, // Maximum output variation per clock cycle; always positive

   // Per-setpoint settings
   input signed [DWI-1:0] setp_x,
   input signed [DWI-1:0] setp_y,

   output signed [DWI-1:0] out_x,
   output signed [DWI-1:0] out_y
);

   wire start_g = start&~pulse_on; // Ignore if already pulsing

   // Delayed start marker to match pipeline latency
   wire start_dly;
   reg_delay #(.dw(1), .len(3-1)) i_pipe_lat (
      .clk  (clk), .reset (1'b0), .gate  (1'b1),
      .din   (start_g), .dout  (start_dly));

   reg [LENGTH_WI-1:0] len_cnt, rise_cnt, fall_t;
   reg pulse_on=0, fall=0, fall_r, pulse_on_dly=0;
   always @(posedge clk) begin
      if (start_g) begin
         pulse_on <= 1;
         len_cnt  <= 0;
         rise_cnt <= 0;
         fall     <= 0;
         fall_t   <= 0;
      end
      fall_r <= fall;
      if (start_dly) pulse_on_dly <= 1;

      if (pulse_on_dly) begin
         len_cnt <= len_cnt + 1;

         if (len_cnt == length) {pulse_on, pulse_on_dly} <= 0; // Strictly enforce pulse length
         if ((fall_t != 0) && (len_cnt == fall_t)) fall <= 1;

         if (x_railed && y_railed) begin
            fall_t <= length - rise_cnt - 1;
         end else begin
            rise_cnt <= rise_cnt + 1;
         end
      end
   end

   wire x_pos, y_pos;
   assign x_pos = ~setp_x[DWI-1];
   assign y_pos = ~setp_y[DWI-1];

   reg [DWI-2:0] setp_x_us, setp_y_us;
   reg [DWI-2:0] x_us=0, y_us=0;
   reg signed [DWI-1:0] x_next=0, y_next=0;
   always @(posedge clk) begin
      setp_x_us <= x_pos ? setp_x : -setp_x;
      setp_y_us <= y_pos ? setp_y : -setp_y;
      if (pulse_on) begin
         x_next <= setp_x_us;
         if (!x_railed)
            x_next <= fall ? x_next - slew_limit : x_next + slew_limit;

         y_next <= setp_y_us;
         if (!y_railed)
            y_next <= fall ? y_next - slew_limit : y_next + slew_limit;
      end else begin
         x_next <= 0;
         y_next <= 0;
      end
   end

   reg x_railed=0, y_railed=0;
   always @(posedge clk) if (pulse_on) begin
      if (!fall_r) begin
         {x_railed, x_us} <= x_next >= setp_x_us ? {1'b1, setp_x_us} : {1'b0, x_next};
         {y_railed, y_us} <= y_next >= setp_y_us ? {1'b1, setp_y_us} : {1'b0, y_next};
      end else begin
         {x_railed, y_railed} <= 2'b0;
         x_us <= x_next < 0 ? 0 : x_next;
         y_us <= y_next < 0 ? 0 : y_next;
      end
   end else begin
      {x_railed, x_us} <= 0;
      {y_railed, y_us} <= 0;
   end

   reg signed [DWI-1:0] out_x_r, out_y_r;
   always @(posedge clk) begin
      out_x_r <= x_pos ? x_us : -x_us;
      out_y_r <= y_pos ? x_us : -y_us;
   end
   assign out_x = out_x_r;
   assign out_y = out_y_r;
   assign busy = pulse_on;
endmodule
