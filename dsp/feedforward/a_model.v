// Constructs a predicted cavity signal based on a drive waveform,
// as a component of model/controller system.
// Targeted at the amplitude component only, for an SRF cavity.
module a_model(
	input clk,
	input [1:0] subcycle,
	input signed [17:0] coeff,
	input signed [17:0] drive,
	output signed [17:0] cavity,
	output error
);

// subcycle = 2   coeff = drive coupling, drive input is valid
// subcycle = 3   coeff = cavity decay bandwidth
// subcycle = 0 or 1  other inputs are don't care
parameter shift = 3;

// As usual, negative-full-scale coeff is considered invalid
reg signed [17+shift:0] cavity_r=0;
wire signed [17:0] m_in = subcycle[0] ? (cavity_r >>> shift) : drive;
wire signed [35:0] m_result = m_in * coeff;
wire signed [17:0] m_result_s = m_result[34:17];
reg carry=0, error_r=0;
// XXX pipelining needs work
always @(posedge clk) if (subcycle[1]) begin
	{carry, cavity_r} <= cavity_r + m_result_s;
	error_r <= carry != (cavity_r[17+shift]) | (m_result[35] != m_result[34]);
end
assign cavity = cavity_r >>> shift;
assign error = error_r;

endmodule
