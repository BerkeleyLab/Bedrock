`timescale 1ns / 1ns

module fake_dpram_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("fake_dpram.vcd");
		$dumpvars(5,fake_dpram_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<120; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("PASS");
	$finish();
end

parameter aw=4;
parameter dw=5;
reg [aw-1:0] addr1, addr2;
reg [dw-1:0] din1, din2;
reg wen1=0, ren1=0, wen2=0, ren2=0;
integer jx=0;

// Create port 1 signals
always @(posedge clk) begin
	wen1 <= 0;
	ren1 <= 0;
	din1 <= {dw{1'bx}};
	addr1 <= {aw{1'bx}};
	if ((cc < 30) && ((cc%3)==2)) begin
		wen1 <= 1;
		din1 <= cc;
		addr1 <= cc/3;
	end
	if ((cc > 70) && (cc < 90) && ((cc%3)==2)) begin
		ren1 <= 1;
		addr1 <= cc/3;
	end
end

// Create port 2 write signals
always @(posedge clk) begin
	wen2 <= 0;
	ren2 <= 0;
	din2 <= {dw{1'bx}};
	addr2 <= {aw{1'bx}};
	if ((cc > 20) && (cc < 45) && ((cc%3)==2)) begin
		wen2 <= 1;
		din2 <= cc+10;
		addr2 <= 2+cc/3;
	end
	if ((cc > 80) && (cc < 100) && ((cc%2)==1)) begin
		ren2 <= 1;
		addr2 <= 6+cc/2;
	end
end

wire [dw-1:0] dout1, dout2;
wire error;
fake_dpram #(.aw(aw), .dw(dw)) dut (
	.clk(clk),
	.addr1(addr1), .din1(din1), .dout1(dout1), .wen1(wen1), .ren1(ren1),
	.addr2(addr2), .din2(din2), .dout2(dout2), .wen2(wen2), .ren2(ren2),
	.error(error)
);

endmodule
