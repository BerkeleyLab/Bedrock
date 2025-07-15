`timescale 1ns / 1ns
module ds1822_tb();

reg clk, rst;
integer cc;
integer errors=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("ds1822.vcd");
		$dumpvars(5,ds1822_tb);
	end
	clk=0;
	rst=1;
	#160;
	rst=0;
	for (cc=0; cc<70000; cc=cc+1) begin
		#250; clk=1;
		#250; clk=0;
	end
	if (errors != 0) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

tri1 DS1;
reg [5:0] address=0;
wire [8:0] result;
ds1822_driver #(.cnv_cnt(192), .tck_mask(7)) mut(
	.clk(clk), .rst(rst), .run(1'b1),
	.DS1(DS1),
	.address(address), .result(result)
);

// Emulation of chip
ds1822 chip(DS1);

reg [7:0] want;
always @(address) case (address)
	6'h00: want=8'h00;
	6'h01: want=8'h00;
	6'h02: want=8'hfd;
	6'h03: want=8'hcc;
	6'h04: want=8'hbe;
	6'h05: want=8'hd7;
	6'h06: want=8'h01;
	6'h07: want=8'h4b;
	6'h08: want=8'h46;
	6'h09: want=8'h7f;
	6'h0a: want=8'hff;
	6'h0b: want=8'h09;
	6'h0c: want=8'h10;
	6'h0d: want=8'h55;
	6'h0e: want=8'hff;
	6'h0f: want=8'hff;
	6'h10: want=8'hff;
	6'h11: want=8'h00;
	6'h12: want=8'hfd;
	6'h13: want=8'h33;
	6'h14: want=8'h01;
	6'h15: want=8'h8e;
	6'h16: want=8'h2f;
	6'h17: want=8'he5;
	6'h18: want=8'h08;
	6'h19: want=8'h00;
	6'h1a: want=8'h00;
	6'h1b: want=8'hbe;
	6'h1c: want=8'h00;
	6'h1d: want=8'hfd;
	6'h1e: want=8'hcc;
	6'h1f: want=8'h44;
endcase

// Read out result
reg fault=0;
always @(posedge clk) begin
	if (cc>66000 && cc<66256 && (cc%8==3)) address <= address+1;
	if (cc>66000 && cc<66256 && (cc%8==1)) begin
		fault = result != want;
		if (fault) errors=errors+1;
		if (fault) $display("readout %x %x %x %d", address, result, want, fault);
	end
end

endmodule
