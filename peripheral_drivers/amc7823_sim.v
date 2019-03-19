module  amc7823_sim
(input ss,output miso,input mosi,input sclk
);
// pin   ss is        IO_L18N_T2_32 bank  32 bus_digitizer_U15[2]       AB20
// pin  miso is        IO_L18P_T2_32 bank  32 bus_digitizer_U15[1]       AB19
// pin  mosi is        IO_L23N_T3_32 bank  32 bus_digitizer_U18[3]        V19
// pin  sclk is        IO_L17N_T2_34 bank  34 bus_digitizer_U18[4]         Y5
reg value=0;
always @(posedge sclk) begin
	value=~value;
end
assign miso=value;

endmodule
