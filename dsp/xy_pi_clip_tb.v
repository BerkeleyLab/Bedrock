`timescale 1ns / 1ns

module xy_pi_clip_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("xy_pi_clip.vcd");
		$dumpvars(5,xy_pi_clip_tb);
	end
	for (cc=0; cc<200; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	$display("WARNING: Not a self-checking testbench. Will always pass.");
	$finish();
end

reg [2:0] state=0, state1=0, state2=0;
wire iq=state[0];
reg signed [17:0] in_xy=0;
integer ccx;
reg sync=0;
wire [1:0] s0_addr = {state[1],state[0]};
wire [1:0] s1_addr = {state2[2],state2[0]};
always @(posedge clk) begin
	ccx <= cc-5;
	state <= state+1;
	state1 <= state;
	state2 <= state1;
	sync <= state==7;
	in_xy <= 18'bx;
	case (state)
	7: in_xy <= 10000;
	0: in_xy <= 20000;
	endcase
	if (cc<7) in_xy <= 0;  // keep pipeline from getting corrupted at start-up
end

// Not used
reg [1:0] lb_write=0;
reg [1:0] lb_addr=0;
reg signed [17:0] lb_data=0;

wire signed [17:0] coeff, lim;
quad_ireg s0(.clk(clk), .rd_addr(s0_addr), .lb_data(lb_data), .lb_write(lb_write[0]), .lb_addr(lb_addr), .d(coeff));
quad_ireg s1(.clk(clk), .rd_addr(s1_addr), .lb_data(lb_data), .lb_write(lb_write[1]), .lb_addr(lb_addr), .d(lim));

reg signed [17:0] ff_drive, ff_phase;
reg ff_en=0;

initial begin
	s0.store[0] =  10000;  // coeff X I
	s0.store[1] = -12000;  // coeff Y I
	s0.store[2] =      0;  // coeff X P
	s0.store[3] =      0;  // coeff Y P
	s1.store[0] =      0;  // lim X hi
	s1.store[1] =      0;  // lim Y hi
	s1.store[2] =      0;  // lim X lo
	s1.store[3] =      0;  // lim Y lo
	@(cc==9);
	s1.store[0] = 1500;  // lim X hi
	s1.store[2] =  500;  // lim X lo
	@(cc==40);
	s1.store[1] = 2000;  // lim Y hi
	s1.store[3] = 2000;  // lim Y lo
	@(cc==56);
	s0.store[2] = -100;  // coeff X P
	@(cc==100);
	s1.store[0] = 500;  // lim X hi
	@(cc==120);
	ff_en       = 1;
	ff_drive    = 10;
end

wire signed [17:0] out_xy;
xy_pi_clip dut(.clk(clk), .sync(sync), .in_xy(in_xy),
	.coeff(coeff), .lim(lim),
	.ff_en(ff_en), .ff_drive(ff_drive), .ff_phase(ff_phase),
	.out_xy(out_xy)
);

endmodule

module quad_ireg(
	input clk,
	input [1:0] rd_addr,
	output signed [17:0] d,
	// local bus
	input signed [17:0] lb_data,
	input lb_write,
	input [1:0] lb_addr
);
reg signed [17:0] store[0:3], val=0;
always @(posedge clk) begin
	if (lb_write) store[lb_addr] <= lb_data;
	val <= store[rd_addr];
end
assign d = val;
endmodule
