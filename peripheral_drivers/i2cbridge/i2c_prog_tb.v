`timescale 1ns / 1ns

module i2c_prog_tb;

reg clk;
integer cc;
integer worked=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("i2c_prog.vcd");
		$dumpvars(5,i2c_prog_tb);
	end
	for (cc=0; cc<24000; cc=cc+1) begin
		clk=0; #10;
		clk=1; #10;
	end
	$display("%s", worked==3 ? "PASS" : "FAIL");
	if (worked != 3) $stop();
	$finish();
end

// Pacing counter for bit engine
// Line rate is 50 MHz / 9 / 14 = 397 kbps,
// where 14 is the number of phases in i2c_bit module.
reg [3:0] tick_cnt=0;
always @(posedge clk) tick_cnt <= tick_cnt==9 ? 0 : tick_cnt+1;
wire tick = tick_cnt==3;

// Address of simulated slave hardware
parameter SADR = 7'b0010_000;

// I2C bus itself
wire scl_o, sda_o;  // outputs of DUT
tri1 scl_v = scl_o ? 1'bz : 1'b0;
tri1 sda_v = sda_o ? 1'bz : 1'b0;

// Generate test pattern
parameter [7:0] idle = 8'b00;
parameter [7:0] c_rd = 8'h20;
parameter [7:0] c_wr = 8'h40;
parameter [7:0] c_wx = 8'h60;
parameter [7:0] c_p1 = 8'h80;
integer ix=0, jx;
reg [7:0] command_table[0:29];
initial begin
	for (jx=0; jx<30; jx=jx+1) command_table[jx] = idle;
	command_table[0]  = c_p1 + 2;
	command_table[1]  = c_wr + 4;
	command_table[2]  =   {SADR, 1'b0};
	command_table[3]  =   8'h01;
	command_table[4]  =   8'ha5;
	command_table[5]  =   8'h5a;
	command_table[6]  = c_wx + 2;
	command_table[7]  =   {SADR, 1'b0};
	command_table[8]  =   8'h02;
	command_table[9]  = c_rd + 2;
	command_table[10] =   {SADR, 1'b1};
	command_table[11] = c_wx + 2;
	command_table[12] =   {SADR, 1'b0};
	command_table[13] =   8'h01;
	command_table[14] = c_rd + 3;
	command_table[15] =   {SADR, 1'b1};
	command_table[0]  = c_p1 + 2;
end
wire [9:0] p_addr;
reg [7:0] command=0;
always @(posedge clk) begin
	command <= command_table[p_addr];
end

// Instantiate device under test
wire [1:0] bit_cmd;
wire bit_adv, sda_h;
wire run_cmd = cc>500;
wire [7:0] result;
wire result_stb;
wire [9:0] result_addr;
i2c_prog prog (.clk(clk),
	.bit_cmd(bit_cmd), .bit_adv(bit_adv), .sda_h(sda_h),
	.p_addr(p_addr), .p_data(command),
	.result(result), .result_stb(result_stb), .result_addr(result_addr),
	.run_cmd(run_cmd)
);

// Supporting modules
wire [8:0] odata;
i2c_bit bit (.clk(clk),
	.tick(tick), .advance(bit_adv),
	.command(bit_cmd),
	.scl_o(scl_o), .sda_o(sda_o), .sda_v(sda_v), .sda_h(sda_h)
);

// Simulated slave hardware
i2c_slave_model #(.I2C_ADR(SADR), .debug(0)) slave (.scl(scl_v), .sda(sda_v));

// Check of results
reg [7:0] want;
reg ok;
integer rjx=0;
always @(negedge clk) if (result_stb) begin
	case (rjx)
		0: want=8'h5a;
		1: want=8'ha5;
		2: want=8'h5a;
	endcase
	ok = result == want;
	if (ok) worked = worked+1;
	$display("read result 0x%x, wanted 0x%x %s",
		result, want, ok ? "   OK" : "FAULT");
	rjx = rjx+1;
end

endmodule
