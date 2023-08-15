// Based on test bench for the badger/mem_gateway client.
//
`timescale 1ns / 1ns
module lb_marble_slave_tb;

parameter n_lat=8;

initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("lb_marble_slave.vcd");
		$dumpvars(5, lb_marble_slave_tb);
	end
end

// Gateway to UDP, client interface test generator
wire [10:0] len_c;
wire [7:0] idata, odata;
wire clk, raw_l, raw_s;
wire in_use=0;
client_sub #(.n_lat(n_lat)) net(.clk(clk), .len_c(len_c), .idata(idata),
	.raw_l(raw_l), .raw_s(raw_s), .odata(odata), .thinking(in_use));

// Badger client plugin to localbus master
wire [23:0] addr;
wire [31:0] data_out, data_in;
wire control_strobe, control_rd, control_rd_valid;
mem_gateway #(.n_lat(n_lat), .enable_bursts(1)) dut(.clk(clk),
	.len_c(len_c), .idata(idata), .raw_l(raw_l), .raw_s(raw_s),
	.odata(odata),
	.addr(addr), .control_strobe(control_strobe),
	.control_rd(control_rd), .control_rd_valid(control_rd_valid),
	.data_out(data_out), .data_in(data_in)
);

// TWI bus itself
tri1 TWI_SCL, TWI_SDA, TWI_INT, TWI_RST;
wire [2:0] dum_scl;
tri1 [2:0] dum_sda;

// Should mostly match marble_base.v, some outputs ignored
lb_marble_slave #(.USE_I2CBRIDGE(1), .twi_q0(4), .twi_q1(0), .twi_q2(2), .led_cw(6)) slave(
	.clk(clk), .addr(addr),
	.control_strobe(control_strobe), .control_rd(control_rd),
	.data_out(data_out), .data_in(data_in),
	.clk62(clk),
	.ibadge_clk(1'b0),
	.ibadge_stb(1'b0), .ibadge_data(8'b0),
	.obadge_stb(1'b0), .obadge_data(8'b0),
	.tx_mac_done(1'b0), .rx_mac_data(16'b0),
	.rx_mac_buf_status(2'b0),
	.xdomain_fault(1'b0),
	.frequency_si570(28'd3333),
	.mmc_pins(4'b0),
	.rx_category_s(1'b0), .rx_category(4'b0),
	.twi_scl({dum_scl, TWI_SCL}), .twi_sda({dum_sda, TWI_SDA}),
	.gps(4'b00z0),
	.twi_int(TWI_INT), .twi_rst(TWI_RST)
);

// One stupid device on the bus
// Doesn't actually match Marble hardware
parameter SADR = 7'b0010_000;
i2c_slave_model #(.I2C_ADR(SADR), .debug(0)) hw_slave(.scl(TWI_SCL), .sda(TWI_SDA));

// One weird hack, even works in Verilator!
always @(posedge clk) begin
	if (slave.stop_sim & ~in_use & ~raw_l) begin
		$display("hw_test_tb:  stopping based on localbus request");
		$finish(0);
	end
end

endmodule
