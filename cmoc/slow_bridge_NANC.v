`timescale 1ns / 1ns

module slow_bridge_NANC #(
    parameter aw=8,
    parameter dw=32
) (
	// 32-bit local bus (slave)
	input lb_clk,
	input [14:0] lb_addr,
	input lb_read,
	output [dw-1:0] lb_out,
	// Output status bit, valid in slow_clk domain
	output     slow_invalid,   // indicates internal data transfer in progress
	// 8-bit shift-register port (master)
	input      slow_clk,
	output     slow_op,
	input      slow_snap,
	input [dw-1:0] slow_out
);

reg running=0, shifting=0;
reg [8:0] write_addr=0;
always @(posedge slow_clk) begin
	if (slow_snap | &write_addr) running <= slow_snap;
	if (running) write_addr <= write_addr+1;
	shifting <= running & |write_addr[8:4];
end

wire [dw-1:0] ram_out;
dpram #(.aw(aw), .dw(dw)) ram(.clka(slow_clk), .clkb(lb_clk),
	.addra(write_addr), .dina(slow_out), .wena(running),
	.addrb(lb_addr[aw-1:0]), .doutb(ram_out));

assign lb_out = ram_out;  // pad from 8 to 32 bits?
assign slow_op = slow_snap | shifting;
assign slow_invalid = running;

endmodule
