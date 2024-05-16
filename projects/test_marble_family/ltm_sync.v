`timescale 1ns / 1ns

// Generate CLKIN pins for an LTM4673, based on a host-settable config word

module ltm_sync(
	input clk,
	input [4:0] ps_config,
	output [2:0] ps_sync
);

// XXX Wild attempt at something useful
// bits 0 and 2 for 12A channels at 600 kHz, CCM selected with "1"
// bit 1 for 5A channels at 1 MHz, CCM selected with "0"
// So default ps_sync for CCM should be 3'b101.
// This is the intended behavior when configured with
//   the power-on default of 0 for ps_config.

// ps_config values 0-7 (with upper two bits 0):
//   lower 3 bits disable CCM mode for the respective channels
// ps_config values 8-31 (with upper two bits non-zer0):
//   divide clock input (supposedly 125 MHz) by ps_config to get
//   a base rate 15.6 MHz to 4.03 MHz,
//   designed for nominal 5.95 MHz with ps_config == 21.
//   Sync bits are further divded down from there, as given below.
// LTM4673 data sheet asks for +/-30% of the nominal 600 kHz and 1 MHz.
reg [4:0] ps_sync_count=0;
reg [4:0] state=0;  // 0 to 29
reg [2:0] ps_sync_r=0;
// nominal step rate for state is 6 MHz
reg pulse_1MHz=0;    // step rate divided by 6
reg pulse_600kHz=0;  // step rate divided by 10
always @(posedge clk) begin
	ps_sync_count <= (ps_sync_count==0) ? ps_config : (ps_sync_count - 1);
	if (ps_sync_count==0) state <= (state == 0) ? 29 : (state - 1);
	pulse_1MHz <= (state == 1) | (state == 7) | (state == 13) | (state == 19) | (state == 25);
	pulse_600kHz <= (state == 2) | (state == 12) | (state == 22);
	if (ps_config[4:3] == 2'b00) ps_sync_r <= ps_config[2:0] ^ 3'b101;
	else ps_sync_r <= {pulse_600kHz, pulse_1MHz, pulse_600kHz};
end
assign ps_sync = ps_sync_r;

endmodule
