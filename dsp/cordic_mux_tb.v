`timescale 1ns / 1ns

module cordic_mux_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("cordic_mux.vcd");
		$dumpvars(5,cordic_mux_tb);
	end
	for (cc=0; cc<50; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	$finish();
end

reg [2:0] state=0;
wire iq=state[0];
reg signed [17:0] in_iq, in_xy;
reg signed [18:0] in_ph;
integer ccx;
always @(posedge clk) begin
	ccx <= cc-5;
	state <= state+1;
	in_iq <= 18'bx;
	in_xy <= 18'bx;
	in_ph <= 19'bx;
	case (cc)
	6: in_iq <= 1000;
	7: in_iq <= 2000;
	endcase
	case (cc)
	7: in_xy <= 3000;
	8: begin in_xy <= 4000; in_ph <= 5000; end
	endcase
end

wire signed [17:0] out_iq, out_mp;
cordic_mux dut(.clk(clk), .phase(iq), .in_iq(in_iq), .out_iq(out_iq),
	.in_xy(in_xy), .in_ph(in_ph), .out_mp(out_mp));

endmodule
