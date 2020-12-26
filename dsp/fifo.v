// blockram based FIFO
// exchangeable with shortfifo.v
// TODO make reads registered and get rid of the `rw_addr_collision` attribute

module fifo #(
	parameter aw = 3,
	parameter dw = 8
) (
	input clk,

	input [dw - 1: 0] din,
	input we,

	output [dw - 1: 0] dout,
	input re,

	output full,
	output empty,
	output last,

	// -1: empty, 0: single element, 2**aw - 1: full
	output [aw:0] count
);

localparam MEM_LEN = 1 << aw;

(* rw_addr_collision = "yes" *)
reg [dw - 1: 0] mem[MEM_LEN - 1: 0];

// read / write pointers (need an extra bit too!)
reg [aw: 0] wr_addr = 0;
reg [aw: 0] rd_addr = 0;

// Number of items in memory (up to MEM_LEN items)
// Need 1 extra bit, else wouldn't be able to count MEM_LEN items
wire [aw: 0] fill = wr_addr - rd_addr;
assign count = fill - 1;

// can only read when not empty
wire re_ = re && !empty;

// can only write when not full (except when also reading)
wire we_ = we && (!full || re);

assign dout = mem[rd_addr];
assign empty = fill == 0;
assign last = fill == 1;
assign full = fill >= MEM_LEN;

always @(posedge clk) begin
	if (we_) begin
		mem[wr_addr] <= din;
		wr_addr <= wr_addr + 1;
	end

	if (re_) begin
		rd_addr <= rd_addr + 1;
	end
end

// ---------------------------

`ifdef FORMAL
// FIFO verification exercise from:
// https://zipcpu.com/tutorial/lsn-10-fifo.pdf

reg f_past_valid = 0;

// 2 magic addresses we will follow up
(* anyconst *) reg [aw: 0] f_first_addr;
wire [aw:0] f_second_addr = f_first_addr + 1;

// adress pointers are circular. read_pointer is index0 of FIFO
// If these are < fill the addresses are valid
wire [aw: 0] f_first_dist = f_first_addr - rd_addr;
wire [aw: 0] f_second_dist = f_second_addr - rd_addr;
wire f_first_valid = !empty && (f_first_dist < fill);
wire f_second_valid = !empty && (f_second_dist < fill);

// with 2 corresponding magic values
(* anyconst *) reg [dw - 1: 0] f_first_data, f_second_data;

reg [1:0] f_state = 0;

always @(posedge clk) begin
	f_past_valid <= 1;

	// FIFO sequence
	// Follow up the FIFO state transistions as 2 values enter and leave it
	// Need to do it for 2 values to verify the correct order
	case (f_state)
		0: begin  // IDLE state
			// write first magic value into FIFO
			if (we_ && !re_ && (wr_addr == f_first_addr) && (din == f_first_data))
				f_state <= 1;
		end

		1: begin  // 1 value is in
			if (re_ && (rd_addr == f_first_addr))
				f_state <= 0;  // first value was read prematurely, restart
			else if(we_)
				if (din == f_second_data)
					f_state <= 2;  // write second value
				else
					f_state <= 0;  // wrote wrong second value, restart

			// f_first_addr must be in the valid range of the FIFO
			assert(f_first_valid);
			assert(mem[f_first_addr] == f_first_data);
			assert(wr_addr == f_second_addr);
		end

		2: begin  // 2 values are in, read out first value
			if (re_ && (rd_addr == f_first_addr))
				f_state <= 3;

			assert(f_first_valid);
			assert(f_second_valid);
			assert(mem[f_first_addr] == f_first_data);
			assert(mem[f_second_addr] == f_second_data);

			if (rd_addr == f_first_addr)
				assert(dout == f_first_data);
		end

		3: begin  // read out second value
			if (re_)
				f_state <= 0;

			assert(f_second_valid);
			assert(mem[f_second_addr] == f_second_data);

			assert(dout == f_second_data);
		end
	endcase

	// Cannot go from full to empty and vice versa
	if (f_past_valid && $past(full))
		assert(!empty);
	if (f_past_valid && $past(empty))
		assert(!full);

	// Read and write can happen at the same time!
	if (f_past_valid && $past(we) && $past(re) && !$past(empty))
		assert($stable(fill));

	// cover mode: show 2 values entering and exiting the FIFO:
	// cover(f_past_valid && $past(f_state) == 3 && f_state == 0);
end

// cover mode: Fill up the fIFO and empty it again
reg f_was_full = 0;
reg f_both = 0; // show what happens when both are high
always @(posedge clk) begin
	if (full)
		f_was_full <= 1;
	if (we && re && !empty)
		f_both <= 1;
	cover(empty && f_was_full && f_both);
end


always @(*) begin
	assert(fill == wr_addr - rd_addr);
	assert(empty == (fill == 0));
	assert(last == (fill == 1));
	assert(full == (fill == MEM_LEN));

	// Can't have more items than the memory holds
	assert(fill <= MEM_LEN);

	// Cant be full and empty at the same time
	assert(!(full && empty));
end
`endif

endmodule
