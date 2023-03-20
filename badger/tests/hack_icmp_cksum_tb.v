`timescale 1ns / 1ns

module hack_icmp_cksum_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("hack_icmp_cksum.vcd");
		$dumpvars(5,hack_icmp_cksum_tb);
	end
	for (cc=0; cc<100; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish();
	end
end

// Stimulus
reg [7:0] idat;
reg kick=0;
always @(posedge clk) begin
	kick <= 0;
	idat <= 8'bx;
	case(cc)
		3: idat <= 4;
		4: idat <= 5;
		13: idat <= 4;
		14: begin idat <= 5; kick <= 1; end
		22: idat <= 3;
		23: idat <= 4;
		24: begin idat <= 5; kick <= 1; end
		25: idat <= 6;
		32: idat <= 3;
		33: idat <= 8'hff;
		34: begin idat <= 8'hfd; kick <= 1; end
		35: idat <= 6;
		42: idat <= 3;
		43: idat <= 8'hff;
		44: begin idat <= 8'hff; kick <= 1; end
		45: idat <= 6;
		52: idat <= 93;
		53: idat <= 8'h00;
		54: begin idat <= 8'h01; kick <= 1; end
		55: idat <= 86;
		62: idat <= 42;
		63: idat <= 8'hf8;
		64: begin idat <= 8'h01; kick <= 1; end
		65: idat <= 21;
		72: idat <= 8'hff;
		73: idat <= 8'hff;
		74: begin idat <= 8'hff; kick <= 1; end
		75: idat <= 8'hff;
	endcase
end

// DUT
wire [7:0] odat;
hack_icmp_cksum dut(.clk(clk), .kick(kick), .idat(idat), .odat(odat));

reg [7:0] idat1, idat2, idat3, odat1;
reg kick1=0, kick2=0;
always @(posedge clk) begin
	idat1 <= idat;
	idat2 <= idat1;
	idat3 <= idat2;
	odat1 <= odat;
	kick1 <= kick;
	kick2 <= kick1;
end

reg [15:0] oldv, have;
integer want;
reg fault;
always @(negedge clk) if (kick2) begin
	have = {odat1, odat};
	oldv = {idat3, idat2};
	want = 16'hffff - oldv;  // recover original sum
	want = want - 16'h0800;  // subtract
	if (want< 0) want = want + 16'hffff;  // fix borrow
	want = 16'hffff - want; // one's complement
	fault = have != want;
	if (fault) fail = 1;
	$display("%4x %4x %4x %s", oldv, have, want, fault ? "FAULT" : "   OK");
end

endmodule
