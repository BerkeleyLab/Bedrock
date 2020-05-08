`timescale 1ns / 1ns

// Generic MSB-first SPI master
module spi_eater(
	input clk,
	input pace,  // free-running version of SCK
	// to hardware, but see below
	output sclk,
	output mosi,
	input miso,
	output [5:0] ctl_bits,
	// from request FIFO
	input [8:0] fdata,
	input empty,
	output pull_fifo,
	// to result FIFO
	output [7:0] result,
	output result_we
);

// fdata is either 8 bits of Tx data,
// or 8 bits of "control".
// some dedicated bits of control set
//  fdata[7]   enable read from hardware to output FIFO
//  fdata[6]   select alternate I/O pins
// The remaining bits can be decoded outside this module
// for up to 63 devices (although probably fewer in LCLS-II digitizer
// case, when bits get stolen to control external buffer direction).

reg old_pace = 0;
wire tick1 = ~pace &  old_pace;  // rising edge
wire tick2 =  pace & ~old_pace;  // falling edge
reg pull_fifo_r = 0, mode=0, running=0;
reg [2:0] bit_cnt = 0;
reg [7:0] shift_reg = 0;
reg [7:0] ctrl_reg = 0;
wire want_another = mode | (bit_cnt==7);
reg push_result=0;
reg miso_hold=0;
always @(posedge clk) begin
	old_pace <= pace;
	pull_fifo_r <= tick1 & ~empty & want_another;
	if (tick2) miso_hold <= miso;
	if (tick1 & want_another) running <= ~empty;
	if (tick1 & want_another & ~empty ) mode <= fdata[8];
	if (tick1) shift_reg <= {shift_reg[6:0],miso_hold};
	if (tick1 & want_another & ~empty & ~fdata[8]) shift_reg <= fdata[7:0];
	if (tick1 & want_another & ~empty &  fdata[8]) ctrl_reg <= fdata[7:0];
	if (tick1 & ~mode) bit_cnt <= bit_cnt+1;
	push_result <= tick1 & ctrl_reg[7] & ~mode & (bit_cnt==7);
end
assign pull_fifo = pull_fifo_r;
assign result_we = push_result;
assign result = shift_reg;

// IOB latches are not included here;
// the user is urged to add them, maybe after
// another layer of decode in the case of ctl_bits.
assign sclk = running & ~mode & old_pace;
assign mosi = shift_reg[7];
assign ctl_bits = ctrl_reg[5:0];

endmodule
