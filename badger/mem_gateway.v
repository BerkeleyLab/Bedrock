// Uber-simple mapping of a UDP packet to a register read/write port.
// Lead with 64 bits of padding (sequence number, ID, nonce, ...),
// then alternate 32 bits of control+address with data.
// Stick with 24 bits of address, leave 8 bits for control.
// One of those control bits is the R/W line.
// Every packet is returned to the sender with the read data filled in.
// Local bus read latency is fixed, configurable at compile time.
// Uses standard network byte order (big endian).
//
// This version has one more feature (disabled by default for paranoid
// compatibility reasons, see the enable_bursts parameter), where a repeat
// count for the following operation can be specified.  The address
// autoincrements in that case, and each repeated operation (read or write)
// consumes one more 32-bit data field in the input stream.  This feature
// has been tested, but so far it lacks meaningful software support.
//
// For a longer description of the on-the-wire protocol, see mem_gate.md
// Software and local-bus compatible with mem_gateway in ethernet-core.

// The control_rd port (a.k.a. not write) is just a level that changes at
// the start of each transaction, timing exactly like addr and data_out.
//
// control_pipe_rd is new; it's for people who want to pay attention to
// the pipelining of each read operation.  It shows the strobe propagating
// all the way from the start of the read request to the cycle (marked by
// control_rd_valid, exactly equal to control_pipe_read[read_pipe_len]) when
// this module latches data_in.  Note that the "active" bit(s) flow through
// all read_pipe_len cycles of activity, plus one more at the end, and thus
// has a possibly surprising length.
//
// If read_pipe_len is increased, and bus cycles are spaced close together
// (traditionally every 8 cycles, goes down to every 4 when bursts are used)
// there can be multiple bus transactions in the pipeline simultaneously.

// Write operations start on the cycle marked by control_write.
// At the moment, there is no check that they complete, so any pipelining
// that takes place is outside the purview of this module.

module mem_gateway #(
	parameter read_pipe_len=3,  // minimum allowed value is 1
	parameter n_lat=8,  // minimum allowed value is 5 + read_pipe_len
	parameter enable_bursts=0
) (
	input clk,   // timespec 6.8 ns
	// client interface with RTEFI, see doc/clients.eps
	input [10:0] len_c,
	input [7:0] idata,
	input raw_l,
	input raw_s,
	output [7:0] odata,
	// local bus
	output [23:0] addr,
	output control_strobe,
	output control_rd,
	output control_write,
	output control_rd_valid,
	// length of control_pipe_rd is read_pipe_len+1, see above
	output [read_pipe_len:0] control_pipe_rd,
	output [31:0] data_out,
	input [31:0] data_in
);

// Pipeline match
wire [7:0] pdata;
reg_delay #(.len(read_pipe_len+1), .dw(8)) align(.clk(clk), .gate(1'b1), .reset(1'b0),
	.din(idata), .dout(pdata));

// Create localbus output signals
reg [8:0] repeat_count=0;
reg [23:0] isr=0;  // input shift register
wire [31:0] next_isr = {isr, idata};
reg [63:0] big_r=0;  // command, address, data
reg [1:0] c4=0;
reg data_phase=0;
reg pre_body=0, body=0;
reg do_op=0;
wire next_do_op = body & &c4 & data_phase;
wire set_repeat = ~data_phase & next_isr[29] & enable_bursts;
wire set_repeat_view = body & &c4 & set_repeat; // Debug signal
reg inc_address=0;
always @(posedge clk) begin
	isr <= next_isr[23:0];
	c4 <= raw_s ? c4+1 : 0;
	if (&c4) pre_body <= 1;
	if (&c4 & pre_body) body <= 1;
	if (~raw_s) begin  // reset between packets
		pre_body <= 0;
		body <= 0;
	end
	if (body & &c4) begin
		inc_address <= 0;
		if (set_repeat) begin
			repeat_count <= next_isr[8:0] - 1;
		end else if (~data_phase) begin
			data_phase <= 1;
			big_r[63:32] <= next_isr;
		end else if (|repeat_count) begin
			big_r[31:0] <= next_isr;
			repeat_count <= repeat_count - 1;
			inc_address <= 1;
		end else begin
			big_r[31:0] <= next_isr;
			data_phase <= 0;
		end
		if (inc_address) big_r[63:32] <= big_r[63:32] + 1;
	end
	do_op <= next_do_op;
end
assign addr = big_r[23+32:32];
assign data_out = big_r[31:0];
assign control_rd = big_r[28+32];
assign control_strobe = do_op;
assign control_write = control_strobe & ~control_rd;

// Keep track of the read pipeline
reg [read_pipe_len-1:0] read_pipe_markers=0;
wire read_op = control_strobe & control_rd;
always @(posedge clk) read_pipe_markers <= {read_pipe_markers[read_pipe_len-2:0], read_op};
assign control_pipe_rd = {read_pipe_markers, read_op};
wire capture = control_pipe_rd[read_pipe_len];
assign control_rd_valid = capture;

// capture result
reg [31:0] osr=0;
always @(posedge clk) begin
	osr <= {osr[23:0], pdata};
	if (capture) osr <= data_in;
end
wire [7:0] xdata = osr[31:24];  // Data to be transmitted

// Final alignment of the Tx data with that of all the other clients
reg_delay #(.len(n_lat-read_pipe_len-5), .dw(8)) finale(.clk(clk),
	.gate(1'b1), .reset(1'b0),
	.din(xdata), .dout(odata));

endmodule
