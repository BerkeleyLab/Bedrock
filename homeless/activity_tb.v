`timescale 1ns / 1ns

module activity_tb;

reg clk;
integer cc=0;
initial begin
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<400; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("PASS");
	$finish();
end

reg trigger=0;
always @(posedge clk) case(cc)
	4: trigger<=1;
	20: trigger<=1;
	120: trigger<=1;
	160: trigger<=1;
	default: trigger<=0;
endcase

wire led;
activity #(.cw(6)) mut(.clk(clk), .trigger(trigger), .led(led));

//always @(trigger) $display("%d: trigger %d", cc, trigger);
//always @(mut.arm) $display("%d: arm %d", cc, mut.arm);
  always @(led    ) $display("%d: led %d", cc, led);

endmodule
