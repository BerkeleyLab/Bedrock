/* F(eed)F(orward) Pulser
   Fixed-function feedforward driver that coherently pulses a pair
   of setpoints, e.g., magnitude+phase or I+Q.
   Pulse settings are runtime-configurable but triggering options are
   deliberately left out and left to the instantiation site.

   This code assumes that all settings are set well in advance of pulse start,
   i.e., they're quasi-static.

   Pipelined uarch introduces 3-cycles of latency from start marker
*/

module ff_pulser (
   input  clk,
   input  start, // Reset state and start pulsing
   output busy,

   // Common settings
   input [31:0]        length, // external; Total pulse length, inc. rise and fall;
                               // must have non-zero flat-top
   input [16:0]        slew_lim, // external; Maximum output variation per clock cycle;
                                 // must be greater than zero

   // Per-setpoint settings
   input signed [17:0] setp_x, // external
   input signed [17:0] setp_y, // external

   output signed [17:0] out_x,
   output signed [17:0] out_y
);
   // Not using params to allow newad register extraction
   localparam LENGTH_WI = 32;
   localparam DWI = 18;

   // Delay to match pipeline latency
   reg pulse_on=0;
   wire pulse_on_dly;
   reg_delay #(.dw(1), .len(3)) i_pipe_lat (
      .clk  (clk), .reset (1'b0), .gate  (1'b1),
      .din   (pulse_on), .dout  (pulse_on_dly));

   reg fall=0;
   reg [LENGTH_WI-1:0] len_cnt, rise_cnt, fall_t;
   always @(posedge clk) begin
      if (start&~pulse_on) begin // Ignore if already pulsing
         pulse_on <= 1;
         len_cnt  <= 0;
         rise_cnt <= 0;
         fall     <= 0;
         fall_t   <= 0;
      end

      if (pulse_on_dly) begin
         len_cnt <= len_cnt + 1;

         if (len_cnt == length) pulse_on <= 0; // Strictly enforce pulse length
         if ((fall_t != 0) && (len_cnt == fall_t)) fall <= 1;

         if (x_railed_r && y_railed_r)
            fall_t <= length - rise_cnt - 5;
         else
            rise_cnt <= rise_cnt + 1;
      end
   end

   wire x_pos = ~setp_x[DWI-1];
   wire y_pos = ~setp_y[DWI-1];

   reg [DWI-2:0] setp_x_us, setp_y_us;
   reg [DWI-2:0] x_us=0, y_us=0;
   reg signed [DWI-1:0] x_next=0, y_next=0;
   always @(posedge clk) begin
      setp_x_us <= x_pos ? setp_x : -setp_x;
      setp_y_us <= y_pos ? setp_y : -setp_y;
      if (pulse_on) begin
         x_next <= setp_x_us;
         if (!x_railed) x_next <= fall ? x_next - slew_lim : x_next + slew_lim;

         y_next <= setp_y_us;
         if (!y_railed) y_next <= fall ? y_next - slew_lim : y_next + slew_lim;
      end else begin
         x_next <= 0;
         y_next <= 0;
      end
   end

   reg x_railed=0, y_railed=0;
   reg x_railed_r=0, y_railed_r=0;
   reg x_zero=0, y_zero=0;
   always @(posedge clk) if (pulse_on) begin
      {x_railed_r, y_railed_r} <= {x_railed, y_railed}; // Match pipeline
      if (!fall) begin
         {x_railed, x_us} <= x_next >= setp_x_us ? {1'b1, setp_x_us} : {1'b0, x_next[DWI-2:0]};
         {y_railed, y_us} <= y_next >= setp_y_us ? {1'b1, setp_y_us} : {1'b0, y_next[DWI-2:0]};
      end else begin
         {x_railed, y_railed} <= 2'b0;
         if (x_zero) x_us <= 0;
         else {x_zero, x_us} <= x_next <= 0 ? {1'b1, {DWI-1{1'b0}}} : {x_zero, x_next[DWI-2:0]};

         if (y_zero) y_us <= 0;
         else {y_zero, y_us} <= y_next <= 0 ? {1'b1, {DWI-1{1'b0}}} : {y_zero, y_next[DWI-2:0]};
      end
   end else begin
      {x_zero, x_railed, x_us} <= 0;
      {y_zero, y_railed, y_us} <= 0;
   end

   reg signed [DWI-1:0] out_x_r, out_y_r;
   always @(posedge clk) begin
      out_x_r <= x_pos ? x_us : -x_us;
      out_y_r <= y_pos ? y_us : -y_us;
   end
   assign out_x = out_x_r;
   assign out_y = out_y_r;
   assign busy = pulse_on;
endmodule
