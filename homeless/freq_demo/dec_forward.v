module dec_forward #(
	parameter dw=16
) (
	input clk,
	input [dw-1:0] bdata,
	input load,
	input [3:0] dig_cnt,  // preferably constant
	output [3:0] nib_out,
	output rts,
	input cts
);

// Conversion to decimal (BCD) in reverse digit order
wire [3:0] nibble;
wire nstrobe;
b2decimal #(.dw(dw)) b2d(.clk(clk), .bdata(bdata), .load(load),
	.nibble(nibble), .nstrobe(nstrobe));

// RAM to hold results and allow reversal of the order of nibbles
reg [3:0] nram[0:15];
reg [3:0] npt;  // up to 15 digits
reg [3:0] nib_out_r;
reg phase1, phase2;
wire nwe = nstrobe & phase1;
always @(posedge clk) begin
	if (nwe) nram[npt] <= nibble;
	nib_out_r <= nram[npt];
end
assign nib_out = nib_out_r;

// State machine
reg rts_r;
always @(posedge clk) begin
	if (load) begin phase1 <= 1; phase2 <= 0; end
	if (load) npt <= 0;
	if (nwe) begin
		if (npt == dig_cnt-1) begin phase1 <= 0; phase2 <= 1; end
		else npt <= npt+1;
	end
	if (phase2 & cts) npt <= npt-1;
	if ((npt == 0) & cts) phase2 <= 0;
	rts_r <= phase2;
end
assign rts = rts_r;

endmodule
