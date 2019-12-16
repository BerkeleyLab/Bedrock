`timescale 1ns / 1ns

// AD6552 SPI DAC as used by White Rabbit to control VCXO
module ad5662_tb;

reg clk;  // 125 MHz
integer cc;
reg fail=0;
wire [1:0] faults;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("ad5662.vcd");
		$dumpvars(5,ad5662_tb);
	end
	for (cc=0; cc<500; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$display("%s", |faults ? "FAIL" : "PASS");
	if (|faults) $stop();
end

// Pacing counter for bit engine
reg [1:0] tick_cnt=0;
always @(posedge clk) tick_cnt <= tick_cnt==2 ? 0 : tick_cnt+1;
wire tick = tick_cnt==1;

// SPI bus itself, outputs of DUT
parameter nch=2;
wire sclk, sdo;
wire [nch-1:0] sync_;

// Stimulus
reg [15:0] data=16'h1234;
reg [1:0] ctl=2'h0;
reg [nch-1:0] sel=2'b01;
reg send=0;
always @(posedge clk) begin
	send <= (cc%153) == 20;
	if (cc==100) data <= 16'h4321;
	if (cc==250) sel <= 2'b10;
end

// Instantiate device under test
wire sda_h, busy;
ad5662 #(.nch(2)) dut (.clk(clk), .tick(tick),
	.data(data), .sel(sel), .ctl(ctl), .send(send),
	.busy(busy),
	.sclk(sclk), .sync_(sync_), .sdo(sdo)
);

reg [23:0] correct;
always @(posedge clk) if (send) correct <= {6'b0, ctl, data};

// Could I use an instance array instead?
ad5662_em #(.id(1)) dac1(.sclk(sclk), .din(sdo),
	.fault(faults[0]), .sync_(sync_[0]), .correct(correct));
ad5662_em #(.id(2)) dac2(.sclk(sclk), .din(sdo),
	.fault(faults[1]), .sync_(sync_[1]), .correct(correct));

endmodule

// Model of the AD5662 chip
module ad5662_em #(
	parameter id=0
) (
	// actual pins
	input sclk,
	input din,
	input sync_,
	// test harness
	input [23:0] correct,
	output reg fault
);
initial fault=0;

// Functional
reg [23:0] out_sr=0;
integer n_clk=0;
always @(negedge sclk) if (~sync_) begin
	out_sr <= {out_sr[22:0], din};
	n_clk <= n_clk+1;
end
always @(negedge sync_) begin
	n_clk=0;
	out_sr=0;
end
always @(posedge sync_) if ($time>0) begin
	$display("%1d 0x%x", id, out_sr);
	if (out_sr != correct) fault=1;
	if (n_clk != 24) $display("Wrong clock count! %d", n_clk);
end

// Timing checks
// t_ numbers reference AD5662 datasheet Table 2
integer start_t, sclk_t=0, this_per, t_1=9999, t_4;
always @(negedge sync_) start_t = $time;
always @(negedge sclk) if (start_t != 0) begin
	t_4 = $time-start_t;
	$display("t_4 = %3d ns", t_4);
	if (t_4 < 13) fault=1;
	start_t = 0;
end
always @(negedge sclk) if ($time>0) begin
	this_per = $time-sclk_t;
	if (t_1 > this_per) t_1 = this_per;
	sclk_t = $time;
end
integer t_7;
always @(posedge sync_) if ($time>0) begin
	t_7 = $time-sclk_t;
	$display("t_7 = %3d ns", t_7);
	$display("t_1 = %3d ns", t_1);
	if (t_1 < 48) fault=1;
	// Strictly speaking, threshold should be 50 ns for V_DD < 3.6V
end
endmodule
