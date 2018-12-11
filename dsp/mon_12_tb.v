`timescale 1ns / 1ns
`include "constants.vams"

module mon_12_tb;

integer den, logden;
reg [2:0] shift;
real fden, fnum, ampi, ampo_expect, phsi, phs_marg;
reg overload=0;
initial begin
	// Test not designed to work with phsi near pi
	// 4 <= den <= 128, no factor of fnum
	if (!$value$plusargs("amp=%f", ampi)) ampi=10000.0;
	if (!$value$plusargs("phs=%f", phsi)) phsi=0.0;
	if (!$value$plusargs("den=%d", den )) den=16;
	ampo_expect=ampi;
	phs_marg=0.00002;
	phs_marg=0.95/ampi;
	if (ampi > 32765.0) begin
		overload=1;
		ampo_expect=32764.0;
		phs_marg=0.2;
	end
	$display("ampi=%.2f  ampo_expect=%.2f  phsi=%.5f  phs_marg=%.5f",
		ampi, ampo_expect, phsi, phs_marg);
	fden=den;
	fnum=3.0;
	logden=$clog2(den);
	shift=logden-2;
	$display("den=%d  logden=%d  shift=%d", den, logden, shift);
end

reg clk;
integer cc, errors;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("mon_12.vcd");
		$dumpvars(5,mon_12_tb);
	end
	errors=0;
	$display("    X1      Y1      X2      Y2     R1    OK   Phi1  OK");
	for (cc=0; cc<32*den; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s",errors==0?"PASS":"FAIL");
	$finish();
end

reg signed [15:0] adc=0;
integer noise;
integer nseed=1234;

integer ccmod;
real th0, tha, thb;
reg signed [17:0]  cosa=0, sina=0, cosb=0, sinb=0;
reg signed [17:0] xcosa,  xsina,  xcosb,  xsinb;
integer ax;  // can be huge in the face of clipping.  Don't be stupid and
	// set amplitude larger than 2^31 in ADC sine wave below.
	// 100 X overdrive is plenty for this purpose.
reg sample=0;
always @(posedge clk) begin
	noise = $dist_normal(nseed,0,1024);
	th0 = (cc)*`M_TWO_PI*fnum/fden - phsi;
	ax = $floor(ampi*$cos(th0)+0.5+noise/1024.0);
	if (ax >  32767) ax =  32767;
	if (ax < -32678) ax = -32768;
	adc <= ax;
	// $display("%d adc", adc);
	ccmod = cc%den;
	tha = ccmod*`M_TWO_PI*fnum/fden;
	// Scaling of LO is non-obvious.  Set such that a square-wave input
	// can't overflow CIC.  Conceptually that's pi/2, so set to pi/4 of full
	// scale and absorb a factor of two later.
	// 2^17 = 131072 - a little bit to cover rounding
	xcosa = $floor(131070.0*$cos(tha)+0.5);  cosa <= xcosa;
	xsina = $floor(131070.0*$sin(tha)+0.5);  sina <= xsina;
	thb = ccmod*`M_TWO_PI*7.0/fden;
	xcosb = $floor(13107.00*$cos(tha)+0.5);  cosb <= xcosb;
	xsinb = $floor(13107.00*$sin(tha)+0.5);  sinb <= xsinb;
	sample <= ccmod==0;
end

parameter dw=32;
wire [dw-1:0] sr_out;
wire sr_val;
cim_12x #(.dw(32)) cim(.clk(clk), .adca(adc), .adcb(adc),
	.reset(1'b0),
	.adcc(16'b0), .inm(16'b0), .outm(16'b0), .adcx(16'b0),
	.cosa(cosa), .sina(sina), .cosb(cosb), .sinb(sinb),
	.sample(sample),
	.sr_out(sr_out), .sr_val(sr_val)
);

wire strobe;
reg use_raw=0;
wire signed [19:0] result;
ccfilt #(.dsr_len(12), .dw(dw)) ccfilt(.clk(clk), .reset(1'b0),
	.sr_out(sr_out), .sr_val(sr_val),
	.shift({shift,1'b1}),
	.result(result), .strobe(strobe)
);

reg strobe1=0;
integer col=0;
parameter dsr_len=12;
reg signed [19:0] out_set[0:dsr_len-1];
always @(posedge clk) begin
	strobe1 <= strobe;
	if (strobe) begin
		col <= (col==dsr_len-1) ? 0 : col+1;
		out_set[col] <= result;
		// $display("%d: out[%d] <= %d", cc, col, result);
	end
end

real xr, xi, ampo, phso;
reg amp_pass, phs_pass, fault, use_row;
always @(negedge clk) if (cc/den > 18) begin
	//if (strobe & ~strobe1) $display("#");
	//if (strobe) $display("%d", result);
	xr=out_set[0];
	xi=out_set[1];
	ampo=$sqrt(xr*xr+xi*xi)/(fden*fden)*(1<<(2*shift));
	ampo=ampo*131072.0/131070.0;
	phso=$atan2(xi,xr);
	amp_pass = overload ? ampo > ampo_expect :
		((ampo > ampo_expect*0.99995-0.7) & (ampo < ampo_expect*1.00005+0.7));
	phs_pass = (phso>phsi-phs_marg) & (phso<phsi+phs_marg);

	if (strobe && (col==0)) begin
		$display("%d %d %d %d  %8.2f %b %8.5f %b %s.",
			out_set[0], out_set[1], out_set[2], out_set[3],
			ampo, amp_pass, phso, phs_pass, fault ? "FAULT" : "");
		fault = (~amp_pass | ~phs_pass);
		if (fault) errors=errors+1;
	end
end

endmodule
