/* First-order low-pass filter (RC)
   y[n] = y[n-1] + k(x[n] - y[n-1])
   Pole at (1-k)

   Corner frequency (fc) set by:
   fc = k / [(1-k)*2*PI*dt]

   e.g.:
   dt = 20 ns
   k  = 0.5**21
   fc ~= 3.7946 Hz

   No need for saturated arithmetic, since gain is strictly less than unity.
*/

module lpass1 #(
   parameter dwi = 16,
   parameter klog2 = 21, // Actual k is 0.5**klog2; max 31
   parameter TRIM_SHIFT = 2
) (
   input clk,
   input [TRIM_SHIFT-1:0] trim_sh, // Move corner up in steps of 2x; Extra logic
                                   // should disappear if hardcoded
   input signed [dwi-1:0] din,
   output signed [dwi-1:0] dout
);
   wire [4:0] full_sh = klog2 - trim_sh;

   reg signed [dwi+klog2-1:0] dout_r=0;
   wire signed [dwi+klog2:0] sub = (din<<<full_sh) - dout_r; // Shift din to buy precision

   always @(posedge clk) begin
       dout_r <= dout_r + (sub>>>full_sh);
   end

   assign dout = dout_r>>>full_sh;

endmodule
