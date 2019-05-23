`timescale 1ns / 1ns

// No sign handling here, and the DAC is offset binary.
// So the caller needs to provide offset binary inputs.
module dac_cells(
	clk,
	data0,
	data1,
	dac
);

parameter width=16;

input  clk;
input  [width-1:0] data0;
input  [width-1:0] data1;
output [width-1:0] dac;

wire rst=0;
wire set=0;
wire ce=1;
genvar ix;
generate
	for (ix=0; ix<width; ix=ix+1) begin: out_cell
		// Xilinx XST 12.1 tells me SRTYPE=SYNC is not compatible with DDR_ALIGNMENT=C0 or C1
`ifndef SIMULATE
		ODDR2 #(.DDR_ALIGNMENT("C0"), .INIT(1'b0), .SRTYPE("ASYNC"))
			a(.Q(dac[ix]), .C0(clk), .C1(~clk), .CE(ce), .D0(data0[ix]), .D1(data1[ix]), .S(set), .R(rst));
`endif
	end
endgenerate
`ifdef SIMULATE
reg [width-1:0] r0=0, r1=0, out=0;
initial begin
	#1; out=0;
end
always @(posedge clk) begin
        r0 <= data0;
        r1 <= data1;
end
always @(clk) out <= clk ? data1 : data0;
assign dac = out;
`endif

endmodule
