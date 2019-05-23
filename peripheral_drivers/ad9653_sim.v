// Less ambitious than firmware/rfs/ad9653/ad9653_sim.v
module ad9653_sim(
	input CSB,
	input SCLK_DTP,
	inout SDIO_OLM
);

wire clk = SCLK_DTP;
reg [4:0] state=0;
reg [23:0] sr=0;
reg write_mode=0;
always @(posedge clk) begin
	state <= state+1;
	sr <= {sr[22:0], SDIO_OLM};
	if (state==0) write_mode <= ~SDIO_OLM;
end
always @(negedge CSB) begin
	state=0;
	write_mode=0;
	drive_sdio_r=0;
end

reg drive_sdio_r=0, sdio_odata=0;
always @(negedge clk) begin
	drive_sdio_r <= ~write_mode & (state > 15);
	sdio_odata <= ~state[0]^state[2];  // XXX totally bogus
end
wire drive_sdio = drive_sdio_r & ~CSB;
assign SDIO_OLM = drive_sdio ? sdio_odata : 1'bz;

endmodule
