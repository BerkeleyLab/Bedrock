// Four orders of CIC interpolation,
// data path interleaved so one result comes out every four cycles.
// Input can be provided at any order.

// Parameter squelch causes output to be driven as 18'bx during
// non-meaningful time slots; might be helpful when visualizing simulations.

module cic_bankx #(
	parameter shift=2,
	parameter stage=5,
	parameter squelch=0
) (
	input clk,
	input [1:0] subcycle,
	input init,
	input signed [17:0] mem_v,
	output signed [17:0] drive_delta,
	output signed [17:0] drive,
	output error
);

reg signed [17+shift:0] sr1=0, sr2=0, sr3=0, sr4=0;
reg signed [18:0] delta=0;
wire signed [17:0] loop = subcycle==3 ? 18'b0 : sr2 >>> shift;
reg carry1=0, error_r=0;
always @(posedge clk) begin
	delta <= (loop >>> stage) + mem_v;
	{carry1, sr1} <= init ? delta <<< shift : sr4 + delta;
	sr2 <= sr1;
	sr3 <= sr2;
	sr4 <= sr3;
	error_r <= carry1 != sr1[17+shift];
end
assign error = error_r;
wire signed [17:0] drive_delta_l = squelch & (subcycle != 1) ? 18'bx : delta;
assign drive_delta = drive_delta_l >>> shift;
assign drive = squelch & (subcycle != 2) ? 18'bx : sr1 >>> shift;

endmodule
