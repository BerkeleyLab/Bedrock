// Hacked to support Ethernet
module crc8e_guts(
	input clk,
	input gate,
	input first,  // set this during the first clock cycle of a new block of data
	input [7:0] d_in,
	output [7:0] d_out,
	output zero
);
// https://en.wikipedia.org/wiki/Cyclic_redundancy_check
parameter wid=32;
parameter init=32'hffffffff;

// Three names are magic to crc_guts.vh:
//   D    data in
//   O    old CRC value
//   crc  new CRC value
reg [wid-1:0] crc=0;
wire [7:0] D = d_in;
wire [wid-1:0] O = first ? init : crc;
always @(posedge clk) if (gate) begin
`include "crc8e_guts.vh"
end
wire [7:0] dr = ~crc[wid-1:wid-8]; // note polarity inversion
assign d_out = {dr[0],dr[1],dr[2],dr[3],dr[4],dr[5],dr[6],dr[7]};
// note bit order reversal

// assign zero = ~(|crc);
assign zero = crc==32'hc704dd7b;
endmodule
