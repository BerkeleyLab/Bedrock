`timescale 1ns / 1ns

module jit_rad_gateway_demo #(
	parameter passthrough=0
) (
	input lb_clk,
	input [7:0] net_idata,
	output [7:0] net_odata,
`ifdef QF2
	input rx_stb,
	input rx_end,
	input tx_stb,
	output tx_rdy,
	output tx_end,
`else
	input raw_l,
	input raw_s,
	input [10:0] len_c,
	output [7:0] n_lat_expose,  // work around a limitation in Verilator
`endif
	output lb_error,
	input app_clk
);

// For use with cdc_snitch
(* magic_cdc = 1 *) reg [7:0] net_idata_r=0;
always @(posedge lb_clk) net_idata_r <= net_idata;

wire [23:0] lb_addr;
wire lb_strobe, lb_prefill;
wire [31:0] lb_dout;  // data sent from network to local bus for write cycles
reg [31:0] lb_din=0;  // main register with data read from local bus, headed back to net
wire lb_rd;

`ifdef QF2
(* magic_cdc = 1 *) reg rx_stb_r=0, rx_end_r=0, tx_stb_r=0;
always @(posedge lb_clk) begin
	rx_stb_r <= rx_stb;
	rx_end_r <= rx_end;
	tx_stb_r <= tx_stb;
end
jxj_gate #(.slow_rx(0)) jxjgate(
	.clk(lb_clk),
	.rx_din(net_idata_r), .rx_stb(rx_stb_r), .rx_end(rx_end_r),
	.tx_dout(net_odata), .tx_rdy(tx_rdy), .tx_end(tx_end), .tx_stb(tx_stb_r),
	.lb_addr(lb_addr), .lb_dout(lb_dout), .lb_din(lb_din),
	.lb_strobe(lb_strobe), .lb_rd(lb_rd), .lb_prefill(lb_prefill)
);
`else
(* magic_cdc *) reg raw_l_r=0, raw_s_r=0;
(* magic_cdc *) reg [10:0] len_c_r=0;
always @(posedge lb_clk) begin
	raw_l_r <= raw_l;
	raw_s_r <= raw_s;
	len_c_r <= len_c;
end
wire control_rd_valid;  // not used here
localparam n_lat = 10;
assign n_lat_expose = n_lat + 1;  // + 1 for the cdc_snitch pipeline?
mem_gateway #(.n_lat(n_lat)) badgergate(.clk(lb_clk),
	.len_c(len_c_r), .idata(net_idata_r), .raw_l(raw_l_r), .raw_s(raw_s_r),
	.odata(net_odata), .control_prefill(lb_prefill),
	.addr(lb_addr), .control_strobe(lb_strobe),
	.control_rd(lb_rd), .control_rd_valid(control_rd_valid),
	.data_out(lb_dout), .data_in(lb_din)
);
`endif

wire xfer_clk, xfer_strobe, xfer_snap;
wire [3:0] xfer_addr;
wire [31:0] lb_reg_bank_6;
reg [31:0] reg_bank_6=0;
jit_rad_gateway #(.passthrough(passthrough)) xfer_bank_6(
	.lb_clk(lb_clk), .lb_addr(lb_addr[3:0]),
	.lb_strobe(lb_strobe), .lb_odata(lb_reg_bank_6),
	.lb_prefill(lb_prefill), .lb_error(lb_error),
	.app_clk(app_clk), .xfer_clk(xfer_clk), .xfer_strobe(xfer_strobe),
	.xfer_addr(xfer_addr), .xfer_odata(reg_bank_6), .xfer_snap(xfer_snap)
);

wire [31:0] hello_0 = "Hell";
wire [31:0] hello_1 = "o wo";
wire [31:0] hello_2 = "rld!";
wire [31:0] hello_3 = 32'h0d0a0d0a;
wire [31:0] xfer_status;
reg [31:0] aset[0:15];
reg [31:0] test_1=0, test_2=0;  // for exercising xfer_snap

// Very basic pipelining of read process
reg [23:0] lb_addr_r=0;
always @ (posedge lb_clk) begin
	if (lb_strobe) lb_addr_r <= lb_addr;
end
//
reg [31:0] reg_bank_0=0;
//
always @(posedge lb_clk) begin
	if (lb_strobe) begin
		case (lb_addr)
			4'h0: reg_bank_0 <= hello_0;
			4'h1: reg_bank_0 <= hello_1;
			4'h2: reg_bank_0 <= hello_2;
			4'h3: reg_bank_0 <= hello_3;
			4'h4: reg_bank_0 <= xfer_status;
			default: reg_bank_0 <= 32'hfaceface;
		endcase
	end
end
//
always @(posedge xfer_clk) begin
	if (xfer_strobe) begin
		case (xfer_addr)
			4'h0: reg_bank_6 <= aset[0];
			4'h1: reg_bank_6 <= test_1;
			4'h2: reg_bank_6 <= test_2;
			4'h3: reg_bank_6 <= aset[3];
			4'h4: reg_bank_6 <= aset[4];
			4'h5: reg_bank_6 <= aset[5];
			4'h6: reg_bank_6 <= aset[6];
			4'h7: reg_bank_6 <= aset[7];
			4'h8: reg_bank_6 <= aset[8];
			4'h9: reg_bank_6 <= aset[9];
			4'ha: reg_bank_6 <= aset[10];
			4'hb: reg_bank_6 <= aset[11];
			4'hc: reg_bank_6 <= aset[12];
			4'hd: reg_bank_6 <= aset[13];
			4'he: reg_bank_6 <= aset[14];
			4'hf: reg_bank_6 <= aset[15];
		endcase
	end
end
//
always @(posedge lb_clk) begin
	casez (lb_addr_r)
		24'h????0?: lb_din <= reg_bank_0;
		24'h????6?: lb_din <= lb_reg_bank_6;
		default: lb_din <= 32'hfaceface;
	endcase
end

// Example of how you can atomically (single-cycle) capture
// some (or even all) of the registers in question.
// Don't do this for register 0; it's natively captured at
// the xfer_snap cycle.
reg [31:0] test_1p=0, test_2p=0;
always @(posedge app_clk) if (xfer_snap) begin
	test_1 <= aset[1];
	test_2 <= aset[2];
end

// Time-varying register set
reg lb_dynamic=0, app_dynamic=0;
integer ix;
reg [31:0] starter=22;
initial for (ix=0; ix<16; ix=ix+1) aset[ix] = 3*ix+22; 
always @(posedge app_clk) begin
	app_dynamic <= lb_dynamic;  // CDC
	starter <= (starter << 1) | starter[31];
	if (app_dynamic) begin
		aset[0] <= starter;
		for (ix=1; ix<16; ix=ix+1) aset[ix] <= (aset[ix-1]*5) ^ ix;
	end else begin
		for (ix=0; ix<16; ix=ix+1) aset[ix] <= ix*32'h11111110 + (15-ix);
	end
end

// Exactly one writable register
wire write_dynamic = lb_strobe & ~lb_rd & (lb_addr == 24'h100);
wire write_stop = lb_strobe & ~lb_rd & (lb_addr == 24'h200);
always @(posedge lb_clk) begin
	if (write_dynamic) lb_dynamic <= lb_dout;
	if (write_stop) begin
`ifdef VERILATOR
		$display("jit_rad_gateway_demo:  stopping based on localbus request");
		$finish(0);
`endif
	end
end

// More important than it looks.
// Makes sure that reg_bank_0 has input data from the lb_clk domain.
reg [9:0] err_cnt=0;
reg [9:0] pack_cnt=0;
always @(posedge lb_clk) begin
	if (lb_error) err_cnt <= err_cnt + 1;
	if (lb_prefill) pack_cnt <= pack_cnt + 1;
end
assign xfer_status = {12'b0, err_cnt, pack_cnt};

endmodule
