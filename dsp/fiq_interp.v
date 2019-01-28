`timescale 1ns / 1ns

// Name: IQ interpolator
//% Takes interleaved I-Q, produces interpolated,
//% separate streams ready for upconversion
module fiq_interp(
	input clk,
	input [a_dw-1:0] a_data,  // Interleaved I-Q Data
	input a_gate,  // Data valid gate
	input a_trig,  // 1 bit information telling data is I or Q
	output [i_dw-1:0] i_data,
	output i_gate,
	output i_trig,
	output [q_dw-1:0] q_data,
	output q_gate,
	output q_trig,
	output time_err
);

parameter a_dw=16;
parameter i_dw=17;
parameter q_dw=17;

wire iq_sync = a_trig;
reg signed [a_dw-1:0] iq_in1=0, iq_in2=0;
always @(posedge clk) begin
	iq_in1 <= a_data;
	iq_in2 <= iq_in1;
end
wire signed [a_dw-1:0] i_raw = iq_sync ? iq_in1 : a_data;
wire signed [a_dw-1:0] q_raw = iq_sync ? iq_in2 : iq_in1;

reg signed [a_dw-1:0] i_raw1=0, q_raw1=0;
reg signed [a_dw  :0] i2i=0, i2q=0;
always @(posedge clk) begin
	i_raw1 <= i_raw;
	q_raw1 <= q_raw;
	i2i <= i_raw + i_raw1;
	i2q <= q_raw + q_raw1;
end

reg last_sync=0, time_err_r=0;
always @(posedge clk) begin
	last_sync <= iq_sync;
	time_err_r <= ~a_gate | (iq_sync & ~last_sync);
end

assign i_data = i2i;
assign i_gate = 1'b1;
assign i_trig = 1'b1;
assign q_data = i2q;
assign q_gate = 1'b1;
assign q_trig = 1'b1;
assign time_err = time_err_r;

endmodule
