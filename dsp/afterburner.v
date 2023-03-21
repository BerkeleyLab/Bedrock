// Synthesizes to 47 slices and 1 MULT18X18 at 166 MHz in XC3Sxxx-4 using XST-9.2.04i
//  Use parameter triple instead of preprocessor variable AFTERBURNER_TRIPLE
//  User port coeff instead of parameter coeff
// If the port coeff is set to a constant value, should synthesize identically
// There is a latency of 3 clock cycles (??)
// Note: The output of the module is Offset Binary
// [It is perhaps stupid to have that here and it should be moved into another module]

// CONCEPT: The mid point along the circle of a of 2 complex numbers that already lie
//          on a circle is not a plain average. To obtain the (real/imaginary) component
//          of this mid-point one has to multiply by what is called "coeff"
//          k = 0.5*sec(theta) .. where theta is the angle between the complex numbers

`timescale 1ns / 1ns
module afterburner(
	input clk,  // timespec 6.0 ns
	input signed [16:0] data,  // This is level set data [.. a_n1, a_n2 ..]
	input signed [15:0] coeff, // Coefficient to correct for  interpolation
	output [15:0] data_out0,   // Interpolated [coeff*[..(a_n1+a_n2), (a_n2+a_n3),..]]
	output [15:0] data_out1    // Untouched    [.. a_n1, a_n2 ..]
);

parameter triple=0;

// concept:  a1  k*(a1+a2)  a2  k*(a2+a3)  a3  ...
// where k = 0.5*sec(theta) = 0.5*sec(2*pi*11/28) = -0.63952
// to handle 55 MHz output at 70 MHz clk (140 MS/s data rate to DAC)

// num = 2  % or 8 for L-band
// den = 11
// coeff = floor(32768*0.5*sec(pi*num/den)+0.5)
// 19476  % or -25019 for L-band

reg signed [17:0] avg=0;
reg signed [16:0] data1=0, data2=0, data3=0, data4=0;
wire signed [16:0] thru = triple ? data4 : data3;
reg signed [33:0] prod=0;
reg signed [15:0] sat=0;
always @(posedge clk) begin
	data1 <= data;
	data2 <= data1;
	data3 <= data2;
	data4 <= data3;
	avg <= data + (triple ? data3 : data1);
	prod <= avg * coeff;  // scale by 32768
	sat <= (~(|prod[33:31]) | (&prod[33:31])) ? prod[31:16] : {prod[33],{15{~prod[33]}}};
end

// send offset binary to DAC (someone else needs to instantiate the DDR output cells)
assign data_out0 = ({~sat[15], sat[14:0]});
assign data_out1 = ({~thru[16], thru[15:1]});

endmodule
