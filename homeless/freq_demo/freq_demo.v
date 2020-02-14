module freq_demo(
	input refclk,
	input [3:0] unk_clk,
	output uart_tx,
	input uart_rx
);

// 9600 baud at 125 MHz
parameter cfg_divider = 20'd13021;
parameter rw = 25;  // refclk counter width
parameter rv = 25000000;
parameter uw = 25;
parameter dig_cnt = 4'd8;

// Trigger every 0.2 second = 25e6 cycles of 125 MHz clock
// Will divide result by 2, resulting in 1 count = 10 Hz
// Also note the 5 cycle dead-time during a switch between channels.
// The integration time for each channel is what's defined by rv.
reg [rw-1:0] refcnt=0;
reg refcnt_zero=1, reset_fe=0, refcnt_ending=0;
reg [1:0] clksel=0;
always @(posedge refclk) begin
	refcnt_zero <= refcnt == 0;
	refcnt_ending <= refcnt == 5;
	refcnt <= refcnt_zero ? rv+3 : refcnt-1;
	if (refcnt_ending) reset_fe <= 1;
	if (refcnt_zero) reset_fe <= 0;
	if (refcnt_ending) clksel <= clksel + 1;
end

// Instantiate frequency counter front-end
wire [uw-1:0] frequency;
freq_multi_count_fe #(.NF(4), .uw(uw), .gw(3)) fe(
	.unk_clk(unk_clk), .refclk(refclk),
	.clksel(clksel), .reset(reset_fe), .frequency(frequency));

// Convert frequency counter output to decimal
wire [3:0] nib_out;
wire rts, cts;
dec_forward #(.dw(uw-1)) dec(.clk(refclk),
	.bdata(frequency[uw-1:1]), .load(refcnt_ending), .dig_cnt(dig_cnt),
	.nib_out(nib_out), .rts(rts), .cts(cts));

// Key interface point, three control signals plus 4-bit data:
//   vv  refcnt_zero
//   vv  rts = request to send
//   vv  nib_out
//   ^^  cts = clear to send

// Build up message
// "#" will be converted to channel number
// "@" will be converted to decimal output
wire busy;
reg [4:0] msg_ctr=0;
reg [7:0] msg_pre_byte=0, msg_byte=0;
reg [255:0] message = "     Channel #:  @@@.@@@@@ MHz\015\n";
wire msg_digit = msg_pre_byte==8'h40;
wire rts2 = msg_ctr==0 ? refcnt_zero : msg_digit ? rts : 1'b1;
wire [1:0] clkselm1 = clksel-1;
always @(posedge refclk) begin
	if (rts2 & ~busy) msg_ctr <= msg_ctr-1;
	if (refcnt_zero) msg_ctr <= 31;
	msg_pre_byte <= message[msg_ctr*8 +: 8];
	case (msg_pre_byte)
	8'h23 /* # */: msg_byte <= {6'b001100, clkselm1};
	8'h40 /* @ */: msg_byte <= {4'b0011, nib_out};
	default: msg_byte <= msg_pre_byte;
	endcase
end
assign cts = msg_digit & ~busy;

// UART needs initialization
reg resetn=0, we=0;
always @(posedge refclk) begin
	resetn <= 1;
	if (resetn) we <= 1;
end

// Instantiate UART
simpleuart simpleuart (
	.clk         (refclk      ),
	.resetn      (resetn      ),
	.ser_tx      (uart_tx     ),
	.ser_rx      (uart_rx     ),
	.cfg_divider (cfg_divider),
	.b_we  (we & rts2),
	.b_re  (1'b0),
	.b_di  (msg_byte),
	.b_busy(busy)
);

endmodule
