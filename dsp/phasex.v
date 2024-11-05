`timescale 1ns / 1ns

// DMTD-inspired investigation into clock phasing
// No on-chip analysis, but that could be added later once we see the captured patterns
module phasex #(
	parameter aw=10
) (
	input uclk1,  // unknown clock 1
	input uclk2,  // unknown clock 2
	input sclk,   // sampling clock
	input rclk,   // readout clock (data transfer, local bus)
	// all of the following are in rclk domain
	input trig,
	output ready,
	input [aw-1:0] addr,
	output [15:0] dout
);

// Move software-created trigger to sclk domain
wire trig2;
flag_xdomain trigx(.clk1(rclk), .flagin_clk1(trig),
	.clk2(sclk), .flagout_clk2(trig2));

// Dividers for snapshot operation
reg div1=0, div2=0;
always @(posedge uclk1) div1 <= ~div1;
always @(posedge uclk2) div2 <= ~div2;

// Control logic in sclk domain
// aw bits row address, 3 bits to control stuffing of 8 bit-pairs into one 16-bit word
reg [aw+2:0] count=0;
reg run=0;
always @(posedge sclk) begin
	if (trig2) run <= 1;
	if (run) count <= count+1;
	if (&count) run <= 0;
end
wire wen = run & (&count[2:0]);
wire [aw-1:0] waddr = count[aw+2:3];

// Data flow logic, also in sclk domain
reg [15:0] shiftr=0;
(* ASYNC_REG = "TRUE" *) reg [1:0] snap=0;
always @(posedge sclk) begin
	snap <= {div2, div1};  // safely crosses clock domain
	if (run) shiftr <= {shiftr[13:0], snap};
end

// Store the result
dpram #(.aw(aw), .dw(16)) mem(.clka(sclk), .clkb(rclk),
	.addra(waddr), .dina(shiftr), .wena(wen),
	.addrb(addr), .doutb(dout));

// Single status bit, OK to capture in rclk domain
reg ready_r=0;
reg invalid=0;
always @(posedge rclk) begin
	ready_r <= ~run;  // safely crosses clock domain
	if (trig) invalid <= 1;
	if (~ready_r) invalid <= 0;
end
assign ready = ready_r & ~invalid;

endmodule
