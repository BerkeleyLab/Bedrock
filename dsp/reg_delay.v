`timescale 1ns / 1ns

module reg_delay #(
	parameter dw=16,  // Width of data
	parameter len=4   // Cycles to delay
) (
	input clk, // Rising edge clock input; all logic is synchronous in this domain
	input reset,
	input gate, // Enable processing
	input [dw-1:0] din, // Input data
	output [dw-1:0] dout // Output data
);

// len clocks of delay.  Xilinx should turn this into
//   dw*floor((len+15)/16)
// SRL16 shift registers, when there reset is tied to 1'b0 at instantiation site.
generate if (len > 1) begin: usual
	reg [dw*len-1:0] shifter=0;
	always @(posedge clk) begin
		shifter <= reset ? 0 : gate ? {shifter[dw*len-1-dw:0],din} : shifter;
	end
	assign dout = shifter[dw*len-1:dw*len-dw];
end else if (len > 0) begin: degen1
	reg [dw*len-1:0] shifter=0;
	always @(posedge clk) begin
		shifter <= reset ? 0 : gate ? din : shifter;
	end
	assign dout = shifter[dw*len-1:dw*len-dw];
end
else begin: degen0
	assign dout = din;
end
endgenerate

endmodule
