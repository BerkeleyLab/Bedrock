`timescale 1ns / 1ns

module scanner_tb;

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd4};  // 192.168.7.4
parameter [47:0] mac = 48'h12555500012d;

reg clk;
integer cc;
reg pass=1;
integer test_count=0;
wire [15:0] test_count_goal;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("scanner.vcd");
		$dumpvars(5,scanner_tb);
	end
	// Plan to stop at end of file when test_count_goal gets set;
	// cc limit is just a fail-safe to keep us out of an infinite loop.
	for (cc=0; cc<20000 && test_count_goal==0; cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
	if (test_count_goal != 0) $display("expecting %2d tests", test_count_goal);
	if (pass && test_count == test_count_goal) $display("PASS");
	else begin
		$display("FAIL");
		$stop();
	end
end

// Create flow of packets
// offline takes care of its own argument parsing and file opening
wire [7:0] goal;
wire eth_in_s;
wire [7:0] eth_in;
offline offline(.clk(clk), .rx_dv(eth_in_s), .rxd(eth_in),
	.goal(goal), .count(test_count_goal));

// DUT
wire [3:0] ip_a;  reg [7:0] ip_d=0;  // MAC/IP config, Rs side
wire status_valid;  wire [7:0] status_vec;
wire [10:0] pack_len;
wire [3:0] pno_a;
reg [7:0] pno_d;
scanner a(.clk(clk),
	.eth_in(eth_in), .eth_in_s(eth_in_s),
	.eth_in_e(1'b0), .enable_rx(1'b1),  // no tests for these
	.ip_a(ip_a), .ip_d(ip_d),
	.pno_a(pno_a), .pno_d(pno_d),
	.status_valid(status_valid), .status_vec(status_vec), .pack_len(pack_len)
);

// Easy viewing
reg [7:0] stat_r=0;
always @(posedge clk) if (status_valid) stat_r <= status_vec;

// Memory for MAC/IP addresses
reg [7:0] ip_mem[0:15];
always @(posedge clk) ip_d <= ip_mem[ip_a];
initial begin
	// Matches packets in at least arp3.dat, icmp3.dat, udp3.dat.
	ip_mem[0] = mac[47:40];  // Start of MAC
	ip_mem[1] = mac[39:32];
	ip_mem[2] = mac[31:24];
	ip_mem[3] = mac[23:16];
	ip_mem[4] = mac[15:8];
	ip_mem[5] = mac[7:0];  // End of MAC
	ip_mem[6] = ip[31:24];  // Start of IP
	ip_mem[7] = ip[23:16];
	ip_mem[8] = ip[15:8];
	ip_mem[9] = ip[7:0];  // End of IP
end

// Memory for UDP port numbers
reg [7:0] number_mem[0:15];
always @(posedge clk) pno_d <= number_mem[pno_a];
initial begin
	number_mem[0] = 0;
	number_mem[1] = 7;
	number_mem[2] = 3;
	number_mem[3] = 232;
	number_mem[4] = 7;
	number_mem[5] = 208;
	number_mem[6] = 11;
	number_mem[7] = 184;
	number_mem[8] = 0;
	number_mem[9] = 0;
	number_mem[10] = 0;
	number_mem[11] = 0;
	number_mem[12] = 0;
	number_mem[13] = 0;
	number_mem[14] = 0;
	number_mem[15] = 0;
end

// Print per-packet test result summary
reg fault;
always @(negedge clk) if (status_valid) begin
	test_count = test_count+1;
	fault = status_vec != goal;
	$display("%2d:  Length %4d   Status word 0x%x   goal 0x%x   %s",
		test_count, pack_len, status_vec, goal, fault ? "FAULT" : "   OK");
	if (fault) pass = 0;
end

endmodule
