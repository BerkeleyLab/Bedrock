// Software-accessible features for support of digitizer board
// Please keep this as simulatable and portable Verilog!
// Purposefully does not include:
//   adc_test
//   iq_trace
//   slow readout chain (and therefore not adc minmax?)
module digitizer_config(

	// local bus -- minimize or eliminate uses
	input         lb_clk,
	input         lb_strobe,
	input         lb_rd,
	input [23:0]  lb_addr,
	input [31:0]  lb_dout,

	zest_cfg_if.master zif_cfg,

	// clocks for frequency and phase measurement
	input         clk200,

	// llspi physical I/O
	// slightly less physical
	output        rawadc_trig_x,

	// 8 channels high-speed 16-bit parallel ADC data
	input         adc_clk,
	input [127:0] adc_data,

	// outputs to host read register map
	output [31:0] banyan_status,
	output [15:0] phasex_dout,
	output [31:0] phase_status_U2,
	output [31:0] phase_status_U3,
	output [0:0]  phasex_ready,
	output [0:0]  phasex_present,
	output [7:0]  llspi_status,
	output [7:0]  llspi_result,
	output [6:0]  idelay_mirror_val, // special
	output [7:0]  scanner_result_val, // special
	output [31:0] banyan_data, // special
	output [27:0] frequency,
	output [27:0] frequency_4xout,
	output [27:0] frequency_clkout3,
	output [27:0] frequency_dac_dco,
	output [1:0]  clk_status,

	// software-settable
	// adc_clk domain
	(* external *)
	input [31:0] periph_config,    // external
	(* external *)
	input [15:0] bitslip,          // external
	(* external *)
	input [31:0] U15_spi_data_addr_r,   // external
	(* external *)
	input [31:0] U18_spi_data_addr_r,   // external
	(* external *)
	input        U2_clk_reset_r,   // external
	(* external *)
	input        U3_clk_reset_r,   // external
	(* external, signal_type="single-cycle" *)
	input [1:0]   adc_mmcm, // external single-cycle
	(* external *)
	input        U2_iserdes_reset_r, // external
	(* external *)
	input        U3_iserdes_reset_r, // external
	(* external *)
	input        U4_reset_r,         // external
	(* external *)
	input        mmcm_reset_r,       // external
	(* external *)
	input        idelayctrl_reset_r, // external

	// lb_clk domain
	// newad-force lb domain
	(* external, cd="lb" *)
	input [1:0] U15_spi_read_and_start_r,  // external
	(* external, cd="lb" *)
	input [1:0] U18_spi_read_and_start_r,  // external
	(* external, cd="lb" *)
	input [7:0] banyan_mask, // external
	(* external, signal_type="single-cycle", cd="lb" *)
	input phasex_trig, // external single-cycle
	(* external, signal_type="we-strobe", cd="lb" *)
	input llspi_we,  // external we-strobe
	input llspi_re,  // -- external strobe
	(* external, signal_type="we-strobe", cd="lb" *)
	input clk_status_we,  // external we-strobe
	(* external, cd="lb" *)
	input [4:0] scanner_debug, // external
	input autoset_enable,  // -- external
	input scan_trigger,  // -- external single-cycle
	(* external, signal_type="we-strobe", cd="lb" *)
	input scan_trigger_we,  // external we-strobe
	// lb_clk domain, but only because I flag_xdomain to adc_clk
	(* external, signal_type="single-cycle", cd="lb" *)
	input rawadc_trig,  // external single-cycle

	// adc_clk domain
	// newad-force clk1x domain
	(* external *)
	input [9:0] adc_downsample_ratio,  // external
	(* external *)
	input [9:0] sync_ad7794_cset,  // external
	(* external *)
	input [5:0] sync_tps62210_cset  // external
);

assign zif_cfg.U15_sclk_in    = 1'b0;
assign zif_cfg.U15_mosi_in    = 1'b0;
assign zif_cfg.U15_spi_ssb_in = 1'b1;

assign zif_cfg.U18_sclk_in    = zif_cfg.U15_sclk_out;
assign zif_cfg.U18_mosi_in    = zif_cfg.U15_mosi_out;
assign zif_cfg.U18_spi_ssb_in = zif_cfg.U15_spi_ssb_out;
assign zif_cfg.U15_U18_sclk   = zif_cfg.U18_sclk_out;
assign zif_cfg.U15_U18_mosi   = zif_cfg.U18_mosi_out;

assign zif_cfg.U15_clk=lb_clk;
assign zif_cfg.U18_clkin=lb_clk;

// Propagate these (mirrored) host-settable registers to output ports of this module
assign zif_cfg.U15_spi_start = U15_spi_read_and_start_r[0];
assign zif_cfg.U15_spi_read = U15_spi_read_and_start_r[1];
assign zif_cfg.U15_spi_data = U15_spi_data_addr_r[31:16];
assign zif_cfg.U15_spi_addr = U15_spi_data_addr_r[15:0];
assign zif_cfg.U18_spi_start = U18_spi_read_and_start_r[0];
assign zif_cfg.U18_spi_read = U18_spi_read_and_start_r[1];
assign zif_cfg.U18_spi_data = U18_spi_data_addr_r[31:8];
assign zif_cfg.U18_spi_addr = U18_spi_data_addr_r[7:0];
assign zif_cfg.U2_clk_reset = U2_clk_reset_r;
assign zif_cfg.U3_clk_reset = U3_clk_reset_r;

assign zif_cfg.U2_bitslip = bitslip[7:0];
assign zif_cfg.U2_pdwn = periph_config[1];
assign zif_cfg.U3_bitslip = bitslip[15:8];
assign zif_cfg.U3_pdwn = periph_config[1];

assign zif_cfg.U4_reset = U4_reset_r;
assign zif_cfg.U33U1_pwr_en = periph_config[0];
assign zif_cfg.IDELAY_ctrl_rst = idelayctrl_reset_r;

assign zif_cfg.U2_mmcm_reset = mmcm_reset_r;
assign zif_cfg.U2_mmcm_psclk = lb_clk;
assign zif_cfg.U2_mmcm_psen = adc_mmcm[0];
assign zif_cfg.U2_mmcm_psincdec = adc_mmcm[1];
// Maybe no need to attach to U2_mmcm_psdone
assign zif_cfg.U3_mmcm_reset = mmcm_reset_r;
assign zif_cfg.U3_mmcm_psclk = 0;
assign zif_cfg.U3_mmcm_psincdec = 0;
assign zif_cfg.U3_mmcm_psen = 0;
// Do not attach to U3_mmcm_psdone

`define CONFIG_LLSPI
`ifdef CONFIG_LLSPI

assign zif_cfg.U3_sdio_as_i = ~zif_cfg.U27_dir;
assign zif_cfg.U2_sdio_as_i = ~zif_cfg.U27_dir;

assign zif_cfg.U3_sdo = zif_cfg.U2_sdo;
assign zif_cfg.U3_sclk_in = 1'b0;
// DAC (U4) unused for now
assign zif_cfg.U4_sclk_in = 1'b0;
assign zif_cfg.U1_clkuwire_in = 1'b0;

wire [8:0] host_din = lb_dout[8:0];
llspi llspi(
	.clk(lb_clk),
	// Physical FMC pins connected to digitizer board
	.P2_SCLK(zif_cfg.U2_sclk_in),//bus_digitizer_U4[26]),
	.P2_SDI(zif_cfg.U4_sdio_inout),//bus_digitizer_U4[0]),
	.P2_LMK_LEuWire(zif_cfg.U1_leuwire_in),//bus_digitizer_U1[5]),
//    .P2_ADC_SDIO(U23_sdio_inout),//bus_digitizer_U4[1]),
	.sdi(zif_cfg.U2_sdi),
	.sdo(zif_cfg.U2_sdo),
	.P2_ADC_SDIO_DIR(zif_cfg.U27_dir),
	.P2_ADC_CSB_0(zif_cfg.U2_csb_in),//bus_digitizer_U2[22]),
	.P2_ADC_CSB_1(zif_cfg.U3_csb_in),//bus_digitizer_U3[11]),
	.P2_DAC_CSB(zif_cfg.U4_csb_in),//bus_digitizer_U4[19]),
	.P2_DAC_SDO(zif_cfg.U4_sdo_out),//bus_digitizer_U4[12]),
`ifdef POLL_WITH_LLSPI
// Following four llspi outputs can be left unused if
// llspi isn't driving the chips
	.P2_POLL_SCLK(zif_cfg.U18_sclk_in),  // Y5
	.P2_POLL_MOSI(zif_cfg.U18_mosi_in),  // V19
	.P2_AMC7823_SPI_SS(zif_cfg.U15_ss_in),  // AB20
	.P2_AD7794_CSb(zif_cfg.U18_ss_in),  // AE17
`endif
// OK to attach the following two llspi input pins even if
// llspi isn't driving the chips; no floating-input warnings this way
	.P2_AMC7823_SPI_MISO(zif_cfg.U15_miso_out),//bus_digitizer_U15[1]),  // AB19
	.P2_AD7794_DOUT(zif_cfg.U18_miso_out),//bus_digitizer_U18[1]),  // AF17
	// Host write port
	.host_din(host_din),// assign host_din = lb_dout[8:0]),
	.host_we(llspi_we),
	// Status made available to host
	.status(llspi_status),
	// Host read port
	.result_re(llspi_re),
	.host_result(llspi_result)
);
`endif

// MMCM status tracking, should detect if we ever lost clocks since setting up
// status = 0   on reset
// status = 1   set up, frozen
// status = 2   verified with PRNG
reg [1:0] clk_status_r=0;
always @(posedge lb_clk) begin
	if (clk_status_we) begin
		if (lb_dout[0]) clk_status_r <= 1;
		if (lb_dout[1] & (clk_status_r==1)) clk_status_r <= 2;
	end
	if (~zif_cfg.U2_mmcm_locked) clk_status_r <= 0;
end
assign clk_status = clk_status_r;

// Change clock domains for the rawadc_trig command, from lb_clk to adc_clk
flag_xdomain rawadc_trig_xdomain (.clk1(lb_clk), .flagin_clk1(rawadc_trig),
	.clk2(adc_clk), .flagout_clk2(rawadc_trig_x));

// One more clock-domain change, so idelay_scanner can run in pure lb_clk domain
wire [127:0] permuted_data;  // from banyan_mem
wire [15:0] scanner_adc_val = permuted_data[15:0];
reg [15:0] scanner_adc_val_r=0;
always @(posedge lb_clk) scanner_adc_val_r <= scanner_adc_val;

// 16 idelay registers mapped to lb_addr 112-127
// See idelay_base in static_oscope_regmap.json
wire scan_running;
wire [3:0] hw_addr;
wire [4:0] hw_data;
wire hw_strobe;
wire [7:0] scanner_banyan_mask;
wire [2:0] scanner_adc_num;  // not used
wire lb_idelay_write = lb_strobe & ~lb_rd & (lb_addr[23:4] == 20'h19007);
idelay_scanner #(.use_decider(1)) scanner(
	.lb_clk(lb_clk), .lb_addr(lb_addr[3:0]), .lb_data(lb_dout[4:0]),
	.lb_id_write(lb_idelay_write),
	.scan_trigger(scan_trigger), .autoset_enable(autoset_enable),
	.scan_running(scan_running),
	.ro_clk(lb_clk), .ro_addr(lb_addr[10:0]),
	.mirror_val(idelay_mirror_val), .result_val(scanner_result_val),
	.debug_sel(scanner_debug[4]), .debug_addr(scanner_debug[3:0]),
	.hw_addr(hw_addr), .hw_data(hw_data), .hw_strobe(hw_strobe),
	.banyan_mask(scanner_banyan_mask), .adc_num(scanner_adc_num),
	.adc_clk(lb_clk), .adc_val(scanner_adc_val_r)
);

// process the output hw_ bus from idelay_scanner, sending to IDELAYE2
reg [4:0] idelay_hold=0;
reg [3:0] idelay_addr=0;
reg [1:0] idelay_sr=0;
//wire idelay_stb0 = lb_strobe & ~lb_rd &(lb_addr[23:4] == 7);
wire idelay_stb0 = hw_strobe;
// This logic is extra-fake because we don't have access to the clock used by IDELAYE2.
// Just hope we get at least one such edge every two lb_clk periods.
always @(posedge lb_clk) begin
	idelay_sr <= {idelay_sr[0],idelay_stb0};
	if (idelay_stb0) begin
		idelay_addr <= hw_addr;  //   x x A A A A x x
		idelay_hold <= hw_data;  //   x x D D D D x x
		//  idelay_stb0               __--_________
		//  idelay_stb_mask[n]        ______----_____
	end
end
reg [15:0] idelay_stb_mask=0;
genvar ixd;
generate for (ixd=0; ixd<16; ixd=ixd+1) begin: gixd
	always @(posedge lb_clk) idelay_stb_mask[ixd] <= |idelay_sr & (idelay_addr == (15-ixd));
end endgenerate

assign zif_cfg.U2_idelay_ld = idelay_stb_mask[7:0];
assign zif_cfg.U2_idelay_value_in = {8{idelay_hold}};

assign zif_cfg.U3_idelay_ld = idelay_stb_mask[15:8];
assign zif_cfg.U3_idelay_value_in = {8{idelay_hold}};

`define CONFIG_SYNC_GEN
`ifdef CONFIG_SYNC_GEN
// This is sloppy use of clock domains for sync_ad7794_cset and sync_tps62210_cset
sync_generate #(.cw(10), .minc(256)) sync_ad7794(.clk(adc_clk),
	.cset(sync_ad7794_cset), .sync(zif_cfg.U18_adcclk));
sync_generate #(.cw(6), .minc(32)) sync_tps62210(.clk(adc_clk),
	.cset(sync_tps62210_cset), .sync(zif_cfg.U33U1_pwr_sync));
`else
assign zif_cfg.U18_adcclk = 0;
assign zif_cfg.U33U1_pwr_sync = 0;
`endif

freq_count freq_count          (.f_in(zif_cfg.U3_clk_div_bufr), .sysclk(lb_clk), .frequency(frequency));
freq_count freq_count_clk4xout (.f_in(clk200),                  .sysclk(lb_clk), .frequency(frequency_4xout));
freq_count freq_count_clkout3  (.f_in(zif_cfg.U1_clkout),       .sysclk(lb_clk), .frequency(frequency_clkout3));
freq_count freq_count_dac_dco  (.f_in(zif_cfg.U4_dco_clk_out),  .sysclk(lb_clk), .frequency(frequency_dac_dco));

`define CONFIG_PHASEX
`ifdef CONFIG_PHASEX
assign phasex_present = 1;
phasex #(.aw(10)) phasex(.uclk1(zif_cfg.U2_clk_div_bufg), .uclk2(zif_cfg.U3_clk_div_bufr), .sclk(clk200),
	.rclk(lb_clk), .trig(phasex_trig), .ready(phasex_ready),
	.addr(lb_addr[9:0]), .dout(phasex_dout));
`else
assign phasex_present = 0;
assign phasex_ready = 0;
assign phasex_dout = 0;
`endif

// iserdes_reset, clk_div_in, and dco_clk_out are "special snowflakes"
// U3 needs two of them, since its ad9653 instantiation is configured with BANK_CNT = 2
assign zif_cfg.U3_iserdes_reset[0] = U3_iserdes_reset_r;
assign zif_cfg.U3_iserdes_reset[1] = U2_iserdes_reset_r;
assign zif_cfg.U2_iserdes_reset = U2_iserdes_reset_r;
assign zif_cfg.U3_clk_div_in[0] = zif_cfg.U3_clk_div_bufr;
assign zif_cfg.U3_clk_div_in[1] = zif_cfg.U2_clk_div_bufr;
assign zif_cfg.U2_clk_div_in = zif_cfg.U2_clk_div_bufr;
assign zif_cfg.U3_dco_clk_in[0] = zif_cfg.U3_dco_clk_out;
assign zif_cfg.U3_dco_clk_in[1] = zif_cfg.U2_dco_clk_out;
assign zif_cfg.U2_dco_clk_in = zif_cfg.U2_dco_clk_out;

`define CONFIG_PHASE_DIFF
`ifdef CONFIG_PHASE_DIFF
wire err_ff_U2, err_ff_U3;
wire [12:0] phdiff_out_U2, phdiff_out_U3;
wire [13:0] vfreq_out_U2, vfreq_out_U3;
// Measure the phases of the two BUFR outputs relative to adc_clk (U2's BUFR after MMCM and BUFG)
phase_diff #(.delta(33)) phase_diff_U2(.uclk1(zif_cfg.U2_clk_div_bufg), .uclk2(zif_cfg.U2_clk_div_bufr), .uclk2g(1'b1), .sclk(clk200),
	.rclk(lb_clk), .phdiff_out(phdiff_out_U2), .vfreq_out(vfreq_out_U2), .err_ff(err_ff_U2));
phase_diff #(.delta(33)) phase_diff_U3(.uclk1(zif_cfg.U2_clk_div_bufg), .uclk2(zif_cfg.U3_clk_div_bufr), .uclk2g(1'b1), .sclk(clk200),
	.rclk(lb_clk), .phdiff_out(phdiff_out_U3), .vfreq_out(vfreq_out_U3), .err_ff(err_ff_U3));
assign phase_status_U2 = {err_ff_U2, vfreq_out_U2, 4'b0, phdiff_out_U2};
assign phase_status_U3 = {err_ff_U3, vfreq_out_U3, 4'b0, phdiff_out_U3};
`else
assign phase_status_U2 = 0;
assign phase_status_U3 = 0;
`endif

`define CONFIG_BANYAN
`ifdef CONFIG_BANYAN
// Banyan-routed memory, that features a simple one-shot fill.
// Use rawadc_trig for a direct asynchronous fill, or rawadc_trig_req
// to start filling at the next external trigger (ext_trig).
parameter banyan_aw = 14;  // 8 blocks of RAM, each 16K x 16
reg banyan_run=0, banyan_run_d=0;
wire rollover, full;
wire [banyan_aw+3-1:0] pointer;
always @(posedge adc_clk) begin
	if (rawadc_trig_x | rollover) banyan_run <= rawadc_trig_x;
	banyan_run_d <= banyan_run;
end
// Control routed through idelay_scanner
reg [7:0] actual_banyan_mask=0;
always @(posedge lb_clk) actual_banyan_mask <= scan_running ? scanner_banyan_mask : banyan_mask;
// banyan_mask must be provided to banyan_mem in the adc_clk domain, otherwise the
// synthesizer will rightfully complain that timing analysis is impossible.
reg [7:0] banyan_mask_x=0;
always @(posedge adc_clk) banyan_mask_x <= actual_banyan_mask;


// Pass adc_data through a moving average filter
wire [7: 0] adc_data_valid;
wire [8*16-1:0] adc_data_decimated;
genvar ix;
generate for (ix=0; ix<8; ix=ix+1) begin: mavg_set
        moving_average mavg(.o(adc_data_decimated[(ix+1)*16-1 -: 16]),
		       .data_valid(adc_data_valid[ix]),
		       .log_downsample_ratio(adc_downsample_ratio[4:0]),
		       .clk(adc_clk),
		       .rst(1'b0),
		       .i(          adc_data[(ix+1)*16-1 -: 16])
	);
end endgenerate

//wire [127:0] banyan_adc = {U2DD, U2DC, U2DB, U2DA, U3DD, U3DC, U3DB, U3DA};
banyan_mem #(.aw(banyan_aw), .dw(16)) banyan_mem(.clk(adc_clk),
	.adc_data(adc_data_decimated), .banyan_mask(banyan_mask_x),
	.reset(rawadc_trig_x), .run(banyan_run & adc_data_valid[0]),
	.pointer(pointer), .rollover(rollover), .full(full),
	.permuted_data(permuted_data),
	.ro_clk(lb_clk), .ro_addr(lb_addr[banyan_aw+3-1:0]), .ro_data(banyan_data[15:0]), .ro_data2(banyan_data[31:16])
);
// Output status can be expected to cross clock domains.
// pointer readout is only intended to be valid if ~banyan_run.
// Stretch the reported run signal to guarantee that validity rule.
wire banyan_run_s = banyan_run_d | banyan_run;
wire [5:0] banyan_aw_fix = banyan_aw;
wire [19:0] pointer_fix = pointer;
// Abuse this register a little by adding the idelay_scanner status.
// Not so bad, because that scanner depends on data provided by the banyan switch.
/// banyan_status = {banyan_run_s (1'b), full (1'b), banyan_aw_fix (6'b), 2'b0, autoset_enable (1'b), scan_running (1'b), pointer_fix (20'b)};
assign banyan_status = {banyan_run_s, full, banyan_aw_fix, 2'b0, autoset_enable, scan_running, pointer_fix};
`else
assign banyan_status = 0;
assign banyan_data = 0;
assign permuted_data = 0;
`endif

endmodule
