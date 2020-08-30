module ad5662_lock(
	input clk,
	input tick,  // pacing gate
	input pps_in,  // from GPS
	// host control bus
	input [17:0] host_data,
	input host_write_dac,  // single-cycle gate
	input host_write_cr,  // single-cycle gate
	output spi_busy,
	output [31:0] dsp_status,
	// hardware pins
	output sclk,  // peak rate is half that of input tick
	output [1:0] sync_,
	output sdo
);

parameter count_period = 125000000;

// 4-bit configuration register and its decoding
reg [3:0] config_r=0;
always @(posedge clk) if (host_write_cr) config_r <= host_data;
wire run_request = config_r[0];  // When this is 0, we get
// 100% software compatiblity with simpler (non-lockable) previous behavior.
wire err_sign = config_r[1];
wire [1:0] lock_sel = config_r[3:2];

// Slightly strange, peek at writes to DAC
// I bet I could reduce resource usage if I tried.
reg [15:0] dac_preset_r=0;
always @(posedge clk) if (host_write_dac) dac_preset_r <= host_data;

// Instantiate PLL
wire [15:0] lock_data;
wire lock_send;
wire pps_out;
pps_lock #(.count_period(count_period)) dut(.clk(clk),
	.pps_in(pps_in), .err_sign(err_sign),
	.run_request(run_request), .dac_preset_val(dac_preset_r),
	.dac_data(lock_data), .dac_send(lock_send),
	.dsp_status(dsp_status), .pps_out(pps_out)
);

// Multiplex host and PLL sources
wire [15:0] data = run_request ? lock_data : host_data[15:0];
wire [1:0] sel = run_request ? lock_sel : host_data[17:16];
wire send = run_request ? lock_send : host_write_dac;

// Instantiate SPI driver
wire [1:0] ctl = 0;  // {PD1, PD0}, see fig. 34 of ad5662.pdf
ad5662 #(.nch(2)) wr_dac(.clk(clk), .tick(tick),
	.data(data), .sel(sel),
	.ctl(ctl), .send(send), .busy(spi_busy),
	.sclk(sclk), .sync_(sync_), .sdo(sdo)
);

endmodule
