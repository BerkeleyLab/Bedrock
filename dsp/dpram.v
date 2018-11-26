`timescale 1ns / 1ns
// Dual port memory with independent clocks, port B is read-only
// Altera and Xilinx synthesis tools successfully "find" this as block memory
module dpram(
	clka, clkb,
	addra, douta, dina, wena,
	addrb, doutb
);
parameter aw=8;
parameter dw=8;
parameter sz=(32'b1<<aw)-1;
	input clka, clkb, wena;
	input [aw-1:0] addra, addrb;
	input [dw-1:0] dina;
	output [dw-1:0] douta, doutb;

reg [dw-1:0] mem[sz:0];
reg [aw-1:0] ala=0, alb=0;

// In principle this should work OK for synthesis, but
// there seems to be a bug in the Xilinx synthesizer
// triggered when k briefly becomes sz+1.
`ifdef SIMULATE
integer k=0;
initial
begin
	for (k=0;k<sz+1;k=k+1)
	begin
		mem[k]=0;
	end
end
`endif

assign douta = mem[ala];
assign doutb = mem[alb];
always @(posedge clka) begin
	ala <= addra;
	if (wena) mem[addra]<=dina;
end
always @(posedge clkb) begin
	alb <= addrb;
end

endmodule
