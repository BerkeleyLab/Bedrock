// ctrace is a stripped-down logic analyzer/recorder
// along the lines of Xilinx's ChipScope or Altera's Signaltap.
// Of course it doen't have the tools integration that those
//  proprietary things do.  Maybe it could get hooks in yosys?

// Right now I use it with the barest of start/status/dump interaction with the
// host, communicating over an LBNL localbus.  Trigger logic should always be
// left for the user to synthesize, but it would be nice to add some configurable
// support for pre-trigger buffer management.  There are also fancier ways to
// compress the time axis, and I personally want an enable input that can give
// more flexiblity to time stretching and event capturing.

// "make ctrace_view" will show you the internals of its logic.
// "make ctrace_test1_view" will show the test bench stimulus waveform,
// as captured by ctrace, and converted to VCD by c2vcd.

module ctrace #(
	parameter dw = 8,  // width of data word captured
	parameter tw = 24,  // width of counter word keeping track of time
	parameter aw = 10  // width of address, sets depth of memory
) (
	input clk,
	input [dw-1:0] data,
	// Control in clk domain
	input start,  // single-cycle
	output running,
	output [aw-1:0] pc_mon,
	// Readout in lb_clk domain
	input lb_clk,
	input [aw-1:0] lb_addr,
	output [dw+tw-1:0] lb_out
	// Note that the instantiator could have a problem if dw + tw > 32
);

reg [aw-1:0] pc = 0;
reg running_r = 0;
assign running = running_r;
assign pc_mon = pc;

reg [tw-1:0] count = 0;

reg [dw-1:0] data1 = 0, data2 = 0; // pipeline
reg diff = 0;
reg of = 0;  // counter overflow
wire wen = running_r & (diff | of);
always @(posedge clk) begin
	data1 <= data;
	data2 <= data1;
	diff <= data1 != data;
	if (start) begin
		pc <= 0;
		running_r <= 1;
		count <= 1;
		of <= 0;
	end else if (wen) begin
		count <= 1;
		pc <= pc + 1;
		if (&pc) running_r <= 0;
		of <= 0;
	end else begin
		{of,count} <= count + 1;
	end
end

wire [dw+tw-1:0] saveme = {count, data2};

// Trace memory
dpram #(.dw(dw+tw), .aw(aw)) xmem(
	.clka(clk), .clkb(lb_clk),
	.addra(pc), .dina(saveme), .wena(wen),
	.addrb(lb_addr), .doutb(lb_out)
);

endmodule
