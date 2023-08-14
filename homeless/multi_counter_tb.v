`timescale 1ns / 1ns

module multi_counter_tb;

// Basic setup with clock source
reg clk;
integer cc=0;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("multi_counter.vcd");
		$dumpvars(5, multi_counter_tb);
	end
	for (cc=0; cc<100; cc=cc+1) begin
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

// Stimulus
reg inc=0;  reg[3:0] inc_addr;
always @(posedge clk) case(cc)
	4: begin inc<=1; inc_addr<=4; end
	5: begin inc<=1; inc_addr<=3; end
	10: begin inc<=1; inc_addr<=4; end
	11: begin inc<=1; inc_addr<=4; end
	20: begin inc<=1; inc_addr<=6; end
	25: begin inc<=1; inc_addr<=6; end
	default: begin inc<=0; inc_addr<=4'bx; end
endcase

// Read address sequencing
reg [3:0] read_addr=0;
always @(posedge clk) if ((cc>30) && ((cc%3)==0)) read_addr <= read_addr+1;

// Instantiation of Device Under Test
wire [15:0] read_data;
multi_counter dut(.clk(clk), .inc(inc), .inc_addr(inc_addr),
	.read_addr(read_addr), .read_data(read_data)
);

// Cross-check data read from DUT
reg [3:0] prev_addr=0;
always @(posedge clk) prev_addr <= read_addr;
reg fault=0;
always @(posedge clk) case(prev_addr)
	3: fault <= read_data != 1;
	4: fault <= read_data != 3;
	6: fault <= read_data != 2;
	default: fault <= read_data != 0;
endcase
always @(posedge clk) if (fault) fail <= 1;

endmodule
