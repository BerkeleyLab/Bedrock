// Synthesizes to 47 slices and 1 MULT18X18 at 166 MHz in XC3Sxxx-4 using XST-9.2.04i
`timescale 1ns / 1ns
`include "freq.vh"
module afterburner(
	input clk,  // timespec 6.0 ns
	input signed [16:0] data,
	output [15:0] data_out0,
	output [15:0] data_out1
);

parameter  coeff=`AFTERBURNER_COEFF;

// concept:  a1  k*(a1+a2)  a2  k*(a2+a3)  a3  ...
// where k = 0.5*sec(theta) = 0.5*sec(2*pi*11/28) = -0.63952
// to handle 55 MHz output at 70 MHz clk (140 MS/s data rate to DAC)

reg signed [17:0] avg=0;
reg signed [16:0] data1=0, data2=0, data3=0;
`ifdef AFTERBURNER_TRIPLE
reg signed [16:0] data4=0;
wire signed [16:0] thru = data4;
`else
wire signed [16:0] thru = data3;
`endif
reg signed [33:0] prod=0;
reg signed [15:0] sat=0;
always @(posedge clk) begin
	data1 <= data;
	data2 <= data1;
	data3 <= data2;
`ifdef AFTERBURNER_TRIPLE
	data4 <= data3;
	avg <= data + data3;
`else
	avg <= data + data1;
`endif
	prod <= avg * coeff;  // scale by 32768
	sat <= (~(|prod[33:31]) | (&prod[33:31])) ? prod[31:16] : {prod[33],{15{~prod[33]}}};
end

// send offset binary to DAC (someone else needs to instantiate the DDR output cells)
assign data_out1=({~thru[16],thru[15:1]});
assign data_out0=({~sat[15],sat[14:0]});

endmodule
