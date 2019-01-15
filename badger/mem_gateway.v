// Uber-simple mapping of a UDP packet to a register read/write port.
// Lead with 64 bits of padding (sequence number, ID, nonce, ...),
// then alternate 32 bits of control+address with data.
// Stick with 24 bits of address, leave 8 bits for control.
// Only one of those control bits is actually used, it's the R/W line.
// Every packet is returned to the sender with the read data filled in.
// Local bus read latency is fixed, configurable at compile time.
// Uses standard network byte order (big endian).

// Software and local-bus compatible with mem_gateway in ethernet-core

module mem_gateway(
	input clk,   // timespec 6.8 ns
	// client interface with RTEFI, see clients.eps
	input [10:0] len_c,
	input [7:0] idata,
	input raw_l,
	input raw_s,
	output [7:0] odata,
	// local bus
	output [23:0] addr,
	output control_strobe,
	output control_rd,
	output control_rd_valid,
	output [31:0] data_out,
	input [31:0] data_in
);

parameter read_pipe_len=3;
parameter n_lat=8;  // minimum allowed value is 5 + read_pipe_len

// Pipeline match
wire [7:0] pdata;
reg_delay #(.len(read_pipe_len+1), .dw(8)) align(.clk(clk), .gate(1'b1), .reset(1'b0),
	.din(idata), .dout(pdata));

// Create localbus output signals
reg [63:0] isr=0;  // input shift register
wire [63:0] next_isr = {isr[55:0], idata};
reg [63:0] big_r=0;  // command, address, data
reg [31:0] data_out_r=0;
reg [2:0] c8=0;
reg body=0;
wire next_do_op = body & &c8;
reg do_op=0;
always @(posedge clk) begin
	isr <= {isr[55:0], idata};
	c8 <= raw_s ? c8+1 : 0;
	if (&c8) body <= 1;
	if (~raw_s) body <= 0;
	if (next_do_op) big_r <= next_isr;
	do_op <= next_do_op;
end
assign addr = big_r[23+32:32];
assign data_out = big_r[31:0];
assign control_rd = big_r[28+32];
assign control_strobe = do_op;

// Synchronize and capture result
wire capture;
reg_delay #(.len(read_pipe_len), .dw(1)) sync(.clk(clk),
	.gate(1'b1), .reset(1'b0),
	.din(do_op & control_rd), .dout(capture));
reg [31:0] osr=0;
always @(posedge clk) begin
	osr <= {osr[23:0], pdata};
	if (capture) osr <= data_in;
end
wire [7:0] xdata = osr[31:24];
assign control_rd_valid = capture;

// Final alignment
reg_delay #(.len(n_lat-read_pipe_len-5), .dw(8)) finale(.clk(clk),
	.gate(1'b1), .reset(1'b0),
	.din(xdata), .dout(odata));

endmodule
