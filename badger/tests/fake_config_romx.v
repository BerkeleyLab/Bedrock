// testing substitute for ROM that is often part of our build process
module fake_config_romx(
	input clk,
	input [3:0] address,
	output [15:0] data
);
reg [15:0] dxx = 0;
assign data = dxx;
always @(posedge clk) case(address)
	4'h0: dxx <= 16'h800a;
	4'h1: dxx <= 16'h7334;
	4'h2: dxx <= 16'hb948;
	4'h3: dxx <= 16'hd276;
	4'h4: dxx <= 16'h1ffa;
	4'h5: dxx <= 16'h393e;
	4'h6: dxx <= 16'h8c13;
	4'h7: dxx <= 16'h3a91;
	4'h8: dxx <= 16'hcd35;
	4'h9: dxx <= 16'hfd90;
	4'ha: dxx <= 16'hf6ad;
	4'hb: dxx <= 16'h800a;
	4'hc: dxx <= 16'hac94;
	4'hd: dxx <= 16'h89a3;
	4'he: dxx <= 16'h60ab;
	4'hf: dxx <= 16'h7b8e;
	default: dxx = 0;
endcase
endmodule
