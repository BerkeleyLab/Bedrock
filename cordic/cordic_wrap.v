// Make a clean synthesis in the fabric, away from the I/O cells
`timescale 1ns / 1ns
module cordic_wrap(
	input clk,  // timespec 8.0 ns
	input [18:0] data,
	input [3:0] strobe,
	input [1:0] osel,
	output reg [18:0] d_out
);


// Just grab things at the IOB
reg [18:0] d1=0;
reg [3:0] s1=0;
reg [1:0] o1=0;
always @(posedge clk) begin
	d1 <= data;
	s1 <= strobe;
	o1 <= osel;
end

// Set up input registers in the fabric
reg [17:0] xin=0, yin=0;  reg [18:0] phasein=0;  reg [1:0] opin=0;
always @(posedge clk) begin
	if (s1[0]) opin <= d1;
	if (s1[1]) xin <= d1;
	if (s1[2]) yin <= d1;
	if (s1[3]) phasein <= d1;
end

// Instantiate!
wire [17:0] xout, yout; wire[18:0] phaseout;
cordicg_b22 #(18) dut(
	.clk(clk), .opin(opin), .xin(xin), .yin(yin), .phasein(phasein),
	.xout(xout), .yout(yout), .phaseout(phaseout));


// collapse
reg [18:0] latch=0;
always @(posedge clk) case(o1)
	2'b00: latch <= 0;
	2'b01: latch <= phaseout;
	2'b10: latch <= xout;
	2'b11: latch <= yout;
endcase

// IOB again
always @(posedge clk) d_out <= latch;

endmodule
