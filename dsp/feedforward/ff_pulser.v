/* F(eed)F(orward) Pulser
   Fixed-function feedfoward driver that coherently pulses a pair
   of setpoints, e.g., magnitude+phase or I+Q.
   Pulse settings are runtime-configurable but triggering options are
   deliberately left out and left to the instantiation site.

   This code assumes that all settings are set well in advance of start pulse,
   i.e., they're quasi-static.
*/

module ff_pulser #(
   parameter LENGTH_WI = 20,
   parameter DWI = 18
) (
   input clk,
   input start,  // Reset state and start pulsing
   output busy,

   // Common settings
   input [LENGTH_WI-1:0] length, // total pulse length, inc. rise and fall
   input [DWI-2:0]       slew_limit, // Maximum output variation per clock cycle; always positive

   // Per-setpoint settings
   input signed [DWI-1:0] setp_x,
   input signed [DWI-1:0] setp_y,

   output signed [DWI-1:0] out_x,
   output signed [DWI-1:0] out_y
);

   reg [LENGTH_WI-1:0] len_cnt, rise_cnt, fall_t;
   reg pulse_on=0, fall=0, fall_r;
   always @(posedge clk) begin
      if (start && ~pulse_on) begin // Ignore if already pulsing
         pulse_on <= 1;
         len_cnt  <= 0;
         rise_cnt <= 0;
         fall     <= 0;
         fall_t   <= 0;
      end
      fall_r <= fall;

      if (pulse_on) begin
         len_cnt <= len_cnt + 1;
         if (len_cnt == length) pulse_on <= 0; // Strictly enforce pulse length
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
   reg signed [DWI-1:0] x_next, y_next;
   always @(posedge clk) begin
      setp_x_us <= x_pos ? setp_x : -setp_x;
      setp_y_us <= y_pos ? setp_y : -setp_y;
      x_next <= fall ? x_us - slew_limit : x_us + slew_limit;
      y_next <= fall ? y_us - slew_limit : y_us + slew_limit;
   end

   reg x_railed=0, y_railed=0;
   always @(*) if (pulse_on) begin
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
