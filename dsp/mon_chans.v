`timescale 1ns / 1ns

module mon_chans #(
	parameter NCHAN=1,
	parameter DWI=16,  // data width
	parameter RWI=28,  // result width
	// Difference between above two widths should be N*log2 of the maximum number
	// of samples per CIC sample, where N=2 is the order of the CIC filter.
	parameter DWLO=18,  // Local Oscillator data width
	parameter DAVR=3
) (
	input clk,  // timespec 8.4 ns
	input signed [NCHAN*DWI-1:0] adc,  // possibly muxed
	input signed [NCHAN*DWLO-1:0] mlo,
	input samp,
	input signed [RWI-1:0] s_in,
	output signed [RWI-1:0] s_out,
	input g_in,
	output g_out,
	input reset
);

reg [1:0] reset_r=0;
always @(posedge clk) reset_r <= {reset_r[0],reset};

wire signed [(NCHAN+1)*RWI-1:0] s_reg;//, s_reg2;
assign s_reg[(NCHAN+1)*RWI-1:NCHAN*RWI]=s_in;
wire [NCHAN:0] g_reg;//, g_reg2;
assign g_reg[NCHAN]=g_in;
wire signed [NCHAN*(DWI+DAVR)-1:0] mout;
wire signed [NCHAN*RWI-1:0] iout;

genvar ix;
generate for (ix=0;ix<NCHAN;ix=ix+1) begin : G_MIX_INTEG_SERIAL
   mixer #(
      .dwi(DWI),.davr(DAVR),.dwlo(DWLO))
   mixer(.clk(clk), .adcf(adc[DWI*(ix+1)-1:DWI*ix]), .mult(mlo[DWLO*(ix+1)-1:DWLO*ix]),
         .mixout(mout[(DWI+DAVR)*(ix+1)-1:(DWI+DAVR)*ix]));

   double_inte #(
      .dwi(DWI+DAVR),.dwo(RWI))
   double_inte(.clk(clk), .in(mout[(DWI+DAVR)*(ix+1)-1:(DWI+DAVR)*ix]),
               .out(iout[RWI*(ix+1)-1:RWI*ix]), .reset(reset_r[1]));

   serialize #(
      .dwi(RWI))
   serialize(.clk(clk), .samp(samp), .data_in(iout[RWI*(ix+1)-1:RWI*ix]),
             .stream_in(s_reg[RWI*(ix+2)-1:RWI*(ix+1)]),
             .stream_out(s_reg[RWI*(ix+1)-1:RWI*ix]),
             .gate_in(g_reg[ix+1]), .gate_out(g_reg[ix]));
end
endgenerate

assign s_out = s_reg[RWI*(0+1)-1:RWI*0];
assign g_out = g_reg[0];

endmodule
