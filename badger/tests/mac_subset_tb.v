`timescale 1ns / 1ns

module mac_subset_tb;

parameter mac_aw=8;
parameter latency=64;
parameter stretch=3;
parameter ifg=3;
reg clk;
integer cc;
integer out_file, hfd;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("mac_subset.vcd");
		$dumpvars(5,mac_subset_tb);
	end
	out_file = $fopen("mac_subset.out", "w");
	hfd = $fopen("host_cmds.dat", "r");
	for (cc=0; cc<300; cc=cc+1) begin
		clk=0; #4;  // 125 MHz
		clk=1; #4;
	end
	if (fail) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

// Fake scanner
integer gapn=0;
always @(posedge clk) case (cc)
	10: gapn <= 4;
	20: gapn <= 16;
	40: gapn <= 17;
	60: gapn <= 15;
	80: gapn <= 20;
	120: gapn <= 13;
	150: gapn <= 14;
	180: gapn <= 34;
	default: if (gapn>0) gapn <= gapn-1;
endcase
reg scanner_busy=0;
always @(posedge clk) scanner_busy <= gapn==0;

// Delay by latency cycles
reg [latency:0] circle;
integer cix=0;
reg scanner_delayed=0;
always @(posedge clk) begin
	scanner_delayed <= circle[cix];
	circle[cix] <= scanner_busy;
	cix <= cix==latency-2 ? 0 : cix+1;
end

// Host bus definition
wire host_clk = clk;
reg [mac_aw:0] host_waddr;
reg host_write=0;
reg [15:0] host_wdata;

// Host bus driven from file
reg wval, wait_mode=0;
wire done;
always @(posedge clk) begin
	host_write <= 0;
	case (1)
		wait_mode: if (wval == done) wait_mode <= 0;
		$fscanf(hfd, "%x %x\n", host_waddr, host_wdata) == 2: host_write <= 1;
		$fscanf(hfd, "wait %d\n", wval) == 1: wait_mode <= 1;
	endcase
end

// memory and control signals are handled external to mac_subset.v
// in this branch, which the testbenches were not designed for ...
// the next few lines are patching that up
wire [mac_aw-1:0] host_raddr;
wire [15:0] host_rdata;
wire [mac_aw-1:0] buf_start_addr;
wire tx_mac_start;
wire tx_clk = clk;
mac_compat_dpram #(
	.mac_aw(mac_aw)
) mac_compat_dpram_inst (
	.host_clk(host_clk),
	.host_waddr(host_waddr),
	.host_write(host_write),
	.host_wdata(host_wdata),
// ----------------------------
	.tx_clk(tx_clk),
	.host_raddr(host_raddr),
	.host_rdata(host_rdata),
	.buf_start_addr(buf_start_addr),
	.tx_mac_start(tx_mac_start)
);

// DUT
wire [7:0] mac_data;
wire strobe_s, strobe_l;
mac_subset #(.mac_aw(mac_aw), .latency(latency), .stretch(stretch), .ifg(ifg)) mac(
	.host_raddr(host_raddr),
	.host_rdata(host_rdata),
	.buf_start_addr(buf_start_addr),
	.tx_mac_start(tx_mac_start),
	.tx_mac_done(done),
	.scanner_busy(scanner_busy),
	.tx_clk(tx_clk), .ce(1'b1), .mac_data(mac_data),
	.strobe_s(strobe_s), .strobe_l(strobe_l)
);

// Push Tx data to output file
integer rc;
always @(negedge clk) if (strobe_s && out_file!=0)
	rc = $fputc(mac_data, out_file);

// Flag timing errors
wire timing_error = strobe_l & scanner_delayed;
always @(posedge clk) if (timing_error) begin
	if (fail==0) $display("collsiion at time", $time);
	fail=1;
end

endmodule
