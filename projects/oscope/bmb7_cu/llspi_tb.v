`timescale 1ns / 1ns

module llspi_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("llspi.vcd");
		$dumpvars(5,llspi_tb);
	end
	for (cc=0; cc<4000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	//$display("%s", fail ? "FAIL" : "PASS");
end

reg [8:0] host_din;
reg host_we=0;
wire [7:0] host_result;
wire [7:0] status;
reg result_re=0;
wire P2_ADC_CSB_0, P2_ADC_CSB_1, P2_SCLK, P2_ADC_SDIO;
wire P2_POLL_SCLK, P2_POLL_MOSI, P2_AD7794_CSb, P2_AD7794_DOUT;
llspi #(.pace_set(3),.infifo_aw(7)) chip(.clk(clk),
	.P2_DAC_SDO(1'b0),
	.P2_ADC_CSB_0(P2_ADC_CSB_0), .P2_ADC_CSB_1(P2_ADC_CSB_1),
	.P2_SCLK(P2_SCLK), .P2_ADC_SDIO(P2_ADC_SDIO),
	.P2_POLL_SCLK(P2_POLL_SCLK), .P2_POLL_MOSI(P2_POLL_MOSI),
	.P2_AMC7823_SPI_SS(), .P2_AD7794_CSb(P2_AD7794_CSb),
	.P2_AMC7823_SPI_MISO(1'b0), .P2_AD7794_DOUT(P2_AD7794_DOUT),
	.host_din(host_din), .host_we(host_we),
	.status(status),
	.host_result(host_result), .result_re(result_re)
);

always @(negedge clk) if (chip.result_we)
	$display("push result %2x",chip.result);

reg [255:0] file1_name;
integer file1;
initial begin
	if (!$value$plusargs("dfile=%s", file1_name)) file1_name="llspi_in.dat";
	file1 = $fopen(file1_name,"r");
end

integer rc=2;
integer ca, cd;
integer control_cnt=0;
integer wait_horizon=5;
always @(posedge clk) begin
	host_we <= 0;
	host_din <= 9'bx;
	control_cnt <= control_cnt+1;
	if (control_cnt > wait_horizon && control_cnt%3==1 && rc==2) begin
		rc=$fscanf(file1,"%d %x\n",ca,cd);
		if (rc==2) begin
			if (ca == 555) begin
				$display("stall %d cycles",cd);
				wait_horizon = control_cnt + cd;
			end else begin
				$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
				host_din <= cd;
				host_we <= 1;
			end
		end
	end
end

// SPI peripheral
ad9653_sim ad9653(.CSB(P2_ADC_CSB_1), .SCLK_DTP(P2_SCLK), .SDIO_OLM(P2_ADC_SDIO));

// SPI peripheral
ad7794_sim ad7794(.CLK(1'b0), .CS(P2_AD7794_CSb), .DIN(P2_POLL_MOSI), .DOUT_RDY(P2_AD7794_DOUT), .SCLK(P2_POLL_SCLK));


endmodule
