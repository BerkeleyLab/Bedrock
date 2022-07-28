// chirp phase generator, quadratic binary NCO
//
// dphase = initial value of d phase / dt (a.k.a. frequency) at reset
// ddphase = d^2 phase / dt^2 (should be held constant during a chirp)
//
// If ddphase is not zero, you really should reset it frequently enough
// that dphase_r (the instantaneous frequency) never overflows.
// Such an overflow is detected (single-cycle) on the output error port.
// Overflows on phase are normal, just represent wrapping around 2*pi.

// Maybe a little inconsistent: the provided ddphase is used on every gate.
// but dphase is only sampled on reset.

// Since this is expected to run for many thousands of cycles, the abstract
// ddphase should be a very small number.  The dx parameter sets how many
// bits right to shift the input dw-bits-wide ddphase port, before adding it
// to dphase.  This module's internal datapath is therefore dw+dx bits wide.

// Note that dphase input parameter must be scaled by 2**DW, while
// ddphase must be scaled by 2**(DW+DX)

module parab #(
   parameter dw = 16,  // input dphase and ddphase width
   parameter dx = 16,  // internal right-shift for ddphase
   parameter ow = 16  // output phase word width
) (
   input  clk,
   input  gate,
   input  reset,

   input signed [dw-1:0] dphase,
   input signed [dw-1:0] ddphase,

   output                 gate_o,
   output signed [ow-1:0] phase,
   output error
);
   localparam aw=dw+dx;  // accumulator width

   reg signed [aw-1:0] phase_r=0;
   reg signed [aw-1:0] dphase_r=0;
   reg gate_r=0;
   reg extra, ovf=0;

   always @(posedge clk) begin
      if (reset) begin
         phase_r <= 0;
         dphase_r <= dphase << dx;
         extra <= dphase_r[aw-1];
      end else if (gate) begin
         phase_r <= phase_r + dphase_r;
         {extra, dphase_r} <= dphase_r + ddphase;
         ovf <= extra^dphase_r[aw-1];
      end
      gate_r <= gate;
   end

   assign phase  = phase_r[aw-1:aw-ow]; // Back to output width
   assign gate_o = gate_r;
   assign error  = ovf;

endmodule
