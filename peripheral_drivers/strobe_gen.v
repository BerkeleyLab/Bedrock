`timescale 1ns / 1ns

module strobe_gen #(
	parameter TYPE="RISE_EDGE"
)
(
    input I_clk,
    input I_signal,
    output O_strobe
);
reg [1:0] sig_r;
generate
if (TYPE=="RISE_EDGE")
	initial
		sig_r=2'b0;
else
	initial
		sig_r=2'b11;
endgenerate

always @(posedge I_clk) begin
    sig_r<={sig_r[0],I_signal};
end
assign O_strobe=(sig_r==2'b01);

endmodule
