`timescale 1ns / 1ns

// Encapsulation of a register delay, z^{-n} in DSP-speak
// Properly handles odd-ball special cases like len==0
module reg_delay #(
	parameter dw=16,  // Width of data
	parameter len=4   // Cycles to delay
) (
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input reset,  // Please tie to 0 if you can; see below
	input gate,  // Enable processing
	input [dw-1:0] din,  // Input data
	output [dw-1:0] dout  // Output data
);

// When used in a Xilinx chip, ideally this logic is turned into
// a bunch of SRL16 shift registers or similar.  That works only if
// our reset port is tied to 1'b0 at instantiation site.
generate if (len > 1) begin: usual
	reg [dw*len-1:0] shifter=0;
	always @(posedge clk) begin
		if (gate) shifter <= {shifter[dw*len-1-dw:0],din};
		if (reset) shifter <= 0;
	end
	assign dout = shifter[dw*len-1:dw*len-dw];
end else if (len > 0) begin: degen1
	reg [dw*len-1:0] shifter=0;
	always @(posedge clk) begin
		if (gate) shifter <= din;
		if (reset) shifter <= 0;
	end
	assign dout = shifter[dw*len-1:dw*len-dw];
end else if (len == 0) begin: degen0
	assign dout = din;
end else begin: bad
	assign dout = din[-1:0];
end
endgenerate

endmodule
