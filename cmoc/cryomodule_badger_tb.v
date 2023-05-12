`timescale 1ns / 1ns

module cryomodule_badger_tb;

// based mostly on aggregate_tb.v
parameter [31:0] ip = 32'd3232237316;  // 192.168.7.4
parameter [47:0] mac = 48'h112233445566;

// Buffer memory to hold a packet read from a file
parameter max_data_len=1024;
reg [7:0] pack_mem [0:max_data_len-1];

reg clk;
integer cc;
reg [127:0] packet_file;
integer data_len;
reg use_tap=1;
`ifdef SIMULATE
initial begin
	if ($value$plusargs("packet_file=%s", packet_file)) begin
		$readmemh(packet_file,pack_mem);
		use_tap=0;
	end
	if (!$value$plusargs("data_len=%d", data_len))  data_len= 64;
	if ($test$plusargs("vcd")) begin
		$dumpfile("cryomodule_badger.vcd");
		$dumpvars(5,cryomodule_badger_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; (cc<1800) | use_tap ; cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
	$display("PASS");
	$finish();
end
`endif //  `ifdef SIMULATE

reg [7:0] eth_in=0, eth_in_=0;
reg eth_in_s=0, eth_in_s_=0;
wire [7:0] eth_out;
wire eth_out_s;

reg eth_out_s1=0, ok_to_print=1;
integer ci;
`ifdef SIMULATE
always @(posedge clk) begin
	ci = cc % (data_len+150);
	if (use_tap) begin
		// Access to Linux tap interface, see tap-vpi.c
		if (cc > 4) $tap_io(eth_out, eth_out_s, eth_in_, eth_in_s_);
		eth_in <= eth_in_;
		eth_in_s <= eth_in_s_;
	end else if ((ci>=100) & (ci<(100+data_len))) begin
		eth_in <= pack_mem[ci-100];
		eth_in_s <= 1;
	end else begin
		eth_in <= 8'hxx;
		eth_in_s <= 0;
	end

	eth_out_s1 <= eth_out_s;
	if (eth_out_s1 & ~eth_out_s) ok_to_print <= 0;
	if (eth_out_s & ok_to_print) $display("octet %x",eth_out);
end
`endif //  `ifdef SIMULATE

// ADC clock and its second-harmonic
// Should match stanza larger_tb.v
reg clk1x=0, clk2x=0;
always begin
	clk2x=0; #1.25;
	clk1x=~clk1x; #1.25;
	clk2x=1; #2.50;
end

// Instantiate the module under test
wire eth_in_e=0;  wire eth_out_e;
cryomodule_badger #(.ip({8'd192, 8'd168, 8'd7, 8'd4}), .siphash_fifo_aw(7)) cryomodule_badger(.clk1x(clk1x), .clk2x(clk2x), .gmii_tx_clk(clk), .gmii_rx_clk(clk),
	.gmii_rxd(eth_in),  .gmii_rx_dv(eth_in_s),  .gmii_rx_er(eth_in_e),
	.gmii_txd(eth_out), .gmii_tx_en(eth_out_s), .gmii_tx_er(eth_out_e),
	.eth_cfg_clk(1'b0), .eth_cfg_set(10'b0)
);

endmodule
