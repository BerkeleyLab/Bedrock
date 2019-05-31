// Short (2-32 long) FIFO meant to be efficiently implemented with
// Xilinx SRL16E or similar
// Except for the unified clock and the count output port,
// this is pin-compatible with ordinary fifo.v

module shortfifo #(
	parameter dw=8,
	parameter aw=4
) (
	// require single clock domain
	input clk,
	// input port
	input [dw-1:0] din,
	input we,
	// output port
	output [dw-1:0] dout,
	input re,
	// status
	output full,
	output empty,
	output [aw-1:0] count  // -1 == empty, -2 == full
);

reg [aw-1:0] raddr=~0;
genvar ix;
generate for (ix=0; ix<dw; ix=ix+1) begin: bit_slice
	abstract_dsr #(.aw(aw)) srl(.clk(clk), .ce(we), .addr(raddr),
		.din(din[ix]), .dout(dout[ix]) );
end endgenerate

localparam len = 1 << aw;
always @(posedge clk) #0 raddr <= raddr + we - re;
assign full = raddr == len-2;
assign empty = &raddr;
assign count = raddr;

endmodule

// should infer as a single SRL16E, SRL32E, ...
// See "Dynamic Shift Registers Verilog Coding Example" in UG687
module abstract_dsr #(
	parameter aw=4
) (
	input clk,
	input ce,
	input din,
	input [aw-1:0] addr,
	output dout
);
localparam len = 1 << aw;
reg [len-1:0] sr=0;
always @(posedge clk) if (ce) sr <= {sr[len-2:0],din};
assign dout = sr[addr];
endmodule
