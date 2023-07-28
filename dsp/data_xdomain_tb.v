`timescale 1ns / 10ps

module data_xdomain_tb;

reg clk1;
integer cc1;
reg fail=0;
integer npt=2000;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("data_xdomain.vcd");
		$dumpvars(5,data_xdomain_tb);
	end
	for (cc1=0; cc1<(npt*2); cc1=cc1+1) begin
		clk1=0; #4;
		clk1=1; #4;
	end
	$display("After %d clk1 cycles, # of errors: %d", cc1, err_cnt);
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end

reg clk2;
integer cc2;
always begin
	clk2=0; #4.72;
	clk2=1; #4.72;
end

reg [15:0] cnt=0;
reg [15:0] cnt_in=0;
reg [15:0] data_in=16'hffff;
always @(posedge clk1) begin
	cnt <= cnt+1;
	data_in <= $random;
end

wire gate_out1;
wire gate_in1=(cnt[2:0]==1);
wire [15:0] data_out1;
data_xdomain one2two(.clk_in(clk1), .gate_in(gate_in1), .data_in(data_in),
	.clk_out(clk2), .gate_out(gate_out1), .data_out(data_out1));

wire gate_out2;
wire [15:0] data_out2;
data_xdomain two2one(.clk_in(clk2), .gate_in(gate_out1), .data_in(data_out1),
	.clk_out(clk1), .gate_out(gate_out2), .data_out(data_out2));

//Memories for data and time stamps (clock1 cycles)
reg [15:0] data_in_array [19:0];
reg [15:0] count_stamp [19:0];
reg [15:0] count_delay=5'b0;
reg [4:0] index_in=0;
reg [4:0] index_out=0;
reg gate_out2_d=1'b0;
reg match_found=1'b0;
reg check_en=1'b0;
reg [16:0] err_cnt=0;
always @(posedge clk1) begin
	if(gate_in1) begin
		data_in_array[index_in] <= data_in;
		index_in <= (index_in==19) ? 0 : index_in+1;
		count_stamp[index_in] <= cnt;
	end
	gate_out2_d <= gate_out2;
	if(gate_out2) begin
		check_en <= 1'b1;
		if(data_in_array[index_out]==data_out2) begin
			index_out <= (index_out==19) ? 0 : index_out+1;
			count_delay <= cnt-count_stamp[index_out];
			match_found <= 1'b1;
		end else match_found <= 1'b0;
	end
	if(gate_out2_d&&check_en&&~match_found) begin
		fail <= 1'b1;
		err_cnt <= err_cnt + 1;
	end
end

wire [15:0] delay=count_delay;

//always @(posedge clk1) if (gate_in1) $display("in %x",data_in);
//always @(posedge clk2) if (gate_out1) $display("out %x",data_out1);
//always @(posedge clk1) if (gate_out2_d) $display("delay %x",delay);

endmodule
