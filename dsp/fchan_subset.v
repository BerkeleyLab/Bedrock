`timescale 1ns / 1ns

// Name: Channel Subset
//% Runtime-configurable selection of which data to keep within each block
//% Typically used on the input to a waveform memory
module fchan_subset #(
	parameter KEEP_OLD = 0,
	parameter a_dw     = 20,
	parameter o_dw     = 20,
	parameter len      = 16
) (
	input clk,
	input reset,
	input [len-1:0] keep,
	input signed [a_dw-1:0] a_data,
	input a_gate, a_trig,
	output signed [o_dw-1:0] o_data,
	output o_gate, o_trig,
	output time_err
);

// Reverse bit order of mask
//   We use historical code in fchan_subset that defines its keep input in
//   the left-to-right sense.  But for ease of documentation and consistency
//   with banyan switch code, our keep input has its bits counted from
//   right to left:  lsb is bit 0, corresponds to channel 0.
wire [len-1:0] keep_use;
genvar ix;
generate
	if (KEEP_OLD==1) begin : G_KEEP_OLD
		for (ix=0; ix<len; ix=ix+1) begin
			assign keep_use[ix] = keep[len-1-ix];
		end
	end
	else begin : G_NKEEP_OLD
		for (ix=0; ix<len; ix=ix+1) begin
			assign keep_use[ix] = keep[ix];
		end
	end
endgenerate

reg [len-1:0] live=0;
always @(posedge clk) begin
    if (reset)
        live <= 0;
    else if (a_gate|a_trig) live <= a_trig ? keep_use : {live[len-2:0],1'b0};
end

assign o_data = a_data;
assign o_gate = a_gate & live[len-1];
assign o_trig = a_trig;

demand_gpt #(.gpt(len)) tcheck(.clk(clk), .gate(a_gate), .trig(a_trig), .time_err(time_err));

endmodule
