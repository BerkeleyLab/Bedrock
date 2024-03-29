`timescale 1ns / 1ns
module flag_xdomain(
	input clk1,
	input flagin_clk1,
	input clk2,
	output flagout_clk2
);

reg flagtoggle_clk1=0;
(* ASYNC_REG="TRUE", RLOC="X0Y0" *)
(* SHREG_EXTRACT="NO", DONT_TOUCH="TRUE" *)
(* ALTERA_ATTRIBUTE="-name AUTO_SHIFT_REGISTER_RECOGNITION OFF" *)
reg [2:0] sync1_clk2=0;
always @(posedge clk1) if (flagin_clk1)
	flagtoggle_clk1 <= ~flagtoggle_clk1;
always @(posedge clk2) sync1_clk2 <= {sync1_clk2[1:0],flagtoggle_clk1};

assign flagout_clk2 = sync1_clk2[2]^sync1_clk2[1];
endmodule
