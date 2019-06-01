`timescale 1ns / 1ns
`include "constants.vams"
module user_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("user.vcd");
		$dumpvars(5,user_tb);
	end
	for (cc=0; cc<300; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

parameter pw = 18;
parameter extra = 4;
parameter mw = 18;
parameter data_len = 6;
parameter consts_len = 4;
parameter const_aw = 2;

// Clear out the register file before we begin
// This gives a zero starting point for any state variables
integer hx;
initial begin
	for (hx=0; hx<32; hx=hx+1) begin
		dut.cpu.rf_a[hx]=0;
		dut.cpu.rf_b[hx]=0;
	end
end

// Emulate the host writing constants before we begin
reg h_write=0;
reg [const_aw-1:0] h_addr=0;
reg signed [pw-1:0] h_data=0;
integer file1, ix, sx, kx;
integer rc, ca, ixa, type;
integer conveyor[0:7];
initial begin
	file1 = $fopen("init2.dat","r");
	sx = 0; // stream index
	rc = 3; // fake
	for (ix=0; rc==3; ix=ix+1) begin
		rc = $fscanf(file1,"%c %d %d\n", type, ixa, ca);
		// $display("read from file", rc, type, ixa, ca);
		if (rc==3) case (type)
		"s": begin conveyor[sx] = ca; sx = sx+1; end
		"h": begin @(posedge clk); h_addr<=ixa; h_write<=1; h_data<=ca; end
		"p": begin dut.cpu.rf_a[ixa] = ca <<< extra; end
		default: begin $display("input error"); end
		endcase
	end
	@(posedge clk); h_write<=0; h_addr<={const_aw{1'bx}}; h_data <= 18'bx;
	for (kx=0; kx < 32; kx=kx+1) dut.cpu.rf_b[kx] = dut.cpu.rf_a[kx];
end

`ifdef PARAM_REGBANK
// Decode Parameters into parallel register bank
reg  [pw-1:0] p_regbank[2**const_aw-1:0];
wire [pw*(2**const_aw)-1:0] param_in;

always @(posedge clk) if (h_write) p_regbank[h_addr] <= h_data;

genvar r;
generate for (r=0; r<2**const_aw; r=r+1) begin : G_P_REGBANK
	assign param_in[(r+1)*pw-1: r*pw] = p_regbank[r];
end endgenerate
`endif

reg signed [pw-1:0] meas=0;
reg trigger=0;
always @(posedge clk) begin
	if (cc-20>=0 && cc-20<data_len) begin
		meas <= conveyor[cc-20];
	end
	trigger <= cc==19;
end

wire signed [pw-1:0] a, b;
wire signed [21:0] trace;
wire trace_strobe;
sf_user #(.extra(extra), .mw(mw),
	.data_len(data_len), .consts_len(consts_len), .const_aw(const_aw)) dut(
	.clk(clk), .ce(1'b1), .meas(meas), .trigger(trigger),
`ifdef PARAM_REGBANK
	.param_in(param_in),
`else
	.h_write(h_write), .h_addr(h_addr), .h_data(h_data),
`endif
	.a_o(a), .b_o(b), .trace(trace), .trace_strobe(trace_strobe));

real f;
always @(negedge clk) begin
	f = dut.cpu.d_in / (131072.0*dut.cpu.scale);
	if (dut.cpu.we && cc>21) $display("%d:  r[%d] <= %d (%+8.5f)", cc-22, dut.cpu.wa, dut.cpu.d_in, f);
end

endmodule
