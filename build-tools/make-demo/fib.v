// Fibonacci series demo
module fib(
	input clk,
	input rst,
	output [15:0] data
);

reg [15:0] s1, s2;
always @(posedge clk) if (rst) begin
	s1 <= 1;
	s2 <= 1;
end else begin
	s1 <= s1 + s2;
	s2 <= s1;
end
assign data = s2;

endmodule
