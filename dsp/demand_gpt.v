`timescale 1ns / 1ns

// timing error logic for simple single-input module that
// requires a fixed gates-per-trig (gpt).
module demand_gpt(
	input clk,
	input gate,
	input trig,
	output time_err
);
parameter gpt=16;

reg time_err_r=0;
reg gate_check=0;
reg [8:0] count=0;  // XXX generous, but not general

always @(posedge clk) begin
	gate_check <= gate;
	count <= count + gate;
	if (trig && gate_check) begin
		time_err_r <= (count+gate) != gpt;
		count <= 0;
	end
end

assign time_err = time_err_r;

endmodule
