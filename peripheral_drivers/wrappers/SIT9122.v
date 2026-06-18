`timescale 1ns / 1ns
module SIT9122 (
	output OE_ST,
	input OUTN,
	input OUTP,
	input oe,
	output clkp,
	output clkn
);
// pin  OUTN is      MGTREFCLK0N_116 bank 116 bus_bmb7_Y4[1]         D5
// pin  OUTP is      MGTREFCLK0P_116 bank 116 bus_bmb7_Y4[0]         D6
// pin OE_ST is        IO_L10P_T1_16 bank  16 bus_bmb7_Y4[2]         C9
assign OE_ST=oe;
assign clkp=OUTP;
assign clkn=OUTN;
//assign OUTN=0;
//assign OUTP=0;
endmodule
