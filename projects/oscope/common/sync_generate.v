module sync_generate #(
	parameter cw=10,
	parameter minc=128
) (
	input clk,
	input [cw-1:0] cset,
	output sync
);

reg [cw-1:0] count=0;
reg ctl_bit=0, invalid=0;
wire rollover = count==1;
always @(posedge clk) begin
	count <= rollover ? cset : (count-1);
	invalid <= cset < minc;
	if (rollover) ctl_bit <= ~ctl_bit | invalid;
end
assign sync = ctl_bit;

endmodule
