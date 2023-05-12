`timescale 1ns / 1ns

module banyan_mem_tb;
parameter dw=12;
parameter aw=4;
reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("banyan_mem.vcd");
		$dumpvars(7,banyan_mem_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<2000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("PASS");
	$finish();
end

// Create input test data that is easy to understand
reg [8*dw-1:0] test=0;
integer ix;
reg [7:0] cx=0;
reg data_valid=1;

always @(posedge clk) begin
	cx <= cx+1;
	for (ix=0; ix<8; ix=ix+1) test[(ix)*dw+:dw] <= ((ix+1) << 8) + cx;
	if (cc > 1600) data_valid <= cx[0];
end

// Main test vector setup
reg trig=0;
reg [7:0] banyan_mask=0;
always @(posedge clk) begin
	trig <= 0;
	case (cc)
		6: banyan_mask <= 8'h01;
		8: trig <= 1;
		406: banyan_mask <= 8'h30;
		408: trig <= 1;
		806: banyan_mask <= 8'h55;
		808: trig <= 1;
		1206: banyan_mask <= 8'hff;
		1208: trig <= 1;
		1606: banyan_mask <= 8'hff;
		1608: trig <= 1;
	endcase
end

// Simple one-shot fill
reg run=0, run_d=0;
wire rollover, full;
always @(posedge clk) begin
	if (trig | rollover) run <= trig;
	run_d <= run;
end
wire reset = trig;

// DUT instantiation
wire [aw+3-1:0] pointer;
reg [aw+3-1:0] ro_addr=0, ro_addr_d=0;
wire [dw-1:0] ro_data;
banyan_mem #(.aw(aw), .dw(dw)) dut3(.clk(clk),
	.adc_data(test), .banyan_mask(banyan_mask),
	.reset(reset), .run(run & data_valid),
	.pointer(pointer), .rollover(rollover), .full(full),
	.ro_clk(clk), .ro_addr(ro_addr), .ro_data(ro_data)
);
// Output status can be expected to cross clock domains.
// pointer readout is only intended to be valid if ~run.
// Stretch the reported run signal to guarantee that validity rule.
wire banyan_run_s = run_d | run;
wire [5:0] banyan_aw_fix = aw;
wire [19:0] pointer_fix = pointer;
wire [31:0] status = {banyan_run_s, full, banyan_aw_fix, 4'b0, pointer_fix};

// Readout
reg ro_done=0, display_next=0;
always @(posedge clk) begin
	if (full & ~ro_done) ro_addr <= ro_addr+1;
	if (&ro_addr) ro_done <= 1;
	if (~full) ro_done <= 0;
	ro_addr_d <= ro_addr;  // pipeline match
	display_next <= full & ~ro_done;
end
always @(negedge clk) if (display_next) $display("%x %x %x", banyan_mask, ro_addr_d, ro_data);

endmodule
