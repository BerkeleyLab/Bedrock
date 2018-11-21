`timescale 1ns / 1ns

module sat_add(clk,a,b,sum);
	parameter isize=16;
	parameter osize=15;
	input clk;
	input signed [isize-1:0] a, b;
	output signed [osize-1:0] sum;
	// why do I need to explicitly sign-extend?
	wire signed [isize:0] s = {a[isize-1],a} + {b[isize-1],b};
	wire ok = ~(|s[isize:osize-1]) | (&s[isize:osize-1]);
	reg signed [osize-1:0] sr=0;
	always @(posedge clk)
		sr <= ok ? s[osize-1:0] : {s[isize],{osize-1{~s[isize]}}};
	assign sum = sr;
endmodule
