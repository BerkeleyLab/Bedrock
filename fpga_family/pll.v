//
// Xilinx PLL instantiation
//
module pll (rst,clkin,locked, clk0,clk1,clk2,clk3,clk4,clk5,drp_clk,drp_write,drp_go,drp_done,drp_addr,drp_data_in,drp_data_out);
parameter DEVICE="KINTEX 7";
//parameter DEVICE="SPARTAN 6";
parameter clkin_period=5.0;
parameter gmult=5;
parameter gphase=0.0;
parameter c0div=8;
parameter c0phase=0.0;
parameter c1div=1;
parameter c1phase=0.0;
parameter c2div=1;
parameter c2phase=0.0;
parameter c3div=1;
parameter c3phase=0.0;
parameter c4div=1;
parameter c4phase=0.0;
parameter c5div=1;
parameter c5phase=0.0;
input rst;
input clkin;
output locked;
output clk0;
output clk1;
output clk2;
output clk3;
output clk4;
output clk5;
input drp_clk;
input drp_write;
input drp_go;
output reg drp_done;
input [6:0] drp_addr;
input [15:0] drp_data_in;
output reg [15:0] drp_data_out;


reg int_drp_go=0, drp_enable=0;
wire drp_ready ;
wire [15:0] int_drp_data_out;

`ifndef SIMULATE

wire clkfb,clki0,clki1,clki2,clki3,clki4,clki5;

generate
if (DEVICE == "SPARTAN 6") begin
	PLL_BASE #(
		.BANDWIDTH ("OPTIMIZED"),   // "high", "low" or "optimized"
		.CLKFBOUT_MULT (gmult),  // multiplication factor for all output clocks
		.CLKFBOUT_PHASE (gphase),  // phase shift (degrees) of all output clocks
		.CLKIN_PERIOD (clkin_period),  // clock period (ns) of input clock on clkin_period
		.CLKOUT0_DIVIDE (c0div),  // division factor for clkout0 (1 to 128)
		.CLKOUT0_DUTY_CYCLE (0.5),    // duty cycle for clkout0 (0.01 to 0.99)
		.CLKOUT0_PHASE (c0phase),  // phase shift (degrees) for clkout0 (0.0 to 360.01)
		.CLKOUT1_DIVIDE (c1div),  // division factor for clkout1 (1 to 128)
		.CLKOUT1_DUTY_CYCLE (0.5),    // duty cycle for clkout1 (0.01 to 0.99)
		.CLKOUT1_PHASE (c1phase),  // phase shift (degrees) for clkout1 (0.0 to 360.01)
		.CLKOUT2_DIVIDE (c2div),  // division factor for clkout2 (1 to 128)
		.CLKOUT2_DUTY_CYCLE (0.5),    // duty cycle for clkout2 (0.01 to 0.99)
		.CLKOUT2_PHASE (c2phase),  // phase shift (degrees) for clkout2 (0.0 to 360.01)
		.CLKOUT3_DIVIDE (c3div),  // division factor for clkout3 (1 to 128)
		.CLKOUT3_DUTY_CYCLE (0.5),    // duty cycle for clkout3 (0.01 to 0.99)
		.CLKOUT3_PHASE (c3phase),  // phase shift (degrees) for clkout3 (0.0 to 360.01)
		.CLKOUT4_DIVIDE (c4div),  // division factor for clkout4 (1 to 128)
		.CLKOUT4_DUTY_CYCLE (0.5),    // duty cycle for clkout4 (0.01 to 0.99)
		.CLKOUT4_PHASE (c4phase),  // phase shift (degrees) for clkout4 (0.0 to 360.01)
		.CLKOUT5_DIVIDE (c5div),  // division factor for clkout5 (1 to 128)
		.CLKOUT5_DUTY_CYCLE (0.5),    // duty cycle for clkout5 (0.01 to 0.99)
		.CLKOUT5_PHASE (c5phase),  // phase shift (degrees) for clkout5 (0.0 to 360.01)
		.COMPENSATION ("SYSTEM_SYNCHRONOUS"),  // "system_synchrnous" // "source_synchrnous"), "internal"),// "external"), "dcm2pll"), "pll2dcm"
		.DIVCLK_DIVIDE (1),  // division factor for all clocks (1 to 52)
			.REF_JITTER (0.100)  // input reference jitter (0.000 to 0.999 ui%)
		)
		pll_base_inst(
			.CLKFBOUT (clkfb),              // general output feedback signal
			.CLKOUT0  (clki0),        // one of six general clock output signals
			.CLKOUT1  (clki1),        // one of six general clock output signals
			.CLKOUT2  (clki2),        // one of six general clock output signals
			.CLKOUT3  (clki3),        // one of six general clock output signals
			.CLKOUT4  (clki4),        // one of six general clock output signals
			.CLKOUT5  (clki5),        // one of six general clock output signals
			.LOCKED   (locked),             // active high pll lock signal
			.CLKFBIN  (clkfb),              // clock feedback input
			.CLKIN    (clkin),              // clock input
			.RST      (rst)
		);               // asynchronous pll reset
	end

	else if (DEVICE == "KINTEX 7") begin
		PLLE2_ADV #(
			.BANDWIDTH          ("OPTIMIZED"),   // "high"), "low" or "optimized"
			.CLKFBOUT_MULT      (gmult),  // multiplication factor for all output clocks
			.CLKFBOUT_PHASE     (gphase),  // phase shift (degrees) of all output clocks
			.CLKIN1_PERIOD      (clkin_period),  // clock period (ns) of input clock on clkin_period
			.CLKOUT0_DIVIDE     (c0div),  // division factor for clkout0 (1 to 128)
			.CLKOUT0_DUTY_CYCLE (0.5),    // duty cycle for clkout0 (0.01 to 0.99)
			.CLKOUT0_PHASE      (c0phase),  // phase shift (degrees) for clkout0 (0.0 to 360.01)
			.CLKOUT1_DIVIDE     (c1div),  // division factor for clkout1 (1 to 128)
			.CLKOUT1_DUTY_CYCLE (0.5),    // duty cycle for clkout1 (0.01 to 0.99)
			.CLKOUT1_PHASE      (c1phase),  // phase shift (degrees) for clkout1 (0.0 to 360.01)
			.CLKOUT2_DIVIDE     (c2div),  // division factor for clkout2 (1 to 128)
			.CLKOUT2_DUTY_CYCLE (0.5),    // duty cycle for clkout2 (0.01 to 0.99)
			.CLKOUT2_PHASE      (c2phase),  // phase shift (degrees) for clkout2 (0.0 to 360.01)
			.CLKOUT3_DIVIDE     (c3div),  // division factor for clkout3 (1 to 128)
			.CLKOUT3_DUTY_CYCLE (0.5),    // duty cycle for clkout3 (0.01 to 0.99)
			.CLKOUT3_PHASE      (c3phase),  // phase shift (degrees) for clkout3 (0.0 to 360.01)
			.CLKOUT4_DIVIDE     (c4div),  // division factor for clkout4 (1 to 128)
			.CLKOUT4_DUTY_CYCLE (0.5),    // duty cycle for clkout4 (0.01 to 0.99)
			.CLKOUT4_PHASE      (c4phase),  // phase shift (degrees) for clkout4 (0.0 to 360.01)
			.CLKOUT5_DIVIDE     (c5div),  // division factor for clkout5 (1 to 128)
			.CLKOUT5_DUTY_CYCLE (0.5),    // duty cycle for clkout5 (0.01 to 0.99)
			.CLKOUT5_PHASE      (c5phase),  // phase shift (degrees) for clkout5 (0.0 to 360.01)
			.COMPENSATION       ("ZHOLD"),  // "system_synchrnous"),// "source_synchrnous"), "internal"),// "external"), "dcm2pll"), "pll2dcm"
			.DIVCLK_DIVIDE      (1),  // division factor for all clocks (1 to 52)
			.REF_JITTER1        (0.100)
		)  // input reference jitter (0.000 to 0.999 ui%)
		pll_inst (
			.CLKINSEL (1'b1),                // clkin1
			.CLKFBOUT (clkfb),              // general output feedback signal
			.CLKOUT0  (clki0),        // one of six general clock output signals
			.CLKOUT1  (clki1),        // one of six general clock output signals
			.CLKOUT2  (clki2),        // one of six general clock output signals
			.CLKOUT3  (clki3),        // one of six general clock output signals
			.CLKOUT4  (clki4),        // one of six general clock output signals
			.CLKOUT5  (clki5),        // one of six general clock output signals
			.LOCKED   (locked),             // active high pll lock signal
			.CLKFBIN  (clkfb),              // clock feedback input
			.CLKIN1   (clkin),              // clock input
			.CLKIN2   (1'b0),                // unused
			.PWRDWN   (1'b0),
			.RST      (rst),                // asynchronous pll reset
			.DADDR    (drp_addr),
			.DCLK     (drp_clk),
			.DEN      (drp_enable),
			.DRDY     (drp_ready),
			.DI       (drp_data_in),
			.DO       (int_drp_data_out),
			.DWE      (drp_write)
		);
	end
	endgenerate
`else

reg clki0,clki1,clki2,clki3,clki4,clki5,locked_i;

	// Generate in-phase clocks according to parameters
	initial begin
		clki0 <= 1;
		clki1 <= 1;
		clki2 <= 1;
		clki3 <= 1;
		clki4 <= 1;
		clki5 <= 1;
		clki5 <= 1;
		locked_i <= 0;
		locked_i <= #(clkin_period+0.1) 1; // Lock right after edge
	end
	initial begin
	end
	always @(*) begin
		clki0 <= #((clkin_period*c0div/gmult)/2) ~clki0;
		clki1 <= #((clkin_period*c1div/gmult)/2) ~clki1;
		clki2 <= #((clkin_period*c2div/gmult)/2) ~clki2;
		clki3 <= #((clkin_period*c3div/gmult)/2) ~clki3;
		clki4 <= #((clkin_period*c4div/gmult)/2) ~clki4;
		clki5 <= #((clkin_period*c5div/gmult)/2) ~clki5;
	end
	assign locked = locked_i;
	assign drp_ready = 1'b0;
	assign int_drp_data_out = 16'b0000000000000000;

`endif // SIMULATE
	assign clk0 = clki0;
	assign clk1 = clki1;
	assign clk2 = clki2;
	assign clk3 = clki3;
	assign clk4 = clki4;
	assign clk5 = clki5;

	// DRP interface - pulse signals and latch result

	// DRP enable pulse
	always @(posedge drp_clk) begin
		int_drp_go <= drp_go;
		drp_enable <= (~(int_drp_go) & drp_go);

		// DRP done latch
		if (drp_ready == 1'b1) begin
			drp_done <= 1'b1;
		end
		else if (drp_enable == 1'b1) begin
			drp_done <= 1'b0;
		end

		// DRP data latch
		if (drp_ready == 1'b1) begin
			drp_data_out <= int_drp_data_out;
		end
	end

	endmodule
