`timescale 1ns / 1ns

module i2c_chunk_tb;

reg clk;
integer cc, ix, worked=0, file2;
reg [255:0] file2_name;
reg [7:0] td;  // scractch copy of trace data
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("i2c_chunk.vcd");
		$dumpvars(5,i2c_chunk_tb);
	end
	for (cc=0; cc<55000; cc=cc+1) begin
		clk=0; #10;
		clk=1; #10;
	end
	if ($value$plusargs("dfile=%s", file2_name)) begin
		$display("Will write trace to %s", file2_name);
		file2 = $fopen(file2_name,"w");
		$fdisplay(file2, "# %d %d", 6, 2);
		for (ix=0; ix<290; ix=ix+1) begin
			td = chunk.dpram.mem[1*1024+ix];
			$fdisplay(file2, "%d %d %d", ix, td[7:2], td[1:0]);
		end
	end
	// for (ix=2048; ix<2088; ix=ix+1) $display("%x %x", ix, chunk.dpram.mem[ix]);
	worked = worked + (chunk.dpram.mem[12'h800] === 8'h5a);
	worked = worked + (chunk.dpram.mem[12'h801] === 8'ha5);
	worked = worked + (chunk.dpram.mem[12'h802] === 8'h5a);
	worked = worked + (chunk.dpram.mem[12'h820] === 8'ha5);
	$display("%d worked, %s", worked, (worked==4) ? "PASS" : "FAIL");
	if (worked != 4) $stop();
	$finish();
end

parameter SADR = 7'b0010_000;

// Local bus
reg [11:0] lb_addr;
reg [7:0] lb_din;
reg lb_write=0;
wire [7:0] lb_dout;

// I2C bus itself -- unless you want to call it TWI
wire scl, sda_drive;
tri1 sda = sda_drive ? 1'bz : 1'b0;
wire sda_sense = sda;

reg trig=0, run=0, freeze=0;
integer file1, rc=1;
reg [7:0] fval;
reg [11:0] dest_p=0;
initial begin
	file1 = $fopen("init.in","r");
	while (rc==1) begin
		rc = $fscanf(file1,"%x\n", fval);
		if (rc==1) begin
			@(posedge clk);
			lb_addr <= dest_p;
			lb_din <= fval;
			lb_write <= 1;
			dest_p <= dest_p+1;
			@(posedge clk);
			lb_addr <= 12'bx;
			lb_din <= 8'bx;
			lb_write <= 0;
			@(posedge clk);
		end
	end
	run <= 1;
	trig <= 1;
	#5000;
	trig <= 0;
end

// Instantiate device under test
wire [3:0] hw_config;
i2c_chunk #(.q1(0), .q2(2)) chunk (.clk(clk),
	.lb_addr(lb_addr), .lb_din(lb_din), .lb_write(lb_write),
	.lb_dout(lb_dout),
	.run_cmd(run), .freeze(freeze), .hw_config(hw_config),
	.scl(scl), .sda_drive(sda_drive), .sda_sense(sda_sense),
	.intp(1'b0), .rst(1'b1)
);

// One device on the bus
i2c_slave_model #(.I2C_ADR(SADR), .debug(0)) slave (.scl(scl), .sda(sda));

endmodule
