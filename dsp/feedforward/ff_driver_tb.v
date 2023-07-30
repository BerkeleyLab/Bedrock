`timescale 1ns / 1ns

module ff_driver_tb;

reg clk;
integer cc;
reg fail=0;
reg trace;

parameter shift = 5;

parameter memw = 11;
reg signed [17:0] mem[0:(1<<memw)-1];

integer ix, fd, trace_fd, rc;
integer coeff_0, coeff_1, sim_expand;

initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("ff_driver.vcd");
		$dumpvars(5,ff_driver_tb);
	end
	fd = $fopen("cic_bankx_in.dat", "r");
	for (ix=0; ix<(1<<memw); ix=ix+1) begin
		rc = $fscanf(fd, "%d\n", mem[ix]);
		if (rc != 1) begin
			$display("FAIL: parse error, aborting");
			$stop(0);
		end
	end
	trace = $test$plusargs("trace");
	if (trace) begin
		trace_fd = $fopen("ff_driver.out", "w");
	end else begin
		trace_fd = 0;
	end
	if (!$value$plusargs("c0=%d", coeff_0)) coeff_0 =  67500;
	if (!$value$plusargs("c1=%d", coeff_1)) coeff_1 = -83030;
	if (!$value$plusargs("sim_expand=%d", sim_expand)) sim_expand = 2;
	if (sim_expand != (1<<shift)) begin
		$display("FAIL: Misconfiguration!  shift=%d, sim_expand=%d", shift, sim_expand);
		$stop(0);
	end

	for (cc=0; cc<(5000<<shift); cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (fail) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

reg start=0;
// Second pulse is intentionally delayed to demonstrate 'start' functionality
always @(posedge clk) start <= (cc == 10) || (cc == (1500 << shift));


// Scaling note:
//  every four clock ticks is a cycle
//  when shift==1, every cycle multiplies cavity state by (1 - coeff>>23)

reg signed [17:0] coeff_v;
wire [1:0] coeff_a;
wire [1:0] error;

// Coeff memory model
always @(posedge clk) case (coeff_a)
	2'b00: coeff_v <= coeff_0;  // drive coupling
	2'b01: coeff_v <= coeff_1;  // cavity decay
	default: coeff_v <= 18'bx;
endcase

// Waveform memory
wire [10:0] mem_a;
reg signed [17:0] mem_v=0;
always @(posedge clk) mem_v <= mem[mem_a];

wire signed [17:0] drive, drive_delta, cavity;

ff_driver # (
	.CAV_SHIFT (shift+5),
	.CIC_SHIFT (shift),
	.MEM_REP   (shift),
	.MEM_AW    (11),
	.squelch   (1)) dut (
	.clk       (clk),
	.start     (start),
	// Cavity model parameters
	.coeff      (coeff_v),
	.coeff_addr (coeff_a),
	// Feedforward memory
	.mem        (mem_v),
	.mem_addr   (mem_a),
	.cav_drive  (drive),
	.cav_ddrive (drive_delta),
	.cav_mag    (cavity),
	.cav_ph     (),
	.error      (error)
);

integer out_cnt=0;
always @(negedge clk) begin
	out_cnt <= (out_cnt + 1) % 4;
	if (|error) begin
		if (fail == 0) $display("first overflow at cycle %d", cc);
		fail = 1;
	end
	if (trace && (out_cnt == 3)) $fwrite(trace_fd, "%d %d %d\n", drive_delta, drive, cavity);
end

endmodule
