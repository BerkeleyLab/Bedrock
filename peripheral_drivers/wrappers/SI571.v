`timescale 1ns / 1ns
module SI571 (input CLKN,input CLKP,output clkp_out, output clkn_out);
// pin  CLKN is      MGTREFCLK1N_116 bank 116 bus_bmb7_U5[0]         F5
// pin  CLKP is      MGTREFCLK1P_116 bank 116 bus_bmb7_U5[1]         F6
assign clkp_out=CLKP;
assign clkn_out=CLKN;
endmodule
