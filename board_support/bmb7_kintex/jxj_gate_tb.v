`timescale 1ns / 1ns

module jxj_gate_tb;

parameter max_data_len=1024;
reg [7:0] pack_mem [0:max_data_len-1];

reg clk;
integer cc;
reg [127:0] packet_file;
integer data_len, udp_port;
reg use_packfile;
initial begin
	use_packfile = $value$plusargs("packet_file=%s", packet_file);
	if (use_packfile) $readmemh(packet_file,pack_mem);
	if (!$value$plusargs("data_len=%d", data_len))  data_len= 64;
	if ($value$plusargs("udp_port=%d", udp_port))  udp_port=0;
	if ($test$plusargs("vcd")) begin
		$dumpfile("jxj_gate.vcd");
		$dumpvars(5,jxj_gate_tb);
	end
	for (cc=0; (udp_port!=0) || (cc<800); cc=cc+1) begin
		clk=0; #10;
		clk=1; #10;
	end
end

// Simulated Rx data
reg [7:0] rx_din;
reg rx_stb=0, rx_end=0;

// Simulated Tx data
wire [7:0] tx_dout;
wire tx_rdy, tx_end;
wire tx_stb;

// Local bus
wire [23:0] lb_addr;
wire [31:0] lb_dout;
reg [31:0] lb_din;
wire lb_strobe, lb_rd;
jxj_gate dut(.clk(clk),
	.rx_din(rx_din), .rx_stb(rx_stb), .rx_end(rx_end),
	.tx_dout(tx_dout), .tx_rdy(tx_rdy), .tx_end(tx_end), .tx_stb(tx_stb),
	.lb_addr(lb_addr), .lb_dout(lb_dout), .lb_din(lb_din),
	.lb_strobe(lb_strobe), .lb_rd(lb_rd)
);

// Simulate Rx data
integer ci;
always @(posedge clk) begin
	ci = cc % (data_len*9+150);
	if ((ci>=100) & (ci<(100+data_len*9)) & (ci%9==0)) begin
		rx_din <= pack_mem[(ci-100)/9];
		rx_stb <= 1;
	end else begin
		rx_din <= 8'hxx;
		rx_stb <= 0;
	end
	rx_end <= (ci==(99+data_len*9));
end

`define NO_TX
`ifdef NO_TX
// Strobe to get Tx data
reg tx_stb_r=0;
reg [3:0] tx_cnt=0;
always @(posedge clk) begin
	tx_cnt <= tx_cnt==8 ? 0 : tx_cnt+1;
	tx_stb_r <= (tx_cnt==0) & tx_rdy;
end
assign tx_stb = 1; // tx_stb_r;
`else
wire data_out_pin;
// tx_8b9b drives tx_stb
tx_8b9b tx(.clk(clk), .data_out(data_out_pin), .word_in(tx_dout),
	.word_available(tx_rdy), .frame_complete(tx_end), .word_read(tx_stb));
`endif

always @(negedge clk) if (tx_stb) $display("Tx %x",tx_dout);

// Just for grins, see if the Rx module works
// Synthesize 4 x sampled waveform.
// According to comments in oversampled_rx_8b9b,
// "int_data(0) is first to arrive, int_data(3) is last"
`ifndef NO_TX
reg [7:0] comm_wave=0;
reg transition;
always @(posedge clk) begin
	transition = data_out_pin;
	if (comm_wave[7] != transition) transition = $random;
	comm_wave <= {{3{data_out_pin}},transition,comm_wave[7:4]};
end
wire [3:0] int_data = comm_wave[5-:4];
oversampled_rx_8b9b #(.word_width(8)) rx(.clk(clk),
	.sync_reset(cc<10),
	.int_data(int_data),
	.enable(1'b1));
`endif

// Stupid test rig
always @(posedge clk) case (lb_addr[2:0])
	 0: lb_din <= "Hell";
	 1: lb_din <= "o wo";
	 2: lb_din <= "rld!";
	 3: lb_din <= 32'h0d0a0d0a;
endcase


endmodule
