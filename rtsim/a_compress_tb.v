`timescale 1ns / 1ns

module a_compress_tb;

// Nominal clock is 188.6 MHz, corresponding to 94.3 MHz ADC clock.
// 166.7 MHz is just a convenient stand-in.
reg clk;
reg trace;
integer cc;
`ifdef SIMULATE
initial begin
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("a_compress.vcd");
		$dumpvars(5,a_compress_tb);
	end
	for (cc=0; cc<660; cc=cc+1) begin
		clk=0; #3;
		clk=1; #3;
	end
	$finish();
end
`endif //  `ifdef SIMULATE

// Fake the drive signals
reg signed [17:0] d_in=0;
reg iq=0;
always @(posedge clk) begin
	iq <= ~iq;
	d_in <= 18'bx;
	if (cc==10) d_in <= 0;
	if (cc==11) d_in <= 10000;
	if (cc==30 || cc==31) d_in <= 100000;
	if (cc==50) d_in <= 500;
	if (cc>50) d_in <= d_in + (iq ? 0 : 432 );
end

// Configuration
reg [15:0] sat_ctl=65535;

wire signed [17:0] d_out, d_check;
a_compress a_compress(.clk(clk), .sat_ctl(sat_ctl),
	.iq(iq), .d_in(d_in), .d_out(d_out)
);

reg_delay #(.dw(18), .len(10))
	match(.clk(clk), .reset(1'b0), .gate(1'b1), .din(d_in), .dout(d_check));

`ifdef SIMULATE
always @(posedge clk) if (trace) begin
	if (cc>60 && ~iq) $display("%d %d", d_check, d_out);
end
`endif

endmodule
