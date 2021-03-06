`timescale 1ns / 1ns

// in this module,
// data flows from in_iq, through the CORDIC, to out_mp
// data flows from in_xy and in_ph, through the CORDIC, to out_iq
// delay is 23 clock cycles

//               1   2   3   4         23  24  25  26  27
// clk      -\_/-\_/-\_/-\_/-\_/-..._/-\_/-\_/-\_/-\_/-\_/-\
// phase    ___/---\___/---\___/-..._/---\___/---\___/---\__
// in_iq     .   I   Q   .   .         .   .   .   .   .
// out_mp    .   .   .   .   .         .   M   P   .   .
// in_xy     .   .   X   Y   .         .   .   .   .   .
// in_ph     .   .   .   P   .         .   .   .   .   .
// out_iq    .   .   .   .   .         .   .   I   Q   .
module cordic_mux(
	input clk,
	input phase,
	// rectangular ports
	input  signed [17:0] in_iq,
	output signed [17:0] out_iq,
	// polar ports
	input  signed [17:0] in_xy,
	input  signed [18:0] in_ph,
	output signed [17:0] out_mp
);

wire signed [17:0] in_iq_se = {in_iq[17],in_iq[17:1]};
reg  signed [17:0] in_iq_hold=0;
reg  signed [17:0] in_xy_hold=0;
always @(posedge clk) begin
	in_iq_hold <= in_iq_se;
	in_xy_hold <= in_xy;
end

// CORDIC input selection
wire signed [17:0] feed_x = phase ? in_xy_hold : in_iq_hold;
wire signed [17:0] feed_y = phase ? in_xy      : in_iq_se;
wire signed [18:0] feed_z = phase ? in_ph      : 0;

// CORDIC instantiation
wire signed [17:0] out_x, out_y;
wire signed [18:0] out_z;
cordicg_b22 #(.nstg(20), .width(18)) cordic(.clk(clk), .opin({1'b0,~phase}),
	.xin(feed_x), .yin(feed_y), .phasein(feed_z),
	.xout(out_x), .yout(out_y), .phaseout(out_z)
);

// output stream generation
reg signed [17:0] hold_y=0, out_iq_r=0, out_mp_r=0;
reg signed [18:0] hold_z=0;
always @(posedge clk) begin
	hold_y <= out_y;
	hold_z <= out_z;
	out_iq_r <= phase ? hold_y : out_x;
	out_mp_r <= phase ? out_x : hold_z[18:1];
end

assign out_iq = out_iq_r;
assign out_mp = out_mp_r;

endmodule
