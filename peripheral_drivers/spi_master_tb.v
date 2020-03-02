`timescale 1ns / 1ns
module spi_master_tb;

parameter TSCKHALF=3; //tsck is 2^5 time ts
parameter ADDR_WIDTH=16;
parameter DATA_WIDTH=8;

reg clk=0;
// spi_master wires
reg [ADDR_WIDTH-1:0] spi_addr;
wire spi_rw=spi_addr[ADDR_WIDTH-1];
reg [DATA_WIDTH-1:0] spi_data;
wire spi_start;
wire cs, sck;
wire sdo=0;
wire [ADDR_WIDTH-1:0] sdo_addr;
wire [DATA_WIDTH-1:0] spi_rdbk;

initial begin
	if($test$plusargs("vcd")) begin
		$dumpfile("spi_master.vcd");
		$dumpvars(5,spi_master_tb);
	end

	//spi_rw=1;
	spi_addr=16'h8002;
	spi_data=8'h18;
	while ($time<40000) begin
		#10;
	end
	$finish;
end

always #5 clk=~clk; // 100 MHz clk

reg start=0;
//============================================================
// spi start generater
//============================================================
always @(posedge clk) begin
	if ((($time>50)&&($time<100))||(($time>3000)&&($time<3050)))
		start<=1;
	else
		start<=0;
end

wire sdi;
//============================================================
// spi master instantiation
//============================================================
spi_master #(.TSCKHALF(TSCKHALF),.ADDR_WIDTH(ADDR_WIDTH),.DATA_WIDTH(DATA_WIDTH)) spi_port(
	.clk(clk),.spi_start(start),.spi_read(spi_rw),
	.spi_addr(spi_addr),.spi_data(spi_data),
	.cs(cs),.sck(sck),.sdo(sdo),.sdi(sdi),
	.sdo_addr(sdo_addr),.spi_rdbk(spi_rdbk)
);


//============================================================
// strobe_gen instantiation
//============================================================
strobe_gen strobe_gen(
	.I_clk(clk), .I_signal(start), .O_strobe(spi_start)
);

endmodule


