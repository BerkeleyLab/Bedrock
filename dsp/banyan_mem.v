// Single-buffered capture of raw ADC data
// Hard-code number of ADCs at 8, at least for now

module banyan_mem #(
	parameter aw=10,
	parameter dw=16
) (
	input clk,  // timespec 6.1 ns
	input [8*dw-1:0] adc_data,
	input [7:0] banyan_mask,  // must be valid in clk domain

	// API in clk domain for controlling acquisition
	// See additional comments below
	input reset,  // resets pointer and full
	input run,  // set to enable writes to memory
	output [aw+3-1:0] pointer,  // write location
	output rollover,
	output full,
	// Note that writes are pipelined, and after clearing the run
	// bit, about four more clk cycles are required before the last
	// data actually shows up in RAM and can be read out.
	// The output status (full, pointer) are all immediately but
	// provisionally valid, pending completion of the pipelined writes.

	// Peek into the data stream between switch and memory.
	// Valid in clk domain.
	output [8*dw-1:0] permuted_data,

	// readout port, separate clock domain
	// recommend only using this when run is low
	input ro_clk,
	input [aw+3-1:0] ro_addr,
	output [dw-1:0] ro_data,
	output [dw-1:0] ro_data2
	// ro_data2 is based on ro_addr xored with 1<<aw
	// You don't have to use it, but if you have a 32 bit bus, 16-bit ADCs,
	// and are trying to pack things efficiently, it's yours for the taking.
);

// We expect banyan_mask to be set by software, and is therefore not
// time-critical.  Other uses should be aware of this extra cycle of latency,
// motivated by the "long" time needed to count the number of bits set.
reg [7:0] mask_d=0;
reg [3:0] bit_cnt=0;
always @(posedge clk) begin
	mask_d <= banyan_mask;  // time-aligned with bit_cnt and therefore done_mask
	bit_cnt <= banyan_mask[0] + banyan_mask[1] + banyan_mask[2] + banyan_mask[3]
	         + banyan_mask[4] + banyan_mask[5] + banyan_mask[6] + banyan_mask[7];
end

//  8 bits set: count to 2^(aw)
//  4 bits set: count to 2^(aw+1)
//  2 bits set: count to 2^(aw+2)
//  1 bit  set: count to 2^(aw+3)
reg [2:0] done_mask;
always @(*) begin
	done_mask = 0;
	if (bit_cnt[1]) done_mask = 4;
	if (bit_cnt[2]) done_mask = 6;
	if (bit_cnt[3]) done_mask = 7;
end

// Simple control logic, put the user in control.  Should support
// options like one-shot fill, or circular roll until fault.
// Expect logic like
//    if (trig | rollover) run <= trig;
//    assign reset = trig;
// for a one-shot, or
//    if (reset | fault) run <= reset;
// for fault capture.
// No hidden state!
// No double-buffering/circular readout, sorry; this is meant for
// wideband snapshotting, where the software can't possibly keep up.
reg full_r=0;
reg [aw+2:0] addr_count=0;
assign rollover = run & &(addr_count|{done_mask,{aw{1'b0}}});
always @(posedge clk) begin
	if (run) addr_count <= addr_count+1;
	if (rollover | reset) addr_count <= 0;
	if (rollover | reset) full_r <= rollover;
end
assign full = full_r;
assign pointer = addr_count;

// Split and time-align write-side addresses
wire [2:0] time_state = addr_count[aw+2:aw];
wire [aw-1:0] wr_addr;
reg_delay #(.dw(aw), .len(4)) addr_pipe(.clk(clk), .reset(1'b0), .gate(1'b1),
	.din(addr_count[aw-1:0]), .dout(wr_addr));
wire run_d;
reg_delay #(.dw(1), .len(3)) run_pipe(.clk(clk), .reset(1'b0), .gate(1'b1),
	.din(run), .dout(run_d));

// Banyan switch itself
wire [7:0] mask_out;
wire [dw*8-1:0] banyan_out;
banyan #(.dw(dw), .np(8), .rl(3)) banyan(.clk(clk),
	.time_state(time_state), .mask_in(mask_d), .data_in(adc_data),
	.mask_out(mask_out), .data_out(banyan_out));
assign permuted_data = banyan_out;

// A new value propagates to mask_out 3 cycles after time_state changes,
// compared to 4 for the data in banyan_out
reg [7:0] mask_out_d=0;
always @(posedge clk) mask_out_d <= mask_out & {8{run_d}};

// Bank of 8 RAM, pretty simple
wire [8*dw-1:0] ram_out;
genvar ix;
generate for (ix=0; ix<8; ix=ix+1) begin: ram_bank
	dpram #(.dw(dw), .aw(aw)) ram(.clka(clk), .clkb(ro_clk),
		.dina( banyan_out[(ix+1)*dw-1 -: dw]), .addra(wr_addr), .wena(mask_out_d[ix]),
		.doutb(   ram_out[(ix+1)*dw-1 -: dw]), .addrb(ro_addr[aw-1:0])
	);
end endgenerate

// Second stage of readout decoding is one cycle delayed from the RAM addressing
reg [2:0] stage2_addr=0;
always @(posedge ro_clk) stage2_addr <= ro_addr[aw+3-1:aw];
assign ro_data  = ram_out[((stage2_addr       )+1)*dw-1 -: dw];
assign ro_data2 = ram_out[((stage2_addr ^ 3'b1)+1)*dw-1 -: dw];
// So ro_data* are one cycle (plus some combinatorial time) delayed from the address provided
// Reads are purely passive, no side effects, hence no read-enable control is provided

endmodule
