// cordicg_tb.v
// Test bench for CORDIC routine, designed so post-processing can check accuracy
// Larry Doolittle, LBNL

`timescale 1ns / 1ns

`ifndef DPW
`define DPW 22
`endif

module main();

// Configure here, or override externally
parameter width = 18;
parameter nstg = 20;

reg clk, rmix;
reg [1:0] op;
initial clk=0;
integer cc;
reg signed [width-1:0] xin;
reg signed [width-1:0] yin=0;
reg signed [width:0] phasein=0;
reg rand1, rand2, rand3, rand4, rand5, rand6, rand7, rand8;  // single bits
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("cordic.vcd");
		$dumpvars(5,main);
	end
	$display("xxx width %d", width);
	if (!$value$plusargs("rmix=%d", rmix)) rmix=0;
	if (!$value$plusargs("op=%d", op)) op=0;
	if (op==3) begin
		xin=153 << (width-9);
	end else if (op==1) begin
		xin=153 << (width-9);     // x^2 + y^2 needs to stay < 32767/1.64676 = 19897
	end else begin
		xin=106 << (width-9);
	end
	for (cc=0; cc<8000; cc=cc+1) begin
		clk=0; #10;
		clk=1; #10;
	end
	$finish();
end

reg [6:0] pstate=0;
wire [6:0] pstate_sum=pstate+10;
parameter den=61;
reg interleave=0;
always @(posedge clk) if (rmix) begin
	{rand1,rand2,rand3,rand4,rand5,rand6,rand7,rand8} = $random;
	xin <= rand1+rand2+rand3+rand4+rand5+rand6+rand7+rand8+30;
	// variance 4, peak-peak 8, rms 2
	pstate <= pstate_sum - ((pstate_sum >= den) ? den : 0);
	phasein <= pstate*8595;
end else if (op==3) begin
	interleave <= ~interleave;
	if (interleave) begin
		yin <= cc*9;
		xin <= 5000;
		if (cc>4000) xin <= 5000-3*cc;
	end else begin
		xin <= 10000;
		yin <= 0;
	end
end else if (op==1) begin
	// consider the following transformations:
	// honest rotation matrix
	//  yin <=  yin*cos(theta) + xin*sin(theta);
	//  xin <= -yin*sin(theta) + xin*cos(theta);
	// small-angle approximation of that for theta = 2^(-9) radians
	//  yin <= yin - (yin>>>19) + (xin>>>9);
	//  xin <= xin - (xin>>>19) - (yin>>>9);
	// corresponding CORDIC stage, gain \approx 1+2^(-19)
	//  yin <= yin + (xin>>>9);
	//  xin <= xin - (yin>>>9);
	// what we actually use, gain \approx 1-2^(-15), so it
	// spirals in slowly and exercises a meaningful span of
	// radial output without risking overflow
	yin <= yin + (xin>>>9) - (yin>>>15);
	xin <= xin - (yin>>>9) - (xin>>>15);
end else begin
	phasein<=phasein+53;
	if (cc>30) yin<=yin+1;
end

wire signed [width-1:0] xout, yout;
wire [width:0] pout;
// testing follow mode: op==3, interleave opp=3 with opp=1
wire [1:0] opp = op&{interleave,1'b1};
localparam cordic_delay = nstg;
cordicg_b`DPW #(.width(width), .nstg(nstg)) dut(clk, opp, xin, yin, phasein, xout, yout, pout);
reg [width:0] ppout;
reg signed [width-1:0] xxout, yyout;
reg        [width  :0] pp[31:0];
reg signed [width-1:0] xp[31:0];
reg signed [width-1:0] yp[31:0];
reg [4:0] pipe_ix=0;
reg signed [width:0] p_show;
reg signed [width-1:0] x_show, y_show;
reg [1:0] o_show;
always @(posedge clk) begin
	xxout = xout;
	yyout = yout;
	ppout = pout;
	// Match the pipeline delay inside CORDIC.
	// You know when the lengths match when column 1 and 2 both become
	// non-x at the same time.
	pp[pipe_ix] <= phasein;
	xp[pipe_ix] <= xin;
	yp[pipe_ix] <= yin;
	p_show <= pp[pipe_ix];
	x_show <= xp[pipe_ix];
	y_show <= yp[pipe_ix];
	o_show <= opp;
	pipe_ix <= pipe_ix == (cordic_delay-1) ? 0 : pipe_ix+1;
	$display("%7d %7d %7d %7d %7d %7d %7d", p_show, x_show, y_show, xxout, yyout, ppout, o_show);
end
endmodule
