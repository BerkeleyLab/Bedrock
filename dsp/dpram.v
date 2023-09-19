`timescale 1ns / 1ns
// Dual port memory with independent clocks, port B is read-only
// Altera and Xilinx synthesis tools successfully "find" this as block memory
module dpram #(
	parameter aw=8,
	parameter dw=8,
	parameter initial_file = ""
) (
	input clka,
	input clkb,
	input [aw-1:0] addra,
	output [dw-1:0] douta,
	input [dw-1:0] dina,
	input wena,
	input [aw-1:0] addrb,
	output [dw-1:0] doutb
);
localparam sz=32'b1<<aw;

reg [dw-1:0] mem[0:sz-1];
reg [aw-1:0] ala=0, alb=0;

// In principle the zeroing loop should work OK for synthesis, but
// there seems to be a bug in the Xilinx synthesizer
// triggered when k briefly becomes sz.
integer k=0;
initial begin
	if (initial_file != "") $readmemh(initial_file, mem);
`ifdef SIMULATE
	else begin
		for (k=0;k<sz;k=k+1) mem[k]=0;
	end
`endif
end

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
