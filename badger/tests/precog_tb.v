`timescale 1ns / 1ns

module precog_tb;

reg clk;
integer cc=0;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("precog.vcd");
		$dumpvars(5,precog_tb);
	end
	while (1) begin
		cc = cc + 1;
		clk=0; #5;
		clk=1; #5;
	end
end

wire clear_to_send;
reg request_to_send = 0;
reg [10:0] tx_packet_width;
reg scanner_busy = 1;
localparam LATENCY = 10;

precog #(
	.PAW                (11),
	.LATENCY            (LATENCY)
) dut (
	.clk                (clk),
	.tx_packet_width    (tx_packet_width),
	.scanner_busy       (scanner_busy),
	.request_to_send      (request_to_send),
	.clear_to_send      (clear_to_send)
);

task generate_gap;
	input [10:0] gap_width;
	input expected_output;
	begin
		// produce the gap
		@(posedge clk);
		request_to_send <= 1;
		@(posedge clk);
		request_to_send <= 0;
		scanner_busy <= 0;
		repeat (gap_width) @(posedge clk) if (clear_to_send) fail = 1;
		scanner_busy <= 1;
		// wait for LATENCY
		repeat (LATENCY - gap_width) @(posedge clk) if (clear_to_send) fail = 1;
		// Output should be high now (if the gap was large enough)
		repeat (tx_packet_width) @(posedge clk) if (clear_to_send != expected_output) fail = 1;
		// Output should go low again after tx_packet_width cycles
		repeat (10) @(posedge clk) if (clear_to_send) fail = 1;
	end
endtask

initial begin
	tx_packet_width = 5;
	// Produce some gaps which are too narrow
	generate_gap(1, 0);
	generate_gap(2, 0);
	generate_gap(3, 0);
	generate_gap(4, 0);
	// Produce some gaps which are wide enough
	generate_gap(5, 1);
	generate_gap(6, 1);
	// Another narrow one
	tx_packet_width = 7;
	generate_gap(6, 0);
	generate_gap(7, 1);
	// tx_packet_width must be <= LATENCY - 2
	tx_packet_width = 8;
	generate_gap(8, 1);
	generate_gap(9, 1);
	// What happens on IDLE line?
	request_to_send <= 1;
	scanner_busy <= 0;
	repeat (100) @(posedge clk);
	scanner_busy <= 1;
	repeat (10) @(posedge clk);
	$display("%s", fail ? "FAIL" : "PASS");
	if (fail) $stop();
	$finish();
end

endmodule
