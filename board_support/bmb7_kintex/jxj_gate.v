`timescale 1ns / 1ns

// Uber-simple mapping of a UDP packet to a register read/write port.
// Uses standard network byte order (big endian).
// Supposedly compatible with mem_gateway.v
// NOTE: This code is not compatible with block-transfer mode described in mem_gate.md
module jxj_gate #(
	parameter dbg="true",
	parameter pipe_del=3,
	parameter slow_rx=1 // Enables legacy mode for slow S6-K7 link;
			    // In this mode, tx start is delayed so stream is not interrupted
) (
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

(* mark_debug = dbg *) reg [2:0] cnt8=0;  // cycling through 64 bits of nonce or ctl/address/data
(* mark_debug = dbg *) reg s1=0;
(* mark_debug = dbg *) reg rx_active=0;

reg nonce_done=0;  // set once we're past the nonce
reg [63:0] rx_sr=0;
reg rx_do=0;
reg lb_strobe_r=0;
assign lb_strobe = lb_strobe_r;
(* mark_debug = dbg *) reg xfer_strobe=0;
reg xfer_read_mode=0;

reg ctl_add_strobe=0, ctl_add_mode=0;

always @(posedge clk) begin
	if (rx_stb) begin
		cnt8 <= cnt8+1;
		if (&cnt8) s1 <= 1;
		nonce_done <= s1;
		rx_sr <= {rx_sr[55:0],rx_din};
		rx_active <= 1;
	end
	if (rx_end) begin
		cnt8 <= 0;
		s1 <= 0;
		rx_active <= 0;
	end
	lb_strobe_r <= rx_stb & (&cnt8) & s1;

	ctl_add_strobe <= rx_stb & nonce_done & (cnt8=='h3);
	if (ctl_add_strobe) ctl_add_mode <= 1;
	if (xfer_strobe) ctl_add_mode <= 0;

	xfer_strobe <= rx_stb & (&cnt8) & ctl_add_mode;
	if (xfer_strobe) xfer_read_mode <= nonce_done & rx_sr[32+28];
end

// Keep track of outstanding transactions to easily identify last tx
reg [5:0] tx_pending=0;
always @(posedge clk) begin
   if (ctl_add_strobe && !(tx_done&fifo_re))
      tx_pending <= tx_pending + 1;
   else if (!ctl_add_strobe && (tx_done&fifo_re))
      tx_pending <= tx_pending - 1;
end

// These become valid the cycle after rx_stb; ensure they do not change until next
// lb_strobe as downstream code can break if they do
wire lb_rd_l = rx_sr[32+28];
reg  lb_rd_r=0;
wire [23:0] lb_addr_l = rx_sr[23+32:32];
reg  [23:0] lb_addr_r=0;
wire [31:0] lb_dout_l= rx_sr[31:0];
reg  [31:0] lb_dout_r=0;

always @(posedge clk) begin
   if (lb_strobe_r) begin
      lb_rd_r <= lb_rd_l;
      lb_addr_r <= lb_addr_l;
      lb_dout_r <= lb_dout_l;
   end
end

assign lb_rd   = (lb_strobe_r) ? lb_rd_l :  lb_rd_r;
assign lb_addr = (lb_strobe_r) ? lb_addr_l : lb_addr_r;
assign lb_dout = (lb_strobe_r) ? lb_dout_l : lb_dout_r;

reg [pipe_del+7:0] xfer_pipe=0;
wire [7:0] tx_pipe=xfer_pipe[7:0];
reg [63:0] tx_sr;
(* mark_debug = dbg *) reg drive_fifo_tx=0;
reg drive_fifo_done=0;
wire tx_sr_load = tx_pipe[7];
always @(posedge clk) begin
	xfer_pipe <= {xfer_strobe , xfer_pipe[pipe_del+7:1]};
	drive_fifo_tx <= |tx_pipe;
	drive_fifo_done = tx_pipe[0]; // Mark last byte
	if (|tx_pipe) tx_sr <= tx_sr_load ? {ctl_add_dout, lb_din} : {tx_sr[55:0], 8'b0};
end

// Store cmd+addr in FIFO to cope with varying pipe_del
wire ctl_add_full;
wire [31:0] ctl_add_din = rx_sr[63:32];
wire [31:0] ctl_add_dout;

shortfifo #(.dw(32), .aw(2)) i_ctl_add_fifo (
	.clk(clk),
	.din(ctl_add_din), .we(xfer_strobe),
	.dout(ctl_add_dout), .re(tx_sr_load), .full(ctl_add_full));

// First 8 bytes are simply looped back (nonce + cmd)
wire rx_loopback = ~s1 & rx_stb;

wire [7:0] drive_fifo_data = rx_loopback ? rx_din : tx_sr[63:56];
wire drive_fifo = drive_fifo_tx | rx_loopback;

// One more FIFO.  Could be considered bufferbloat.
(* mark_debug = dbg *) wire empty;
wire tx_done;
wire fifo_re = tx_rdy_l&tx_stb;

shortfifo #(.dw(9), .aw(5)) fifo (
	.clk(clk),
	.din({drive_fifo_data, drive_fifo_done}), .we(drive_fifo),
	.dout({tx_dout, tx_done}), .re(fifo_re), .empty(empty));

assign tx_rdy_l = slow_rx ? ~empty&nonce_done : ~empty;
assign tx_rdy = tx_rdy_l;
assign tx_end = tx_done && tx_pending==1 && ~rx_active;

endmodule
