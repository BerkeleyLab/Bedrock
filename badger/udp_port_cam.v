// Content-addressable memory for UDP port numbers

// Checking for 8 x 16-bit UDP ports in parallel with synthesis-time
// configured port numbers would take roughly 49 LUT (32 for the comparisons,
// plus overhead).  Switching this to run-time configuration of port numbers
// ups that count to about 217 (192 just to hold the numbers and do the
// comparison, plus overhead).  That's almost half the size of the core
// rtefi_pipe without this feature.

// This version holds the port numbers in 16 x 8 RAM, and performs a
// walk-through of that memory in 16 cycles.  LUT count is about 32
// (for the case naw=3) including the distributed memory.

// The possible complication to this approach shows up with short packets.
// In a simple-minded tap simulation, a minimal length UDP packet
// (no data, 8 bytes long including the header) will require the answer
// approximately six cycles after the port number arrives, in order to
// get stored into MTU memory.  In real life, Ethernet packets have
// a minimum frame size of 64 bytes.  Thus the minimal UDP packet will
// necessarily be followed by 18 padding bytes (usually zero) before the
// CRC32.  That's plenty of time for this module to do its work.  Problems
// could only show up in such over-simplified simulations or if attached to
// standards-violating Ethernet hardware.  The simulation problem has been
// addressed by upgrading ethernet_model.c to add that padding.

// A true single-cycle CAM architecture (such as described in Xilinx
// XAPP1151) could give similar resource footprint, if carefully done,
// but with much less natural setup from the local bus.  A single
// port matcher would use two 32x1 RAMs, each taking 4 address bits from
// the data stream and 1 for high/low byte.

module udp_port_cam #(
	parameter naw=3  // address width for abstract port memory
) (
	input clk,  // timespec 6.8 ns
	input port_s,
	input [7:0] data,
	// port to config memory, single-cycle latency
	// 8-bit with naw+1 address bits, where an abstract
	// version would be 16-bit with naw address bits
	output [naw:0] pno_a,
	input [7:0] pno_d,
	// Results - a port pointer
	output [naw-1:0] port_p,
	output port_h,  // port_p is meaningful (hit)
	output port_v  // timing only: above two results are in
);

// Input setup
reg port_s_d=0;
reg [7:0] port_in1=0, port_in2=0;
reg [naw:0] port_cnt=0;
wire [naw:0] port_cnt_next = port_s ? 0 : port_cnt + 1;
wire port_load = port_s | port_s_d;
always @(posedge clk) begin
	port_s_d <= port_s;
	port_in1 <= port_load ? data : port_in2;
	port_in2 <= port_in1;
	port_cnt <= port_cnt_next;
end
assign pno_a = port_cnt_next;

// Central comparison
wire equal = port_in1 == pno_d;

// Find out when both upper and lower bytes match
reg eq_hold=0;
reg [naw-1:0] port_p_r=0;
reg port_v_r=0, port_h_r=0;
always @(posedge clk) begin
	eq_hold <= equal;
	if (equal & eq_hold & port_cnt[0] & ~port_v_r) begin
		port_h_r <= 1;
		port_p_r <= port_cnt[naw:1];
	end
	if (&port_cnt) port_v_r <= 1;
	if (port_s) begin
		port_h_r <= 0;
		port_v_r <= 0;
	end
end
assign port_p = port_p_r;
assign port_h = port_h_r;
assign port_v = port_v_r;

endmodule
