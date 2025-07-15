`timescale 1ns / 1ns
module flag_xdomain(
	input clk1,
	input flagin_clk1,
	input clk2,
	output flagout_clk2
);

// Step 1: generate 1-bit Gray code
reg flagtoggle_clk1=0;
always @(posedge clk1) if (flagin_clk1)
	flagtoggle_clk1 <= ~flagtoggle_clk1;

// Step 2: cross clock domains
wire sync1_clk2;
reg_tech_cdc flagtoggle_cdc(.I(flagtoggle_clk1), .C(clk2), .O(sync1_clk2));

// Step 3: detect transitions
reg sync2_clk2=0;
always @(posedge clk2) sync2_clk2 <= sync1_clk2;
assign flagout_clk2 = sync2_clk2 ^ sync1_clk2;

// Step 4: (simulation-only) complain if this module is abused
// Too many people wire data_xdomain's .gate_in(1'b1) without understanding
// how the logic is supposed to work.
`ifdef SIMULATE
reg old_flagin=0, warning_sent=0;
always @(posedge clk1) begin
	old_flagin <= flagin_clk1;
	if (flagin_clk1 & old_flagin & ~warning_sent) begin
		// Don't actually crash, at least not for now.
		$display("XXXX  Warning: flag_xdomain module abuse in %m  XXXX");
		warning_sent <= 1;
	end
end
`endif

endmodule
