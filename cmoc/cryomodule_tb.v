`timescale 1ns / 1ns

// compatibility with the flag in cryomodule.v
//`define SIMPLE_DEMO  // Used to get a 5-minute bitfile build

module cryomodule_tb;

reg clk, trace;
integer cc, errors;
`ifdef SIMULATE
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("cryomodule.vcd");
		$dumpvars(7,cryomodule_tb);
	end
	trace = $test$plusargs("trace");
	errors=0;
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<12500; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	//$display("%s",errors==0?"PASS":"FAIL");
	$display("PASS");
	$finish(0);
end
`endif //  `ifdef SIMULATE

reg clk1x=0, clk2x=0;
always begin
	clk2x=0; #1.25;
	clk1x=~clk1x; #1.25;
	clk2x=1; #2.50;
end

integer file1, file2;
reg [255:0] file1_name;
reg [255:0] file2_name;
`ifdef SIMULATE
initial begin
	if (!$value$plusargs("dfile=%s", file1_name)) file1_name="cryomodule_in.dat";
	file1 = $fopen(file1_name,"r");
	file2 = 0;
	if ($value$plusargs("pfile=%s", file2_name)) file2 = $fopen(file2_name,"w");
end
`endif //  `ifdef SIMULATE

integer rc=2;
wire control_clk=clk;
// data path in cryomodule is configured consistent with read_pipe = 2
reg [31:0] control_data, cd;
reg [16:0] control_addr, control_addr_d0, control_addr_d, ca;
reg control_write=0, control_read=0, control_read_d0=0, control_read_d=0;
`ifdef SIMULATE
integer control_cnt=0;
integer start_read=11300;
integer len_read=1024;
integer wait_horizon=5;
always @(posedge control_clk) begin
	control_cnt <= control_cnt+1;
	if (control_cnt > wait_horizon && control_cnt%3==1 && rc==2) begin
		`ifdef SIMULATE
		rc=$fscanf(file1,"%d %d\n",ca,cd);
		`endif
		if (rc==2) begin
			if (ca == 555) begin
				$display("stall %d cycles",cd);
				wait_horizon = control_cnt + cd;
			end else begin
				$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
				control_data <= cd;
				control_addr <= ca;
				control_write <= 1;
			end
		end
	end else if (control_cnt == 680 || control_cnt == 750) begin
		// This just pokes the circle_buf state machine
		control_data <= 32'hx;
		control_addr <= len_read-1+16384+65536;
		control_read <= 1;
	end else if (control_cnt == 682 || control_cnt == 752) begin
		// This just pokes the circle_buf state machine
		control_data <= 32'hx;
		control_addr <= len_read-1+24576+65536;
		control_read <= 1;
	end else if (control_cnt == 690) begin
		// total hack to throw away a buffer quickly
		// otherwise would take 8448 cycles
		// The "real" simulation starts at the buf_sync event
		// triggered by the filling of this sacrificial buffer
`ifndef SIMPLE_DEMO
		#1; l.cryomodule_cavity[0].circle.write_addr = 8184; l.cryomodule_cavity[1].circle.write_addr = 8184;
`endif
	end else if (control_cnt >= start_read && control_cnt < (start_read+len_read)) begin
		// This actually reads the data collected
		control_data <= 32'hx;
                // 16384 for cavity 0
                // 24576 for cavity 1
		control_addr <= control_cnt-start_read+16384+65536;
		control_read <= 1;
	end else if (control_cnt >= (start_read + len_read) && control_cnt < (start_read+len_read+10)) begin
		// This actually reads the data collected
		control_data <= 32'hx;
                // 16384 for cavity 0
                // 24576 for cavity 1
		control_addr <= 49154 + control_cnt - start_read - len_read;
		control_read <= 1;
	end else begin
		control_data <= 32'hx;
		control_addr <= 7'hx;
		control_write <= 0;
		control_read <= 0;
	end
	control_addr_d0 <= control_addr;
	control_read_d0 <= control_read;
	control_addr_d  <= control_addr_d0;
	control_read_d  <= control_read_d0;
end
`endif //  `ifdef SIMULATE


// set buffer size to 1024 (fills in 128*33*2 clock cycles)
wire [31:0] read_result;
cryomodule #(.circle_aw(10), .cavity_count(2)) l(.clk1x(clk1x), .clk2x(clk2x),
	.lb_clk(control_clk),
	.lb_data(control_data), .lb_addr(control_addr), .lb_write(control_write),
	.lb_read(control_read), .lb_out(read_result)
);

wire signed [15:0] mem_val = read_result;  // unsigned -> signed
integer dptr0, ix, drow[0:7];
`ifdef SIMULATE
always @(posedge control_clk) if (control_read_d && control_cnt>2000) begin
	if (trace) begin
	   $display("read value[%d] = %d",control_addr_d-24576,mem_val);
	end
        // 16384 for cavity 0
        // 24576 for cavity 1
	dptr0 = control_addr_d - 16384 - 65536;
	drow[dptr0[2:0]] = mem_val;
	if (file2 != 0 && dptr0[2:0]==3'b111) begin
		for (ix=0; ix<8; ix=ix+1) $fwrite(file2," %d",drow[ix]);
		$fwrite(file2,"\n");
	end
end

initial begin
	#1; // lose races
`ifndef SIMPLE_DEMO
	l.cryomodule_cavity[0].llrf.controller.wave_cnt=10;  // hack to avoid wasting time
	l.cryomodule_cavity[1].llrf.controller.wave_cnt=10;  // hack to avoid wasting time
`endif
end
`endif //  `ifdef SIMULATE

endmodule
