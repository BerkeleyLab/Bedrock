// This is mostly just an engine that takes 32K lb_clk cycles to
// sweep through 16 lanes and 32 idelay values, and record 4 x 8-bit
// (half) ADC samples per combination, 2048 readings total.  Those
// readings are called "results" and are saved in a 2048x8 RAM that
// the host can read.

// The scan_trigger input port starts scans.  When a scan is not in progress,
// the host is given the ability to write normally to the idelay hardware.
// This module also contains an (unproven, can be disabled) data analysis
// step, so that after a run, an optimal set of idelay values are chosen
// and driven to the IDELAYE2 hardware.

// The "mirror" memory of idelay values has a sixth and seventh bit appended
// on the left (msb side) to show the source of that last value written to
// hardware.  00 means it came from the scanner, 01 from the software, and
// 10 is a (claimed) successful auto-set.  That's plenty of easy-to-interpret
// status for host usage.  XXX I'd like to add a single-bit status output
// for hardware usage, e.g., for deciding to move on to a BUFR resync or
// bitslip step.

// There are two local bus addresses and clocks: lb_clk and lb_addr for
// writes, ro_clk and ro_addr for reads.  Local bus address decoding must
// be handled externally.  lb_addr selects the lane of idelay value to write.
// All 11 bits of ro_addr are used as the read address for result RAM.  The
// low-order 4 bits of ro_addr are used as the read address of mirror RAM.
// The instantiating module is free to attach lb_clk and ro_clk to the same
// signal.

// This module is statically set up for 16 lanes of dual-lane 16-bit
// ADC data, matching the LCLS-II LLRF Digitizer hardware.  It would
// be easy to parameterize the sizing if anyone cared.

// External logic needs to route deserialized data from one of eight ADCs
// to the adc_val input, according to the adc_num output.  A banyan_mask
// output is also provided for convenience in the lcls2_llrf context, which
// is derived from the adc_num output.  This module handles the selection of
// eight of those 16 adc data bits that correspond to a lane from the AD9653.

// Resource consumption of this module by itself is miniscule: one RAMB18
// and approximately 80 LUT.  More important are external components like
// the ADC data path multiplexer and the whole IBUFDS/IDELAY/ISERDES setup.
// If you want to trim this resource utilization, don't connect to result_val,
// that will drop the RAMB18.  Or, you can set parameter use_decider to 0,
// that will remove the autoset feature and cut LUT usage down to about 40.
// Doing both of those things would render this module useless.

module idelay_scanner(
	input lb_clk,
	// From the host
	input [3:0] lb_addr,
	input [4:0] lb_data,
	input lb_id_write,  // derived from host's lb_write, along with
		// address decoding for the 16 lanes worth of idelay values
	input scan_trigger,
	input autoset_enable,
	output scan_running,
	// Readback to the host
	input ro_clk,
	input [10:0] ro_addr,
	output [6:0] mirror_val,
	output [7:0] result_val,
	// Temporary
	input debug_sel,
	input [3:0] debug_addr,
	// Control of the IDELAYE2 hardware from this module
	// If the IDELAYE2's port C is not lb_clk, a clock domain crossing
	// should be implemented outside this module.  High performance is
	// not needed, since this module waits about 30 lb_clk cycles after
	// a hw_strobe before trying to capture any data.
	output [3:0] hw_addr,
	output [4:0] hw_data,
	output hw_strobe,
	// Control of external ADC data multiplexer
	// If using banyan_mask, someone else needs to multiplex it with
	// the setting from the host.
	output [2:0] adc_num,
	output [7:0] banyan_mask,
	// Input from the ADC, in its own clock domain
	// That clock is assumed to be pretty fast; the crude clock domain
	// crossing used here requires at least one adc_clk edge in
	// the time of four lb_clk periods.
	input adc_clk,
	input [15:0] adc_val
);

parameter use_decider=1;

// State counter
//   4 bit lane address
//   5 bit idelay value
//   6 bit microcycle
reg [14:0] counter=0;
reg run=0, autoset=0;
always @(posedge lb_clk) begin
	if (scan_trigger | &counter) run <= scan_trigger;
	if (scan_trigger & (counter==0)) autoset <= autoset_enable;
	if (run) counter <= counter + 1;
end
assign scan_running = run;
wire [3:0] state_lane   = counter[14:11];
wire [4:0] state_idelay = counter[10:6];
wire [5:0] state_micro  = counter[5:0];

// Decode banyan_mask
assign adc_num = state_lane[3:1];  // also a module output
reg [7:0] mask_r=0;
genvar jx;
generate for (jx=0; jx<8; jx=jx+1) begin: decode
	always @(posedge lb_clk) mask_r[jx] <= adc_num == jx;
end endgenerate
assign banyan_mask = mask_r;

// Decode other (mostly) single-bit controls
reg [10:0] result_addr=0;
reg lane_grab=0, result_write=0, idelay_push=0;
always @(posedge lb_clk) begin
	lane_grab <= ~state_micro[2];
	result_write <= state_micro[5] & (state_micro[2:0] == 6);
	idelay_push <= state_micro == 1;
	// result_addr synchronized with result_write
	result_addr <= {state_lane, state_idelay, state_micro[4:3]};
end
wire lane_half = ~state_lane[0];

// Grab one lane of data from the ADC
// lane_grab crosses clock domains, and that's OK.
// lane_data guaranteed not to change near active (result_write) lb_clk edge.
reg [7:0] lane_data=0;
always @(posedge adc_clk) if (lane_grab) lane_data <=
	lane_half ? adc_val[15:8] : adc_val[7:0];

// Result memory: 4+5+2 address bits
dpram #(.aw(11), .dw(8)) result(.clka(lb_clk), .clkb(ro_clk),
	.addra(result_addr), .dina(lane_data), .wena(result_write),
	.addrb(ro_addr), .doutb(result_val)
);

// Figure out what the right delay value is
// Note that since I only want to count to 32, and reserve one time slot for
// writing the optimized delay value, scans with autoset engaged only cover
// idelay values from 0 to 30.  As a consequence, the result RAM at array
// index 31 will hold the final adc readout with the autoset idelay.
wire [4:0] idelay_opt;
wire good_enough;
generate if (use_decider) begin: decider_yes
decider decider(.clk(lb_clk),
	.addr(result_addr), .lane_data(lane_data), .strobe(result_write),
	.idelay_opt(idelay_opt), .good_enough(good_enough)
);
end else begin: decider_no
assign idelay_opt = 0;
assign good_enough = 0;
end endgenerate
wire use_opt = (state_idelay == 31) & autoset & good_enough;
wire [4:0] next_idelay = use_opt ? idelay_opt : state_idelay;

// Bus multiplexer
reg [3:0] hw_addr_r=0;
reg [4:0] hw_data_r=0;
reg       hw_strobe_r=0;
reg       run_d=0;
wire [3:0] use_lane = debug_sel ? debug_addr : state_lane;
always @(posedge lb_clk) begin
	hw_addr_r   <= run ? use_lane     : lb_addr;
	hw_data_r   <= run ? next_idelay  : lb_data;
	hw_strobe_r <= run ? idelay_push  : lb_id_write;
	run_d       <= run;
end

// Send multiplexed bus to IDELAYE2 primitives
assign hw_addr = hw_addr_r;
assign hw_data = hw_data_r;
assign hw_strobe = hw_strobe_r;

// Mirror memory for (slightly fake) readback
// It does respond to writes from both scanner and host
wire opt_valid = good_enough & autoset & run_d & (state_idelay==31);
wire [6:0] mirror_data = {opt_valid, ~run_d, hw_data_r};
dpram #(.aw(4), .dw(7)) mirror(.clka(lb_clk), .clkb(ro_clk),
	.addra(hw_addr_r), .dina(mirror_data), .wena(hw_strobe_r),
	.addrb(ro_addr[3:0]), .doutb(mirror_val)
);

endmodule
