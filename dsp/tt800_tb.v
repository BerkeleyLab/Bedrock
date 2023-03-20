`timescale 1ns / 1ns

module tt800_tb;

reg clk;
reg trace;
integer cc;
initial begin
	trace = 1; // $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
	        $dumpfile("tt800.vcd");
	        $dumpvars(5,tt800_tb);
	end
	for (cc=0; cc<300; cc=cc+1) begin
	        clk=0; #3;
	        clk=1; #3;
	end
	$finish();
end

// Initialization port
reg [31:0] initv=0;
reg init=0;
reg en=0;

always @(posedge clk) begin
	// 25 initialization cycles, then run
	init <= cc<35;
	en <= (cc>=10 && cc<35) | (cc>47);
	initv <= 32'bx;
	case (cc-9)
	// run the five lines of initial seeds in tt800_ref.c through the following pipe:
	// tr ' ' '\n' | grep . | sed -e "s/0x/32'h/" -e "s/,/;/" | awk '{print "\t" FNR ": initv <=",$0}'
	1: initv <= 32'h95f24dab;
	2: initv <= 32'h0b685215;
	3: initv <= 32'he76ccae7;
	4: initv <= 32'haf3ec239;
	5: initv <= 32'h715fad23;
	6: initv <= 32'h24a590ad;
	7: initv <= 32'h69e4b5ef;
	8: initv <= 32'hbf456141;
	9: initv <= 32'h96bc1b7b;
	10: initv <= 32'ha7bdf825;
	11: initv <= 32'hc1de75b7;
	12: initv <= 32'h8858a9c9;
	13: initv <= 32'h2da87693;
	14: initv <= 32'hb657f9dd;
	15: initv <= 32'hffdc8a9f;
	16: initv <= 32'h8121da71;
	17: initv <= 32'h8b823ecb;
	18: initv <= 32'h885d05f5;
	19: initv <= 32'h4e20cd47;
	20: initv <= 32'h5a9ad5d9;
	21: initv <= 32'h512c0c03;
	22: initv <= 32'hea857ccd;
	23: initv <= 32'h4cc1d30f;
	24: initv <= 32'h8891a8a1;
	25: initv <= 32'ha6b7aadb;
	default: initv <= 32'bx;
	endcase
end

// Device under test
wire [31:0] y;
tt800 tt800(.clk(clk), .en(en), .init(init), .initv(initv), .y(y));

// Trace output
// Only print y shortly after it gets updated
reg printme=0;
always @(posedge clk) printme <= en & ~init;
always @(negedge clk) if (printme & trace) $display("%x", y);

endmodule
