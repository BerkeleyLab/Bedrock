`timescale 1ns / 1ns

// Timing generator
// Interposes in and passes-through a local register write bus
// One-cycle delay from input bus to output bus
// Controlling bus has priority for access to the controlled bus.
// Output "collision" when a function generator write gets lost.
// That's a single-cycle output, which needs to be latched and/or
// counted by whoever instantiates this module.

// The dual-port ram holding the program is part of the local bus
// address space, defined by an external address decoder that supplies
// the dests_write port signal.  The size of that memory is defined
// by the pcw parameter.

// After filling the table, toggle bank_next to make it take effect.
// In theory, you should then wait for that new bank_next value to
// propagate to bank_stat before writing anything else to the table.
// That's only of real concern if trig inputs are rare.

// Features:
// Each set of four addresses means:
//    time delay
//    address to write
//    lower half-word of data
//    upper half-word of data
// time delay is in units of (clock cycles * 2^tgen_gran), applied _after_ the
// register write.
// Each operation takes four cycles by itself; the delay cycle count adds to
// this pedestal.
// An address of zero ends the program and resets the state to pc=0,
// which restarts when an external trig is supplied.

// runs at 150 MHz in Spartan-6 using 93 slice LUTs and one BRAM.

// Larry Doolittle, LBNL, 2014

module tgen #(
	parameter aw = 17,
	parameter tgen_gran = 0   // tick extension
) (
	input clk,  // timespec 6.66 ns
	input trig,
	output collision,
	// Controlling bus
	input [31:0] lb_data,
	input lb_write,
	input [aw-1:0] lb_addr,
	input dests_write,
	input [aw-17:0] addr_padding,
	(* external *)
	input bank_next,  // external
	// optional monitoring
	output [3:0] status,
	// These two are not actually used, but they trigger magic from newad
	(* external *)
	input [31:0] delay_pc_XXX, // external
	(* external *)
	output [13:0] delay_pc_XXX_addr, // external
	// Controlled bus
	output [31:0] lbo_data,
	output lbo_write,
	output [aw-1:0] lbo_addr
);

localparam pcw=14;  // Set delay_pc_XXX_addr width above to pcw
assign delay_pc_XXX_addr = 0;
// Counters
reg [pcw-1:0] pc=0;
wire [1:0] subcycle = pc[1:0];
reg [15+tgen_gran:0] timer=0;
wire [15:0] new_timer;  // comes from RAM
reg mem_zero=0;  // comes from RAM
wire zero_addr = (subcycle==3) & mem_zero;
wire trig1 = trig & pc==0;
reg trig1d=0;
reg did_work=0;
wire increment = (pc==0) ? trig1d : (subcycle!=0) | (timer==0);
always @(posedge clk) begin
	trig1d <= trig1;
	pc <= pc + increment;
	if (zero_addr) pc <= 0;
	timer <= (subcycle==1) ? (new_timer<<tgen_gran) : timer-(subcycle==0);
	if (trig1) did_work <= 0;
	if (pc[2]) did_work <= 1;
end

// Atomic flip between banks
// OK for bank_next to be in some other clock domain
reg bank=0, bank_prev=0, work_prev=0;
always @(posedge clk) if (trig1) begin
	bank <= bank_next;
	bank_prev <= bank;
	work_prev <= did_work;
end

// DPRAM
wire [15:0] mem_out;
wire [pcw:0] addra = { bank, lb_addr[pcw-1:0]};
wire [pcw:0] addrb = {~bank, pc};
dpram #(.dw(16), .aw(pcw+1)) dests(.clka(clk), .clkb(clk),
	.addra(addra), .dina(lb_data[15:0]), .wena(dests_write),
	.addrb(addrb), .doutb(mem_out));

// Data path for DPRAM read results
reg [15:0] mem_out1=0, mem_out2=0;
always @(posedge clk) begin
	mem_out1 <= mem_out;
	mem_out2 <= mem_out1;
	mem_zero <= mem_out==0;
end
assign new_timer=mem_out;
wire [31:0] our_data = write_cycle ? {mem_out1,mem_out} : 32'd0;
wire [15:0] our_addr = write_cycle ? mem_out2 : 16'd0;

reg write_cycle=0;
always @(posedge clk) write_cycle <= subcycle==3 & ~mem_zero;

// Now merge the two streams
reg [31:0] lbo_data_r=0;
reg [aw-1:0] lbo_addr_r=0;
reg lbo_write_r=0, collision_r=0;
wire write_thru = lb_write & ~dests_write;
always @(posedge clk) begin
	lbo_data_r <= write_thru ? lb_data : our_data;
	lbo_addr_r <= write_thru ? lb_addr : {addr_padding, our_addr};
	lbo_write_r <= write_thru | write_cycle;
	collision_r <= write_thru & write_cycle;
end

// Output ports
assign lbo_addr = lbo_addr_r;
assign lbo_data = lbo_data_r;
assign lbo_write = lbo_write_r;
assign collision = collision_r;
assign status = {work_prev, bank_prev, bank, bank_next};

endmodule
