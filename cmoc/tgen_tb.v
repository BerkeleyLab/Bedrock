`timescale 1ns / 1ns

module tgen_tb;

reg clk;
integer cc, errors;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("tgen.vcd");
		$dumpvars(5,tgen_tb);
	end
	errors=0;
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<240; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	//$display("%s",errors==0?"PASS":"FAIL");
	$display("PASS");
	$finish();
end

integer file1;
reg [255:0] file1_name;
initial begin
	if (!$value$plusargs("tgen_seq=%s", file1_name)) file1_name="tgen_seq.dat";
	file1 = $fopen(file1_name,"r");
end

integer rc=2;
reg [31:0] control_data, cd;
reg [16:0] control_addr, ca;
reg control_strobe=0;
integer control_cnt=0;
integer wait_horizon=5;
always @(posedge clk) begin
	control_cnt <= control_cnt+1;
	if (control_cnt>wait_horizon && control_cnt%3==1 && rc==2) begin
		rc = $fscanf(file1,"%d %d\n",ca,cd);
		if (rc==2) begin
			if (ca == 555) begin
				$display("stall %d cycles", cd);
				wait_horizon = control_cnt + cd;
			end else begin
				$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
				control_data <= cd;
				control_addr <= ca;
				control_strobe <= 1;
			end
		end
	end else begin
		control_data <= 32'hx;
		control_addr <= 7'hx;
		control_strobe <= 0;
	end
end
wire dests_write = control_addr[16:12] == 1;  // matches addresses 4096-8191; see tgen_seq.dat

reg trig=0;
// cc==90 trig will be ignored
always @(posedge clk) trig <= cc==70 || cc==90 || cc==130 || cc==170 || cc==210;
reg bank_next=0;
always @(posedge clk) if (cc==60 || cc==150) bank_next <= ~bank_next;

wire collision;
wire [31:0] lbo_data;
wire lbo_write;
wire [16:0] lbo_addr;
wire [3:0] status;
wire [31:0] delay_pc_XXX = 0;  // dummy
tgen dut(.clk(clk), .trig(trig), .collision(collision),
	.lb_data(control_data), .lb_write(control_strobe), .lb_addr(control_addr),
	.bank_next(bank_next), .status(status),
	.addr_padding(1'b0),
	.dests_write(dests_write), .delay_pc_XXX(delay_pc_XXX),
	.lbo_data(lbo_data), .lbo_write(lbo_write), .lbo_addr(lbo_addr)
);

always @(negedge clk) begin
	if (lbo_write) $display("slave bus[%d] = 0x%x (%d)",lbo_addr,lbo_data,lbo_data);
end

endmodule
