`timescale 1ns / 1ns

module half_filt_tb;

parameter len=10;
parameter per=28;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("half_filt.vcd");
		$dumpvars(5,half_filt_tb);
	end
	for (cc=0; cc<per*500; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

reg signed [19:0] ind=0, ind0=0;
reg ing=0;
integer noise;
integer nseed=1234;

always @(posedge clk) begin
	// ind <= (cc%16==0) ? ((cc>150) ? -400000 : 0) : 20'bx;
	ind <= 20'bx;
	if (cc%per==0) begin
		noise = $dist_normal(nseed,0,1024);
		ind0 = $floor(200000.0*$sin(cc*0.1296/per)+noise/1024.0+0.5);
		// $display("%d %d",cc,ind0);
		ind <= ind0;
	end
	ing <= (cc%per)<len;
end

wire signed [19:0] outd;
wire outg;
half_filt #(.len(len)) dut(.clk(clk), .reset(1'b0), .ind(ind), .ing(ing), .outd(outd), .outg(outg));

reg outg1=0;
always @(posedge clk) begin
	outg1 <= outg;
end

// always @(negedge clk) $display("%d %d %d %d", ind, ing, outd, outg);
always @(negedge clk) if (outg & ~outg1 & (cc>300)) $display("%d",outd);
endmodule
