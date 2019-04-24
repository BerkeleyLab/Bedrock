module CDCE62005 (input U0N,input U0P,output U0P_out,output U0N_out);
// pin   U0N is      MGTREFCLK1N_115 bank 115 bus_bmb7_U19[1]         K5
// pin   U0P is      MGTREFCLK1P_115 bank 115 bus_bmb7_U19[0]         K6
//assign U0N=0;
//assign U0P=0;
assign U0P_out=U0P;
assign U0N_out=U0N;
endmodule
