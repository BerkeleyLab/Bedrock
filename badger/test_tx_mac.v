module test_tx_mac #(
	parameter mac_aw=10,  // 16-bit words
	parameter big_endian=0
) (
	input clk,
	input ce,
	// There is an implied DPRAM _not_ included in this module.
	// These ports access its read port, with assumed 1-cycle latency
	// The packet length is stored as the first word of a buffer.
	// Endian-ness is configurable.
	output [mac_aw-1:0] host_addr,
	input [15:0] host_d,
	// Request from host to transmit a packet, already converted to
	// (or at least usable in) our clk domain.
	// OK to just latch buf_start_addr on one host clock cycle,
	// and raise the start signal on the next.
	// Also OK to construct buf_start_addr with a handful of
	// static 0 at the lsb (representing granularity of buffer starts),
	// could save a few registers in that clock domain crossing.
	input start,
	input [mac_aw-1:0] buf_start_addr,
	output done,  // 4-phase handshake with start signal
	// Connection to precog module
	output req,
	output [10:0] len_req,  // can represent 1 MTU, in octets
	// Connection to output multiplexer (xformer.v)
	input strobe,
	output [7:0] mac_data
);

reg [mac_aw-1:0] buffer_point;  // in words
reg [2:0] mode=0;
reg [10:0] len_req_r=0;
reg req_r=0, done_r=0;
reg odd_octet=0;
wire even_octet = ~odd_octet;
// There's a total of two cycles latency from setting buffer_point
// to being able to use the result of reading that DPRAM entry.
always @(posedge clk) begin
	if (ce) begin
		case (mode)
		0: if (start) begin
			mode <= 1;
			buffer_point <= buf_start_addr;
		end
		1: begin
			mode <= 2;
			buffer_point <= buffer_point + 1;
		end
		2: begin
			mode <= 3;
			len_req_r <= host_d;
			odd_octet <= 0;
			req_r <= 1;
		end
		3: if (strobe) begin
			odd_octet <= ~odd_octet;
			buffer_point <= buffer_point + even_octet;
			len_req_r <= len_req_r-1;
			if (len_req_r == 1) begin
				mode <= 4;
				done_r <= 1;
				req_r <= 0;
			end
		end
		4: begin
			if (~start) begin
				mode <= 0;
				done_r <= 0;
			end
		end
		endcase
	end
end

assign host_addr = buffer_point;
assign len_req = len_req_r;
assign mac_data = (odd_octet^big_endian) ? host_d[15:8] : host_d[7:0];
assign done = done_r;
assign req = req_r;

endmodule
