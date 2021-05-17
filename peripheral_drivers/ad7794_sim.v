module  ad7794_sim
(input CLK,input CS,input DIN,output DOUT_RDY,input SCLK
);
// pin   ss is        IO_L18N_T2_32 bank  32 bus_digitizer_U15[2]       AB20
// pin  miso is        IO_L18P_T2_32 bank  32 bus_digitizer_U15[1]       AB19
// pin  mosi is        IO_L23N_T3_32 bank  32 bus_digitizer_U18[3]        V19
// pin  sclk is        IO_L17N_T2_34 bank  34 bus_digitizer_U18[4]         Y5
reg [31:0] value=0;
reg [31:0] value_sr=0;
always @(negedge SCLK or posedge CS) begin
	if (CS) begin
           value <= value + 1;
           value_sr <= value;
	end else if (~CS) value_sr <= {value_sr[30:0], 1'b0};
end
reg [31:0] shifter;
always @(posedge SCLK) begin
	if (~CS) shifter <= {shifter,DIN};
end
always @(negedge CS) shifter <= {32{1'bx}};
always @(posedge CS) begin
	$display("AD7794 simulator received word %8x",shifter);
	$fflush();
end
assign DOUT_RDY = CS ? 1'bz : value_sr[31];

endmodule
