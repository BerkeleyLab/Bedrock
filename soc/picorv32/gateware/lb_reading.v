module lb_reading #(
	parameter READ_DELAY=3
) (
	input clk,
	input reset,
	input lb_read,
	output lb_rvalid
);

reg [READ_DELAY-1:0] shift=0;
reg reading_r=0;
always @(posedge clk)
	if (reset) begin
		reading_r <= 0;
		shift <= 0;
	end else begin
		if (lb_read) reading_r <= 1;
		if (lb_rvalid) reading_r <= 0;
		shift <= lb_rvalid ? 0 : {shift[READ_DELAY-2:0], lb_read};
	end

assign lb_rvalid = shift[READ_DELAY-1] & ~reset;

endmodule
