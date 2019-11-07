`timescale 1ns / 1ns

// ------------------------------------
// cpxmul_fullspeed.v
//
// Full data-rate pipelined complex multiplier with 3-cycle latency, 4 hw multipliers
// and 2 adders
// Expects time-aligned parallel inputs on all data inputs
//
// ------------------------------------

module cpxmul_fullspeed #(
   parameter DWI = 18,
   parameter OUT_SHIFT = 17, // Down-shift full-precision result
   parameter OWI = 18
) (
   input clk,
   input signed [DWI-1:0] re_a,
   input signed [DWI-1:0] im_a,
   input signed [DWI-1:0] re_b,
   input signed [DWI-1:0] im_b,
   output signed [OWI-1:0] re_out,
   output signed [OWI-1:0] im_out
);

   // (re_a + j*im_a) * (re_b + j*im_b) =
   // (re_a*re_b - im_a*im_b) + j(re_a*im_b + im_a*re_b)
   reg signed [DWI*2-1:0] mul1=0, mul2=0, mul3=0, mul4=0;
   reg signed [DWI*2-1:0] sum1=0, sum2=0, sum3=0;
   reg signed [DWI*2-OUT_SHIFT-1:0] sum1_r=0, sum2_r=0;

   `define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
   always @(posedge clk) begin
      mul1 <= re_a*re_b;
      mul2 <= im_a*im_b;
      mul3 <= re_a*im_b;
      mul4 <= im_a*re_b;
      sum1 <= mul1 - mul2;
      sum2 <= mul3 + mul4;
      sum1_r <= sum1[DWI*2-1:OUT_SHIFT];
      sum2_r <= sum2[DWI*2-1:OUT_SHIFT];
   end

   assign re_out = `SAT(sum1_r, DWI*2-OUT_SHIFT-1, OWI-1);
   assign im_out = `SAT(sum2_r, DWI*2-OUT_SHIFT-1, OWI-1);

endmodule
