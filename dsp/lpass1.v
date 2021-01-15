/* First-order low-pass filter (RC)
   y[n] = y[n-1] + k(x[n] - y[n-1])
   Pole at (1-k)

   Corner frequency (fc) set by:
   fc = k / [(1-k)*2*PI*dt]
*/

module lpass1 #(
   parameter dwi = 16,
   parameter klog2 = 20 // Actual k is 2**klog2
) (
   input clk,
   input signed [dwi-1:0] din,
   output signed [dwi-1:0] dout
);

   reg signed [dwi+klog2-1:0] dout_r=0, dout_r2=0;
   wire signed [dwi+klog2:0] sub = (din<<<klog2) - dout_r2; // Shift din to buy precision

   always @(posedge clk) begin
       dout_r2 <= dout_r;
       dout_r <= dout_r2 + (sub>>>klog2);
   end

   assign dout = dout_r2[dwi+klog2-1:klog2];

endmodule
