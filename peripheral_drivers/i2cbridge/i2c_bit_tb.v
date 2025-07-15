`timescale 1ns / 1ns

module i2c_bit_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("i2c_bit.vcd");
		$dumpvars(5,i2c_bit_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<7000; cc=cc+1) begin
		clk=0; #10;
		clk=1; #10;
	end
	// $display("%s", fail ? "FAIL" : "PASS");
	$display("PASS");
	$finish(0);
end

// Pacing counter for bit engine
reg [3:0] tick_cnt=0;
always @(posedge clk) tick_cnt <= tick_cnt==9 ? 0 : tick_cnt+1;
wire tick = tick_cnt==3;

parameter SADR = 7'b0010_000;

// I2C bus itself
wire scl_o, sda_o;  // outputs of DUT
tri1 scl_v = scl_o ? 1'bz : 1'b0;
tri1 sda_v = sda_o ? 1'bz : 1'b0;

// Generate test pattern
parameter [1:0] idle = 3;
reg [1:0] command=idle;
integer ix=0, jx;
reg [1:0] command_table[0:49];
initial begin
	for (jx=0; jx<50; jx=jx+1) command_table[jx] = idle;
	command_table[1]  = 2;  // start
	command_table[2]  = 0;  // first bit of device address
	command_table[3]  = 0;
	command_table[4]  = 1;
	command_table[5]  = 0;
	command_table[6]  = 0;
	command_table[7]  = 0;
	command_table[8]  = 0;  // last bit of device address
	command_table[9]  = 0;  // write
	command_table[10] = 1;  // space for ack
	command_table[11] = 0;  // first bit of RAM address
	command_table[12] = 0;
	command_table[13] = 0;
	command_table[14] = 0;
	command_table[15] = 0;
	command_table[16] = 0;
	command_table[17] = 0;
	command_table[18] = 1;  // last bit of RAM address
	command_table[19] = 1;  // space for ack
	command_table[20] = 1;  // first bit of write data
	command_table[21] = 0;
	command_table[22] = 1;
	command_table[23] = 0;
	command_table[24] = 0;
	command_table[25] = 1;
	command_table[26] = 0;
	command_table[27] = 1;  // last bit of write data
	command_table[28] = 1;  // space for ack
	command_table[29] = 0;  // first bit of write data
	command_table[30] = 1;
	command_table[31] = 0;
	command_table[32] = 1;
	command_table[33] = 1;
	command_table[34] = 0;
	command_table[35] = 1;
	command_table[36] = 0;  // last bit of write data
	command_table[37] = 1;  // space for ack
	command_table[38] = 0;  // weird pre-stop cycle, forces old_bit=0
	// also forces sda low even if no ack, and adds a needed sck edge
	command_table[39] = 2;  // stop
end
wire advance;
always @(posedge clk) if (advance) begin
	command <= command_table[ix];
	ix <= ix+1;
end

// Instantiate device under test
wire sda_h;
i2c_bit dut (.clk(clk),
	.tick(tick), .advance(advance),
	.command(command),
	.scl_o(scl_o), .sda_o(sda_o), .sda_v(sda_v), .sda_h(sda_h)
);

// Supporting modules
i2c_slave_model #(.I2C_ADR(SADR)) slave (.scl(scl_v), .sda(sda_v));

endmodule
