`timescale 1ns / 1ns
module idelay_scanner_tb;

reg lb_clk;
integer cc;
integer agreed=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("idelay_scanner.vcd");
		$dumpvars(5,idelay_scanner_tb);
	end
	for (cc=0; cc<35000; cc=cc+1) begin
		lb_clk=0; #5;
		lb_clk=1; #5;
	end
	// not 16, because we overwrite lane 7 result with "software"
	if (agreed == 15) $display("PASS"); else $display("FAIL", agreed);
	$finish();
end

// Use ADC data pulled from real hardware (SN011) and AD9653 test pattern 00001100
// Last row holds the "right" idelay values for cross-checking purposes
reg [7:0] experimental [0:16*32+16-1];
integer ix;
initial  $readmemh("sn011.dat", experimental);

// Construct a local bus, we'll use it at the end
// to read data out of the mirror RAM.
reg [10:0] lb_addr=7;
reg [4:0] lb_data=30;
reg lb_id_write=1;
reg scan_trigger=0;
always @(posedge lb_clk) scan_trigger <= cc==10;

// adc_clk not synchronous with lb_clk
reg adc_clk=0;
always begin #4; adc_clk=~adc_clk; end
reg [15:0] adc_val=0;  // will be filled in later

// DUT instantiation and its outputs
wire [6:0] mirror_val;
wire [7:0] result_val;
wire scan_running;
wire [3:0] hw_addr;
wire [4:0] hw_data;
wire [7:0] banyan_mask;
wire hw_strobe;
wire [2:0] adc_num;
idelay_scanner #(.use_decider(1)) dut(
	.lb_clk(lb_clk), .lb_addr(lb_addr[3:0]), .lb_data(lb_data),
	.lb_id_write(lb_id_write),
	.scan_trigger(scan_trigger), .autoset_enable(1'b1),
	.scan_running(scan_running),
	.ro_clk(lb_clk), .ro_addr(lb_addr),
	.mirror_val(mirror_val), .result_val(result_val),
	.debug_sel(1'b0), .debug_addr(4'b0),
	.hw_addr(hw_addr), .hw_data(hw_data), .hw_strobe(hw_strobe),
	.banyan_mask(banyan_mask), .adc_num(adc_num),
	.adc_clk(adc_clk), .adc_val(adc_val)
);

// Delay values for each of the (virtual) IDELAY primitives,
// written to by the hw_* bus from idelay_scanner
reg [4:0] idelay_state [0:15];
integer jx;
initial for (jx=0; jx<16; jx=jx+1) idelay_state[jx] = 0;
always @(lb_clk) if (hw_strobe) idelay_state[hw_addr] <= hw_data;

// Construct ADC data from two lanes
wire [3:0] lane0 = {adc_num,1'b0};  wire [4:0] idelay_l0 = idelay_state[lane0];
wire [3:0] lane1 = {adc_num,1'b1};  wire [4:0] idelay_l1 = idelay_state[lane1];
wire [7:0] lane0_data = experimental[{idelay_l0, lane0}];
wire [7:0] lane1_data = experimental[{idelay_l1, lane1}];
always @(posedge adc_clk) adc_val <= {lane0_data,lane1_data};  // $random;

reg showme=0, showme_d=0;
reg [3:0] showme_addr;
always @(posedge lb_clk) begin
	lb_addr <= 7;
	showme <= 0;
	if (cc>=34000 && cc<34032) begin
		lb_id_write <= 0;
		lb_addr <= (cc-34000)/2;
		showme <= cc%2==1;
	end
	showme_d <= showme;
	showme_addr <= lb_addr;
end
reg [3:0] crosscheck;
always @(negedge lb_clk) if (showme_d) begin
	crosscheck = experimental[16*32+showme_addr];
	if (mirror_val[6:5] == 2 && mirror_val[4:0] == crosscheck) agreed=agreed+1;
	$display("%d %d %d %d",
		showme_addr, mirror_val[6:5], mirror_val[4:0],
		experimental[16*32+showme_addr]);
end

endmodule
