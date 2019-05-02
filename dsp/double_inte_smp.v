`timescale 1ns / 1ns

/** DOUBLE_INTE_SMP
    Variant of double_inte that can operate below the line rate by using an
    input strobe. Incoming samples are only accumulated when strobe is high.
**/

module double_inte_smp #(
  parameter dwi = 16, // data width in
  parameter dwo = 28) // data width out. When used for decimation, output width should
                      // be N*log2(decimation rate), where N=2 is the order of this
                      // double integrator.
(
   input                   clk,
   input                   reset,
   input                   stb_in,
   input  signed [dwi-1:0] in,
   output signed [dwo-1:0] out
);

reg [1:0] reset_r=0;
reg signed [dwo-1:0] int1=0, int2=0;
reg ignore=0;

always @(posedge clk) begin
   reset_r <= {reset_r[0],reset};
end

always @(posedge clk) begin
   if (|reset_r) begin
      {int1, ignore} <= 0;
      int2           <= 0;
   end else if (stb_in) begin
      {int1, ignore} <= $signed({int1, 1'b1}) + in;
      int2           <= int2 + int1;
   end
end

assign out = int2;

endmodule
