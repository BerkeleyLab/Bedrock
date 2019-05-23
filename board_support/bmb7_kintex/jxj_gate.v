`timescale 1ns / 1ns

// Uber-simple mapping of a UDP packet to a register read/write port.
// Uses standard network byte order (big endian).
// Supposedly compatible with mem_gateway.v
module jxj_gate #(parameter dbg="true", parameter pipe_del=3) (
	input clk,  // single-clock-domain design
	// AXI-lite-stream-ish port from remote host
	// (Spartan-6 communication decoder in case of BMB7)
	(* mark_debug = dbg *) input [7:0] rx_din,
	(* mark_debug = dbg *) input       rx_stb,
	(* mark_debug = dbg *) input       rx_end,
	// AXI-lite-stream-ish port to remote host
	// (Spartan-6 communication decoder in case of BMB7)
	(* mark_debug = dbg *) output [7:0] tx_dout,
	(* mark_debug = dbg *) output       tx_rdy,
	(* mark_debug = dbg *) output       tx_end,
	(* mark_debug = dbg *) input        tx_stb,
	// Local bus created here
	(* mark_debug = dbg *) output [23:0] lb_addr,
	(* mark_debug = dbg *) output [31:0] lb_dout,
	(* mark_debug = dbg *) input [31:0]  lb_din,
	(* mark_debug = dbg *) output        lb_strobe,
	(* mark_debug = dbg *) output        lb_rd
);

(* mark_debug = dbg *) reg [2:0] s0=0;  // cycling through 64 bits of nonce or ctl/address/data
(* mark_debug = dbg *) reg s1=0;
(* mark_debug = dbg *) reg rx_active=0;
reg s1_d=0;  // set once we're past the nonce
reg [63:0] rx_sr=0;
reg rx_do=0;
reg lb_strobe_r=0;
assign lb_strobe = lb_strobe_r;
(* mark_debug = dbg *) reg xfer_strobe=0;
reg xfer_read_mode=0;

always @(posedge clk) begin
	if (rx_stb) begin
		s0 <= s0+1;
		if (&s0) s1 <= 1;
		s1_d <= s1;
		rx_sr <= {rx_sr[55:0],rx_din};
		rx_active <= 1;
	end
	if (rx_end) begin
		s0 <= 0;
		s1 <= 0;
		rx_active <= 0;
	end
	lb_strobe_r <= rx_stb & (&s0) & s1;
	xfer_strobe <= rx_stb & (&s0);
	if (xfer_strobe) xfer_read_mode <= s1_d & rx_sr[32+28];
end
// These become valid the cycle after rx_stb
assign lb_rd   = rx_sr[32+28];
assign lb_addr = rx_sr[23+32:32];
assign lb_dout = rx_sr[31:0];

reg [pipe_del+7:0] xfer_pipe=0;
wire [7:0] tx_pipe=xfer_pipe[7:0];
reg [63:0] tx_sr;
wire [63:0] xfer_din = {rx_sr[63:32],(xfer_read_mode ? lb_din : rx_sr[31:0])};
(* mark_debug = dbg *) reg drive_fifo=0;
wire tx_sr_load = tx_pipe[7];
always @(posedge clk) begin
	xfer_pipe <= {xfer_strobe,xfer_pipe[pipe_del+7:1]};
	drive_fifo <= |tx_pipe;
	if (|tx_pipe) tx_sr <= tx_sr_load ? xfer_din : {tx_sr[55:0],8'b0};
end

// One more FIFO.  Could be considered bufferbloat.
(* mark_debug = dbg *) wire empty;
(* mark_debug = dbg *) wire last;
wire [7:0] drive_fifo_data = tx_sr[63:56];
shortfifo #(.dw(8), .aw(5)) fifo (.clk(clk),
	.din(drive_fifo_data), .we(drive_fifo),
	.dout(tx_dout), .re(tx_stb&~empty), .empty(empty), .last(last));
assign tx_rdy = ~empty;
// assign tx_end = empty;
assign tx_end = last & ~(rx_active | drive_fifo);

endmodule
