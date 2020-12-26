// Short (2-32 long) FIFO meant to be efficiently implemented with
// Xilinx SRL16E or similar
// Except for the unified clock and the count output port,
// this is pin-compatible with ordinary fifo.v
// max. elements: 2**aw

`timescale 1ns / 1ns
`default_nettype none

module shortfifo #(
	parameter dw=2,
	parameter aw=2
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
	output last,
	output [aw:0] count  // -1: empty, 0: single element, 2**aw - 1: full
);

// Need 1 extra bit to distinguish between full and empty
reg [aw:0] raddr = ~0;

genvar ix;
generate for (ix=0; ix<dw; ix=ix+1) begin: bit_slice
	abstract_dsr #(.aw(aw)) srl(.clk(clk), .ce(we_), .addr(raddr),
		.din(din[ix]), .dout(dout[ix]) );
end endgenerate

localparam len = 1 << aw;

wire re_ = re && !empty;
wire we_ = we && (!full || re_);

always @(posedge clk) raddr <= raddr + we_ - re_;
assign full = raddr == (len - 1);
assign empty = &raddr;
assign last = ~(|raddr);
assign count = raddr;

// ---------------------------

`ifdef FORMAL
// Formal properties based on:
// https://zipcpu.com/tutorial/lsn-10-fifo.pdf

reg f_past_valid = 0;

// 2 magic addresses we will follow up
(* anyconst *) reg [aw:0] f_first_addr;
wire [aw:0] f_second_addr = f_first_addr + 1;

// with 2 corresponding magic values
(* anyconst *) reg [dw - 1: 0] f_first_data, f_second_data;

// circular addr. ptrs. are used to track the queue position of the 2 values
reg [1:0] f_state = 0;
reg [aw:0] f_wr_addr = 0;
reg [aw:0] f_r_addr = 0;

// How many elements are in the FIFO right now
wire [aw:0] f_fill = f_wr_addr - f_r_addr;

// If these are < f_fill, the addresses are valid (= standing in queue)
wire f_first_valid = (f_first_addr - f_r_addr) < f_fill;
wire f_second_valid = (f_second_addr - f_r_addr) < f_fill;

always @(posedge clk) begin
	f_past_valid <= 1;

	if (we_)
		f_wr_addr <= f_wr_addr + 1;

	if (re_)
		f_r_addr <= f_r_addr + 1;

	// FIFO sequence
	// Follow up the FIFO state transistions as 2 values enter and leave it
	// Need to do it for 2 values to verify the correct order
	case (f_state)
		0: begin  // IDLE state
			// write first magic value into FIFO
			if (we_ && (f_wr_addr == f_first_addr) && (din == f_first_data))
				f_state <= 1;
		end

		1: begin  // 1 value is in
			if (re_ && (f_r_addr == f_first_addr))
				f_state <= 0;  // first value was read prematurely, restart
			else if(we_)
				if (din == f_second_data)
					f_state <= 2;  // write second value
				else
					f_state <= 0;  // wrote wrong second value, restart

			// f_first_addr must be in the valid range of the FIFO
			assert(f_first_valid);
			assert(f_wr_addr == f_second_addr);
		end

		2: begin  // 2 values are in, read out first value
			if (re_ && (f_r_addr == f_first_addr))
				f_state <= 3;

			assert(f_first_valid);
			assert(f_second_valid);

			// TODO how to force data into memory when running the proof?
			// sby just assumes a wrong memory initial value and fails on dout
			if (f_r_addr == f_first_addr)
				assert(dout == f_first_data);
		end

		3: begin  // read out second value
			if (re_)
				f_state <= 0;

			assert(f_second_valid);
			assert(dout == f_second_data);
		end
	endcase

	// Cannot go from full to empty and vice versa
	if (f_past_valid && $past(full))
		assert(!empty);
	if (f_past_valid && $past(empty))
		assert(!full);

	// Show 2 values entering and exiting the FIFO:
	// cover(f_past_valid && $past(f_state) == 3 && f_state == 0);
end

// Fill up the fIFO and empty it again
reg f_was_full = 0;
always @(posedge clk) begin
	if (full)
		f_was_full = 1;
	cover(f_was_full && empty);
end

always @(*) begin
	assert(empty == (f_fill == 0));
	assert(last == (f_fill == 1));
	assert(full == (f_fill == len));

	// Can't have more items than the memory holds
	assert(f_fill <= len);

	// Can't be full and empty at the same time
	assert(!(full && empty));
end
`endif
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
