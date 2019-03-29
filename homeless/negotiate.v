// Ethernet PCS autonegotiation
// http://www.iol.unh.edu/services/testing/ge/training/1000BASE-X/Clause%2037%20Auto-Negotiation.pdf

// lacr == Link Autonegotiation Configuration Register
// module takes up about 42 4-LUTs in Spartan-3, can clock over 180 MHz
//   (need 125 MHz)
module negotiate(
	input rx_clk,    // timespec 5.55 ns
	input los,    // loss of signal
	// data received
	input [15:0] lacr_in,
	input lacr_in_stb,
	// data to be sent
	input tx_clk,
	output [15:0] lacr_out,
	output reg lacr_send,
	// mode control
	output reg operate,
	output [1:0] state_mon,
	output [5:0] leds
);

initial lacr_send=0;
initial operate=0;

// Process the input from the LACR receiver, looking for
// three in a row of the same value.
reg [15:0] lacr_prev_val=0;
reg lacr_match=0, lacr_change=0, lacr_ready=0;
reg [2:0] lacr_valid_cnt=0;
always @(posedge rx_clk) begin
	if (lacr_in_stb) lacr_prev_val <= lacr_in;
	lacr_match  <= lacr_in_stb & (lacr_prev_val == lacr_in);
	lacr_change <= lacr_in_stb & (lacr_prev_val != lacr_in);
	if (lacr_match) begin
		lacr_ready <= lacr_valid_cnt == 2;
		if (lacr_valid_cnt != 2) lacr_valid_cnt <= lacr_valid_cnt + 1;
	end
	if (lacr_change) begin
		lacr_ready <= 0;
		lacr_valid_cnt <= 0;
	end
end
wire unexpected = |lacr_prev_val[8:7] | |lacr_prev_val[3:2];

// Compute action to take based on the value of LACR received
reg lacr_yes=0;  // got a value with ACK set that tells us to start running
reg lacr_no=0;   // got some other value, means we should stop running
wire rx_ack = lacr_prev_val[1];
reg ack_=0;      // ACK signal in Rx clock domain
always @(posedge rx_clk) begin
	lacr_yes <= 0;
	lacr_no  <= 0;
	if (lacr_match & lacr_ready) begin
		ack_ <= (lacr_prev_val[15:10]==6'b1);
		if ((lacr_prev_val[15:10]==6'b1) & rx_ack) lacr_yes <= 1;
		else lacr_no <= 1;
	end
end

// Autonegotiation state machine
parameter [1:0]
  AN_START = 0,
  AN_DWELL = 1,
  AN_PAUSE = 2,
  AN_RUN = 3;

// right number is 1300000, with a 21-bit cnt, but that triggers a
// INTERNAL_ERROR:Pack:pktbaplacepacker.c:897:1.139.4.6 - Unable to obey ..
parameter DELAY=1000000; // number of 8ns ticks for states AN_DWELL and AN_PAUSE

reg [1:0] an_state=AN_START;
reg [19:0] cnt=0;
reg lacr_send_=0;       // lacr_send in the Rx clock domain
always @(posedge rx_clk)
	if (lacr_no | los) begin
		an_state <= AN_START;
	end else case (an_state)
	AN_START: begin
		// Send LACR to start autonegotiation process
		// We hope ACK will get set in the middle of this state
		if (lacr_yes & ack_) begin
			an_state <= AN_DWELL;
			cnt <= DELAY;
		end
		lacr_send_ <= 1;
	end
	AN_DWELL: begin
		// Keep sending LACR in this state
		cnt <= cnt-1;
		if (cnt==0) begin
			an_state <= AN_PAUSE;
			cnt <= DELAY;
		end
	end
	AN_PAUSE: begin
		// Stop sending LACR, but don't operate yet
		lacr_send_ <= 0;
		cnt <= cnt-1;
		if (cnt==0) begin
			an_state <= AN_RUN;
		end
	end
	AN_RUN: begin
		// stay here until error, handled above
	end
endcase

assign leds={unexpected, lacr_ready, ack_,
	an_state==AN_DWELL, an_state==AN_PAUSE, an_state==AN_RUN};
assign state_mon = an_state;

// The following outputs are used in the Tx domain.
// Explicitly transfer them here
reg ACK=0;
reg operate_=0;
always @(posedge rx_clk) operate_ <= an_state == AN_RUN;
always @(posedge tx_clk) begin
	operate <= operate_;
	lacr_send <= lacr_send_;
	ACK <= ack_;
end

// 16-bit Ethernet Configuration Register as documented in
// Networking Protocol Fundamentals, by James Long
// and http://grouper.ieee.org/groups/802/3/z/public/presentations/nov1996/RTpcs8b_sum5.pdf
wire FD=1;   // Full Duplex capable
wire HD=0;   // Half Duplex capable
wire PS1=1;  // Pause 1 (this is a lie)
wire PS2=1;  // Pause 2 (this is a lie)
wire RF1=0;  // Remote Fault 1
wire RF2=0;  // Remote Fault 2
//   ACK     // Acknowledge -- important! defined above
wire NP=0;   // Next Page
// Set "Reserved" bits to 0
assign lacr_out = {NP, ACK, RF2, RF1, 3'b000, PS2, PS1, HD, FD, 5'b00000};

// {PS1,PS2} indicate supported flow-control.  Coding:
//   00 - no pause
//   01 - asymmetric pause toward link partner
//   10 - symmetric pause
//   11 - both symmetric and asymmetric pause toward local device
// {RF1,RF2} indicate to the remote device whether a fault has been
// detected by the local device.  Coding:
//   00 - No error, link OK
//   01 - Offline
//   10 - Link Failure
//   11 - Link Error
// ACK reception of at least three consecutive matching config_reg
// NP  parameter information follows, either message page or unformatted page

endmodule
