// Synthesizes to 251 slices at 116 MHz in XC3Sxxx-4 using XST-8.2i
`timescale 1ns / 1ns

module half_filt(
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input signed [19:0] ind,  // Input data
	input ing,  // Active high gate marking input data as valid
	output signed [19:0] outd,  // Output data
	output outg,  // Active high gate marking output data as valid
	input reset  // manually reset counter
);

parameter len = 4;  // number of interleaved data streams
wire signed [19:0] d0, d1, d2, d3, d4, d5, d6, d7, d8, d9, d10;

assign d0 = ind;
reg_delay #(.dw(20),.len(len)) h0(clk, ing, d0, d1);
reg_delay #(.dw(20),.len(len)) h1(clk, ing, d1, d2);
reg_delay #(.dw(20),.len(len)) h2(clk, ing, d2, d3);
reg_delay #(.dw(20),.len(len)) h3(clk, ing, d3, d4);
reg_delay #(.dw(20),.len(len)) h4(clk, ing, d4, d5);
reg_delay #(.dw(20),.len(len)) h5(clk, ing, d5, d6);
reg_delay #(.dw(20),.len(len)) h6(clk, ing, d6, d7);
reg_delay #(.dw(20),.len(len)) h7(clk, ing, d7, d8);
reg_delay #(.dw(20),.len(len)) h8(clk, ing, d8, d9);
reg_delay #(.dw(20),.len(len)) h9(clk, ing, d9, d10);

reg signed [20:0] s1=0, s2=0, s3=0, s4=0;
reg sg=0;
always @(posedge clk) begin
	s1 <= d0 + d10;
	s2 <= d2 + d8;
	s3 <= d4 + d6;
	s4 <= d5 + 0; // {d5[19],d5};
	sg <= ing;
end

// FIR filter coefficients:
// 2*(1/32 0 -1/8-1/64 0 1/2+1/8-1/64 1 1/2+1/8-1/64 0 -1/8-1/64 0 1/32)/4
// see lowp3.m

reg signed [21:0] a1=0, a2=0, a3=0, a4=0;
reg ag=0;
always @(posedge clk) begin
`ifdef TRUST_VERILOG_DIVISION
	a1 <= s1/16 + 0;
	a2 <= s2/4 + s2/32;
	a3 <= s3/4 - s3/32;
	a4 <= s3 + 2*s4;
`else
	a1 <= {{5{s1[20]}},s1[20:4]};
	a2 <= {{3{s2[20]}},s2[20:2]} + {{6{s2[20]}},s2[20:5]};
	a3 <= {{3{s3[20]}},s3[20:2]} - {{6{s3[20]}},s3[20:5]};
	a4 <= {{1{s3[20]}},s3[20:0]} + {            s4[20:0],1'b0};
`endif
	ag <= sg;
end

reg signed [22:0] b1=0, b2=0;
reg bg=0;
reg [8:0] samp=0;
reg show=0;
always @(posedge clk) begin
	b1 <= a1 - a2;
	b2 <= a3 + a4 + 1;
	bg <= ag;
	if (reset) begin
		samp <= 0;
		show <= 0;
	end
	else begin
		if (bg) begin
			samp <= (samp==len-1'b1) ? 0 : samp+1'b1;
			if (samp==len-1) show <= ~show;
		end
	end
end

wire signed [21:0] c1;
sat_add #(23,22) finals(clk,b1,b2,c1);
reg cg=0;
always @(posedge clk) cg <= bg & show;

assign outd = c1[21:2];
assign outg = cg;

endmodule
