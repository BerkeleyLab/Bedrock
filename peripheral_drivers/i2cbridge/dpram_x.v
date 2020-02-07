// Dual port memory with independent clocks, port B is read-only
// Altera and Xilinx synthesis tools successfully "find" this as block memory
// Experimental, derived from main bedrock dpram
module dpram_x(
	clka, clkb,
	addra, douta, dina, wena,
	addrb, doutb
);
parameter aw=8;
parameter dw=8;
parameter sz=(32'b1<<aw)-1;
parameter initial_load = 0;
parameter initial_file = "";

	input clka, clkb, wena;
	input [aw-1:0] addra, addrb;
	input [dw-1:0] dina;
	output reg [dw-1:0] douta, doutb;

reg [dw-1:0] mem[sz:0];

always @(posedge clka) begin
	douta <= mem[addra];
	if (wena) mem[addra] <= dina;
end
always @(posedge clkb) begin
	doutb <= mem[addrb];
end

initial begin
	if (initial_load) $readmemh(initial_file, mem);
end

endmodule
