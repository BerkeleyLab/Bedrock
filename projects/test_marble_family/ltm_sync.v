`timescale 1ns / 1ns

// Generate CLKIN pins for an LTM4673, based on a host-settable config word
// Designed for 125 MHz clk

module ltm_sync(
	input clk,
	input [4:0] ps_config,
	output [2:0] ps_sync
);

// ps_sync bits 0 and 2 for 12A channels at 600 kHz, CCM selected with "1"
// ps_sync bit 1 for 5A channels at 1 MHz, CCM selected with "0"
// So default ps_sync for CCM should be 3'b101.
// This is the intended behavior when configured with
//   the power-on default of 0 for ps_config.

// ps_config values 0-7 (with upper two bits 0):
//   lower 3 bits disable CCM mode for the respective channels
// ps_config values 16-31 (with upper bit non-zero):
//   divide clock input (supposedly 125 MHz) by ps_config to get
//   a base rate 7.81 MHz to 4.03 MHz,
//   designed for nominal 5.95 MHz with ps_config == 21.
//   Sync bits are further divded down from there, as given below.
// LTM4673 data sheet asks for +/-30% of the nominal 600 kHz and 1 MHz.
// With ps_config == 21, we give it 595 kHz and 992 kHz.
reg [4:0] ps_sync_count=0;
reg [4:0] state=0;  // 0 to 29
reg [2:0] ps_sync_r=0;
// nominal step rate for state is 6 MHz
reg p1=0, p1a=0;  // step rate divided by 6, nominally 1 MHz
reg p0=0, p2=0;   // step rate divided by 10, nominally 600 kHz
always @(posedge clk) begin
	ps_sync_count <= (ps_sync_count==1) ? ps_config : (ps_sync_count - 1);
	if (ps_sync_count==1) state <= (state == 0) ? 29 : (state - 1);
	// 1 MHz:  CLKIN12  (with implied CLKIN2 180 degrees from CLKNIN1)
	case (state)
		1: p1<=1;   2: p1<=1;   3: p1<=1;
		7: p1<=1;   8: p1<=1;   9: p1<=1;
		13: p1<=1;  14: p1<=1;  15: p1<=1;
		19: p1<=1;  20: p1<=1;  21: p1<=1;
		25: p1<=1;  26: p1<=1;  27: p1<=1;
		default: p1<=0;
	endcase
	// 600 kHz phase 1:  CLKIN0
	case (state)
		2: p0<=1;   3: p0<=1;   4: p0<=1;
		12: p0<=1;  13: p0<=1;  14: p0<=1;
		22: p0<=1;  23: p0<=1;  24: p0<=1;
		default: p0<=0;
	endcase
	// 600 kHz phase 2:  CLKIN3
	case (state)
		7: p2<=1;   8: p2<=1;   9: p2<=1;
		17: p2<=1;  18: p2<=1;  19: p2<=1;
		27: p2<=1;  28: p2<=1;  29: p2<=1;
		default: p2<=0;
	endcase
	// Delay p1 by a half-state to keep it out-of-time with p0 and p2 transitions
	// Conceptually the next line should be (ps_sync_count == ps_config/2)
	if (ps_sync_count==10) p1a <= p1;
	if (ps_config[4] == 1'b0) ps_sync_r <= ps_config[2:0] ^ 3'b101;
	else ps_sync_r <= {p2, p1a, p0};
end
assign ps_sync = ps_sync_r;
// Hints for testing on Marble v1.4.1 with ps_config=21:
//    TP20  R164  CLKIN0   595 kHz
//    TP22  R190  CLKIN12  992 kHz
//    TP21  R185  CLKIN3   595 kHz

endmodule
