module offline(
	input clk,
	output rx_dv,
	output [7:0] rxd,
	output [7:0] goal,
	output [15:0] count
);

integer fd;
reg [1023:0] packet_file;  // file name, fragile! limited to 128 characters
initial begin
	fd = 0;
	if ($value$plusargs("packet_file=%s", packet_file)) begin
		fd = $fopen(packet_file, "r");
	end
end

// Create flow of packets
reg [7:0] eth_in=0;
reg eth_in_s=0;
integer ifg=12;
reg [7:0] goal_r;
reg [15:0] test_count_goal=0;
integer rc, hexin;
always @(posedge clk) begin
	eth_in <= 8'hxx;
	eth_in_s <= 0;
	if (ifg > 0) begin
		ifg = ifg-1;
	end else begin
		rc = $fscanf(fd, "%2x\n", hexin);
		// $display("rc1 %d %x", rc, hexin);
		if (rc==1) begin
			eth_in <= hexin;
			eth_in_s <= 1;
		end else begin
			rc = $fscanf(fd, "stop %x\n", hexin);
			// $display("rc2 %d %x", rc, hexin);
			if (rc==1) begin
				ifg = 12;
				goal_r <= hexin;
			end else begin
				rc = $fscanf(fd, "tests %d\n", hexin);
				// $display("rc3 %d %x", rc, hexin);
				if (rc==1) begin
					test_count_goal <= hexin;
				end
			end
		end
	end
end
assign rxd = eth_in;
assign rx_dv = eth_in_s;
assign goal = goal_r;
assign count = test_count_goal;

endmodule
