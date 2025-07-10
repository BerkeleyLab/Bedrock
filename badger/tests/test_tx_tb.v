`timescale 1ns / 1ns

module test_tx_tb;

parameter mac_aw=8;
reg clk;
integer cc;
reg [15:0] host_mem[0:(1<<mac_aw)-1];
integer out_file;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("test_tx.vcd");
		$dumpvars(5,test_tx_tb);
	end
	$readmemh("host_mem", host_mem);
	out_file = $fopen("test_tx.out", "w");
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<200; cc=cc+1) begin
		clk=0; #4;  // 125 MHz
		clk=1; #4;
	end
	$display("PASS");
	$finish(0);
end

wire strobe;  // will be xformer.v or precog?

// Packet send requests hard-coded here
reg start=0;
reg [mac_aw-1:0] buf_start_addr;
wire done;
always @(posedge clk) begin
	case (cc)
		10: buf_start_addr <= 0;
		11: start <= 1;
		50: buf_start_addr <= 60;
		51: start <= 1;
		120: buf_start_addr <= 30;
		121: start <= 1;
		160: buf_start_addr <= 0;
		161: start <= 1;
	endcase
	if (done) start <= 0;
end

// Normally host_mem would be DPRAM, but this testbench
// doesn't need a host-write port.  Instead, it gets filled
// by the $readmemh() above.
wire [mac_aw-1:0] host_addr;
reg [15:0] host_d;
always @(posedge clk) host_d <= host_mem[host_addr];

// Center of DUT complex
wire req;
wire [10:0] len_req;
wire [7:0] mac_data;
test_tx_mac #(.mac_aw(mac_aw)) mac(.clk(clk), .ce(1'b1),
	.host_addr(host_addr), .host_d(host_d),
	.start(start), .buf_start_addr(buf_start_addr), .done(done),
	.req(req), .len_req(len_req),
	.strobe(strobe), .mac_data(mac_data)
);

// Randomized delay from req to strobe
reg [3:0] del1=0;
reg req_d=0;
always @(posedge clk) begin
	req_d <= req;
	if (req & ~req_d) del1 <= $random;
	else if (del1 != 0) del1 <= del1 - 1;
end
assign strobe = req & req_d & (del1 == 0);

// Push Tx data to output file
integer rc;
always @(negedge clk) if (strobe && out_file!=0)
	rc = $fputc(mac_data, out_file);

endmodule
