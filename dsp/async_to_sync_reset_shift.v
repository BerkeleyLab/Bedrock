module async_to_sync_reset_shift(clk,Pinput,Poutput);
input clk;
input Pinput;
output Poutput;
parameter LENGTH =8;
parameter INPUT_POLARITY = 1'b1;
parameter OUTPUT_POLARITY= 1'b1;

reg [LENGTH-1:0] shift=0;
always @(Pinput or (clk)) begin
	if ( Pinput == INPUT_POLARITY ) begin
		shift <= {LENGTH{OUTPUT_POLARITY}};
	end
	else if (clk) begin
		shift <= {shift[LENGTH-2:0], ~OUTPUT_POLARITY};
	end
end
// Output the result on edge - helps to meet timing
//always @(posedge clk) begin
//  Poutput <= shift[LENGTH-1];
//end
assign Poutput=shift[LENGTH-1];
endmodule
