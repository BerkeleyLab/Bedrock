`timescale 1ns / 1ns

module circle_buf_tb;

reg iclk;
integer cc, errors;
`ifdef SIMULATE
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("circle_buf.vcd");
		$dumpvars(5,circle_buf_tb);
	end
	errors = 0;
	for (cc=0; cc<4000; cc=cc+1) begin
		iclk=0; #5;
		iclk=1; #5;
	end
	$display("%d errors", errors);
	if (errors == 0) begin
		$display("PASS");
		$finish(0);
	end else begin
		$display("FAIL");
		$stop();
	end
end
`endif
reg oclk=0;
always begin
	oclk=0; #3;
	oclk=1; #3;
end

// Source emulation
reg [15:0] d_in=0;
reg stb_in=0, boundary=0, stop=0;
always @(posedge iclk) begin
	stb_in <= (cc%4)==2;
	boundary <= cc%8 == 1;  // change to %12 to exercise boundary_ok logic
	stop <= cc==1500 || cc==2200;
	d_in <= cc;
end

// Readout emulation
reg [5:0] read_addr=0;
reg stb_out=0, odata_val=0;
reg [1:0] ocnt=0;
wire enable;
wire otrig=(ocnt==3) & enable;
integer frame=0;
always @(posedge oclk) begin
	ocnt <= ocnt+1;
	if (otrig) read_addr <= read_addr+1;
	if (otrig & (&read_addr)) frame <= frame+1;
	stb_out <= otrig;
	odata_val <= stb_out;
end

// Instantiate Device Under Test
wire [15:0] d_out, buf_stat;
circle_buf #(.aw(6)) dut(.iclk(iclk), .oclk(oclk),
	.d_in(d_in), .stb_in(stb_in), .boundary(boundary),
	.stop(stop),
	.read_addr(read_addr), .d_out(d_out), .stb_out(stb_out),
	.enable(enable), .buf_stat(buf_stat)
);

// Check result
reg [15:0] prev_read=0;
wire [5:0] save_addr=buf_stat[5:0];
wire record_type=buf_stat[15];
reg mismatch=0, fault=0, buffer_mark=0;
always @(posedge oclk) if (odata_val) begin
	prev_read <= d_out;
	mismatch = (d_out != prev_read+4);
	buffer_mark = (save_addr == read_addr) & ~record_type;
	fault = mismatch & ~buffer_mark & (read_addr != 0) & (frame>1);
	if (fault) errors = errors+1;
end

endmodule
