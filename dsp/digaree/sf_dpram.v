// Dual port memory with independent clocks, port B is read-only
// Altera and Xilinx synthesis tools successfully "find" this as block memory
module sf_dpram(
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

(* ram_style = "distributed" *)
reg [dw-1:0] mem[sz:0];
reg [aw-1:0] ala=0, alb=0;

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
