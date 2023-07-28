`timescale 1ns / 1ns

module slew_xarray_tb;

reg clk, fail=0;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("slew_xarray.vcd");
		$dumpvars(5, slew_xarray_tb);
	end
	for (cc=0; cc<400; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (fail) begin
		$display("FAIL");  // tell Makefile that we broke
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end

// Configure for 5-bit values, range 0 to 31.
// Speeds up the simulation by a factor of 8192.
reg [4:0] setm=0, setp=0;
reg enable=0;
reg [1:0] state=0;
always @(posedge clk) state <= state+1;
wire setmp_addr = state[0];  // will be provided by mp_proc
wire step = state[1];  // half-speed

// Test stimulus
always @(posedge clk) begin
	if (cc==3) setm <= 15;
	if (cc==8) enable <= 1;
	if (cc==14) setm <= 10;
	if (cc==45) setm <= 30;  // increase because no wrap
	if (cc==140) setm <= 10;
	if (cc==180) setp <= 10;
	if (cc==240) setp <= 30;  // decrease because wrap
	if (cc==300) setp <= 20;
	if (cc==350) setp <= 10;
end

wire [4:0] setmp = setmp_addr ? setm : setp;
wire [4:0] setmp_l;
wire [1:0] motion;
slew_xarray #(.dw(5)) dut(.clk(clk), .enable(enable),
	.setmp(setmp), .setmp_addr(setmp_addr), .step(step),
	.setmp_l(setmp_l), .motion(motion));

// These signals definitely help to make sense of the timing diagram
reg [4:0] setm_l=0, setp_l=0;
always @(posedge clk) begin
	if ( setmp_addr) setm_l <= setmp_l;
	if (~setmp_addr) setp_l <= setmp_l;
end

// Simple check that the output never moves more than a single step at a time
wire signed [5:0] setm_d = setmp_l - setm_l;
wire signed [4:0] setp_d = setmp_l - setp_l;
reg setm_f=0, setp_f=0;  // faults
always @(posedge clk) begin
	if ( setmp_addr) setm_f <= enable && (setm_d > 1 || setm_d < -1);
	if (~setmp_addr) setp_f <= enable && (setp_d > 1 || setp_d < -1);
	if (setm_f | setp_f) fail=1;
end

endmodule
