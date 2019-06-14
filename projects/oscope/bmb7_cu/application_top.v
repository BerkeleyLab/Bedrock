`define LB_DECODE_application_top

`include "application_top_auto.vh"

module application_top(
	input bmb7_U7_clkout,
	input bmb7_U7_clk4xout,
	output [7:0] port_50006_word_k7tos6,
	input [7:0] port_50006_word_s6tok7,
	output port_50006_tx_available,
	input port_50006_rx_available,
	output port_50006_tx_complete,
	input port_50006_rx_complete,
	input port_50006_word_read,
	output [7:0] port_50007_word_k7tos6,
	input [7:0] port_50007_word_s6tok7,
	input port_50007_tx_available,
	input port_50007_rx_available,
	input port_50007_tx_complete,
	input port_50007_rx_complete,
	input port_50007_word_read,
	input s6_to_k7_clk_out,

	output clk200,
	input idelayctrl_rdy,
	output idelayctrl_reset,
	input [63:0] U2_dout,
	input [63:0] U3_dout,
	input U2_clk_div_bufg,
	input U3_clk_div_bufg,  // purposefully unused
	input U2_clk_div_bufr,
	input U3_clk_div_bufr,
	input U2_dco_clk_out,
	input U3_dco_clk_out,
	output [39:0] U2_idelay_value_in,
	output [39:0] U3_idelay_value_in,
	input [39:0] U2_idelay_value_out,
	input [39:0] U3_idelay_value_out,
	output [7:0] U2_bitslip,
	output [7:0] U3_bitslip,
	output [7:0] U2_idelay_ld,
	output [7:0] U3_idelay_ld,
	output U2_pdwn,
	output U3_pdwn,
	output U2_iserdes_reset,
	output U3_iserdes_reset,

	output U2_clk_reset,
	output U3_clk_reset,
	output mmcm_reset,
	input mmcm_locked,

	output U2_mmcm_psclk,
	output U2_mmcm_psen,
	output U2_mmcm_psincdec,
	input U2_mmcm_psdone,

	output U3_mmcm_psclk,
	output U3_mmcm_psen,
	output U3_mmcm_psincdec,
	input U3_mmcm_psdone,

	input U1_clkout3,
	input U4_dco_clk_out,
	output U4_dci,
	output U4_reset,
	output [13:0] U4_data_i,
	output [13:0] U4_data_q,
	output [2:0] D4rgb,
	output [2:0] D5rgb,
	output U27dir,
	inout [3:0] J17_pmod_4321,   // top row of pins,       J17_pmod_4321[3] next to ground pin
	inout [3:0] J17_pmod_a987,   // row adjacent to board, J17_pmod_a987[3] next to ground pin
	inout [3:0] J18_pmod_4321,   // top row of pins,       J18_pmod_4321[3] next to ground pin
	inout [3:0] J18_pmod_a987,   // row adjacent to board, J18_pmod_a987[3] next to ground pin
	inout [5:0] J19_hdmi_data,
	inout [5:0] J19_hdmi_ctrl,
	output U15_clk,
	output U15_spi_start,
	output [15:0] U15_spi_addr,
	output U15_spi_read,
	output [15:0] U15_spi_data,
	input [15:0] U15_sdo_addr,
	input [15:0] U15_spi_rdbk,
	input U15_spi_ready,
	input U15_sdio_as_sdo,
	output U18_clkin,
	output U18_spi_start,
	output [7:0] U18_spi_addr,
	output U18_spi_read,
	output [23:0] U18_spi_data,
	input [7:0] U18_sdo_addr,
	input [23:0] U18_spi_rdbk,
	input U18_spi_ready,
	input U18_sdio_as_sdo,

	output U15_sclk_in,
	output U15_mosi_in,
	output U15_ss_in,
	input U15_miso_out,
	output U15_ssb_in,
	input U15_sclk_out,
	input U15_mosi_out,
	input U15_ssb_out,
	output U18_sclk_in,
	output U18_mosi_in,
	output U18_ssb_in,
	output U18_clk_in,
	input U18_sclk_out,
	input U18_mosi_out,
	output U18_ss_in,
	input U18_miso_out,
	input U18_ssb_out,

	output U15_U18_sclk,
	output U15_U18_mosi,
	output U33U1_pwr_sync,
	output U33U1_pwr_en,
	output U4_csb_in,
	output U4_sclk_in,
	input U4_sdo_out,
	inout U4_sdio_inout,
	output U1_clkuwire_in,
	inout U1_datauwire_inout,
	output U1_leuwire_in,
	output U2_csb_in,
	output U2_sclk_in,

	input U2_sdi,
	output U2_sdo,
	output U2_sdio_as_i,
	output U3_csb_in,
	output U3_sclk_in,
	input U3_sdi,
	output U3_sdo,
	output U3_sdio_as_i
);

wire lb_clk=bmb7_U7_clkout;
assign U15_sclk_in=1'b0;
assign U15_mosi_in=1'b0;
assign U15_ssb_in=1'b1;
assign U18_sclk_in=U15_sclk_out;
assign U18_mosi_in=U15_mosi_out;
assign U18_ssb_in=U15_ssb_out;
assign U15_U18_sclk=U18_sclk_out;
assign U15_U18_mosi=U18_mosi_out;
//wire clk=bmb7_U7_clkout;
//`define BMB7_STANDALONE
`ifdef BMB7_STANDALONE
	// Clock DSP with 125 MHz
	wire adc_clk=rxusrclk_u50_i[0];
`else
	// Clock DSP from external clock source at 1320/14 MHz
	wire adc_clk=U2_clk_div_bufg;
`endif

assign U15_clk=lb_clk;
assign U18_clkin=lb_clk;
// Magic
// Needs placing before usage of any top-level registers
wire clk1x_clk, clk2x_clk, lb4_clk;
`AUTOMATIC_decode
//`AUTOMATIC_map

wire buf_trig_out;  // sourced later by digitizer_dsp
wire trig_ext;  // used by digitizer_dsp
wire [8:0] ow_up_conv, ow_down_conv;
wire [1:0] cav0_state, cav1_state;  // for LEDs
wire [1:0] clk_status;
wire clock_ok = clk_status==2;
wire gtx_crc_fault_x;  // sourced much later
// reg [0:0] lamp_test_trig; top-level single-cycle

// PMOD_PATTERN from visible.v
assign ow_up_conv = 0;
assign ow_down_conv = 0;
wire [15:0] pmod_pattern;
visible visible(.clk(lb_clk), .pattern(pmod_pattern));
assign J17_pmod_4321 = pmod_pattern[3:0];
assign J17_pmod_a987 = pmod_pattern[7:4];
assign J18_pmod_4321[3:2] = pmod_pattern[11:10];
wire de9_rts, de9_txd;
wire de9_rxd = J18_pmod_4321[0];
wire de9_dsr = J18_pmod_4321[1];
wire j5_24v = J18_pmod_a987[2];
wire j4_24v = J18_pmod_a987[3];
assign J18_pmod_a987[1:0] = {de9_rts, de9_txd};
assign trig_ext = 0;

// reg [7:0] uart_rx_hold=0;
// // https://github.com/alexforencich/verilog-uart
// wire [15:0] uart_prescale = 651;  // 50e6/(9600*8)
// wire uart_rst = 0;
// reg [3:0] uart_test_cnt=0;
// always @(posedge lb_clk) if (fp_blinker_tick) uart_test_cnt <= uart_test_cnt + 1;
// wire [7:0] uart_test_out = {4'h4, uart_test_cnt};  // @ through O
// wire [7:0] uart_rx_tdata;
// wire uart_rx_tvalid;
// uart_rx uart_rx(
// .clk(lb_clk), .rst(uart_rst), .rxd(de9_rxd),
// .output_axis_tdata(uart_rx_tdata),
// .output_axis_tvalid(uart_rx_tvalid),
// .output_axis_tready(1'b1),
// .prescale(uart_prescale)
// );
// uart_tx uart_tx(
// .clk(lb_clk), .rst(uart_rst), .txd(de9_txd),
// .input_axis_tdata(uart_test_out),
// .input_axis_tvalid(fp_blinker_tick),
// .prescale(uart_prescale)
// );
// always @(posedge lb_clk) if (uart_rx_tvalid) uart_rx_hold <= uart_rx_tdata;

// Generate localbus based on link to Spartan
wire [23:0] lb_addr;
wire [31:0] lb_dout;
reg [31:0] lb_din=0;
wire lb_strobe, lb_rd;
jxj_gate jxjgate(
	.clk(lb_clk),
	.rx_din(port_50006_word_s6tok7), .rx_stb(port_50006_rx_available), .rx_end(port_50006_rx_complete),
	.tx_dout(port_50006_word_k7tos6), .tx_rdy(port_50006_tx_available), .tx_end(port_50006_tx_complete), .tx_stb(port_50006_word_read),
	.lb_addr(lb_addr), .lb_dout(lb_dout), .lb_din(lb_din),
	.lb_strobe(lb_strobe), .lb_rd(lb_rd)
);
wire lb_write = lb_strobe & ~lb_rd;
wire [31:0] lb_data = lb_dout;

// clk1x for ADC-related registers including sel4v controller
assign clk1x_clk = adc_clk;
wire [31:0] clk1x_data;
wire [23:0] clk1x_addr;
wire clk1x_write;
data_xdomain #(.size(32+24)) lb_to_adc(
	.clk_in(lb_clk), .gate_in(lb_write), .data_in({lb_addr,lb_data}),
	.clk_out(clk1x_clk), .gate_out(clk1x_write), .data_out({clk1x_addr,clk1x_data})
);

// Comment about the following logic for scan_trigger and autoset_enable:
// Newad doesn't have a feature to create several single-cycle events based on the
// value written.  This is a rare-enough case that it seems simpler to create the explicit
// logic here in Verilog.  We DO use the auto-generated address decode strobe, based
// on the scan_trigger port of digitizer_config, so this slightly hack-ish solution is
// still fully integrated with the automatic addressing features.
reg scan_trigger=0; always @(posedge lb_clk) scan_trigger <= we_digitizer_config_scan_trigger_we & lb_dout[0:0];
reg autoset_enable=0; always @(posedge lb_clk) if (we_digitizer_config_scan_trigger_we) autoset_enable <= lb_dout[1:1];

// reg [1:0] adc_mmcm; top-level single-cycle
wire adc_mmcm_psen = adc_mmcm[0];
wire adc_mmcm_psincdec = adc_mmcm[1];

// reg [0:0] ctrace_start; top-level single-cycle

// reg [31:0] icc_cfg; top-level
// reg [7:0] tag_now; top-level
// reg [1:0] domain_jump_realign; top-level

// Most reads are passive; these are not
// TODO: There is no real way to automate this before we start automating the read address space
wire slow_read_lb = lb_strobe & lb_rd & (lb_addr==8'h43);
// llspi lb address decoding
//wire llspi_we = lb_strobe & ~lb_rd & (lb_addr==5);
wire llspi_re = lb_strobe &  lb_rd & (lb_addr==5);

// ADC channel data setup and mapping
reg signed [15:0] U2DA=0, U2DB=0, U2DC=0, U2DD=0;
reg signed [15:0] U3DA=0, U3DB=0, U3DC=0, U3DD=0;
always @(posedge adc_clk) begin
	U2DA <= U2_dout[63:48];
	U2DB <= U2_dout[47:32];
	U2DC <= U2_dout[31:16];
	U2DD <= U2_dout[15: 0];
	U3DA <= U3_dout[63:48];
	U3DB <= U3_dout[47:32];
	U3DC <= U3_dout[31:16];
	U3DD <= U3_dout[15: 0];
end
wire [127:0] adc_data = {U2DD, U2DC, U2DB, U2DA, U3DD, U3DC, U3DB, U3DA};

// Signals that feed into the local bus read multiplexer
wire [27:0] frequency_adc;
wire [27:0] frequency_4xout;
wire [27:0] frequency_clkout3;
wire [27:0] frequency_dac_dco;
wire [27:0] frequency_gtx_tx;
wire [27:0] frequency_gtx_rx;
wire [15:0] hist_dout;
wire  [1:0] hist_status;
wire [15:0] phasex_dout;
wire phasex_ready;
wire phasex_present;
wire [1:0] phasex_status = {phasex_present,phasex_ready};
wire [12:0] clk_phase_diff_out_U2,  clk_phase_diff_out_U3;
wire [13:0] clk_phase_diff_freq_U2, clk_phase_diff_freq_U3;
wire        clk_phase_diff_err_U2,  clk_phase_diff_err_U3;
wire [7:0] llspi_status;
wire [7:0] llspi_result;
wire wave1_available, wave0_available;
wire [7:0] rawadc_avail;
wire [31:0] banyan_data;
wire [31:0] banyan_status;
wire [31:0] trace_data;
wire [31:0] trace_status1;
wire [31:0] trace_status2;
wire [7:0] slow_data;
wire [0:0] slow_data_ready;
wire [31:0] phase_status_U2;
wire [31:0] phase_status_U3;
reg [15:0] crc_errors=0;
wire [6:0] idelay_mirror_val;
wire [7:0] scanner_result_val;
wire [7:0] slow_chain_out;
wire [19:0] icc_data_U50, icc_data_U32;
wire [8:0] qsfp_result;
wire [31:0] ctrace_out;
wire [0:0] ctrace_running;
parameter ctrace_aw=12;
wire [ctrace_aw-1:0] ctrace_pc;
wire [ctrace_aw-0:0] ctrace_status = {ctrace_pc, ctrace_running};
wire [31:0] ccr1_summary;
wire [31:0] ccr1_counts;
wire [31:0] ccr1_cavity0_status;
wire [31:0] ccr1_cavity1_status;
wire [31:0] ccr1_rev_id;
reg [15:0] cc1_latency=0;
wire [15:0] cct1_local_frame_counter;  // output of chitchat_tx
wire signed [17:0] cavity0_detune;
wire signed [17:0] cavity1_detune;
reg [0:0] cct1_cavity0_detune_valid=0;
reg [0:0] cct1_cavity1_detune_valid=0;
wire cavity0_detune_stb;
wire cavity1_detune_stb;
wire [6:0] cavity0_sat_count;
wire [6:0] cavity1_sat_count;
wire [2:0] dtrace_status;
wire [23:0] trace_lb_out;
wire [21:0] telem_monitor;
wire signed [13:0] fdbk_drive_lb_out;
wire [25:0] freq_multi_count_out;
wire [1:0] dac_enabled;
wire [31:0] U15_spi_addr_rdbk = {U15_sdo_addr, U15_spi_rdbk};
wire [1:0] U15_spi_status = {U15_spi_ready, U15_sdio_as_sdo};
wire [31:0] U18_spi_addr_rdbk = {U18_sdo_addr, U18_spi_rdbk};
wire [1:0] U18_spi_status = {U18_spi_ready, U18_sdio_as_sdo};
wire [3:0] J18_debug = {de9_dsr, de9_rxd, j4_24v, j5_24v};

// this 2K x 16 ROM should be automatically generated
wire [15:0] config_rom_out;
config_romx config_romx(.clk(lb_clk), .address(lb_addr[10:0]), .data(config_rom_out));
// Let the above lookup table synthesize smoothly as block RAM
//reg [15:0] config_rom_out_r=0;
//always @(posedge lb_clk) config_rom_out_r <= config_rom_out;

// Simple redefinitions to harmonize names in output decoder
wire [31:0] hello_0 = "Hell";
wire [31:0] hello_1 = "o wo";
wire [31:0] hello_2 = "rld!";
wire [31:0] hello_3 = 32'h0d0a0d0a;
wire [31:0] ffffffff = 32'hffffffff;
wire [31:0] U2dout_lsb = U2_dout[31:0];
wire [31:0] U2dout_msb = U2_dout[63:32];
wire [31:0] U3dout_lsb = U3_dout[31:0];
wire [31:0] U3dout_msb = U3_dout[63:32];
wire [19:0] idelay_value_out_U2_lsb = U2_idelay_value_out[19:0];
wire [19:0] idelay_value_out_U2_msb = U2_idelay_value_out[39:20];
wire [19:0] idelay_value_out_U3_lsb = U3_idelay_value_out[19:0];
wire [19:0] idelay_value_out_U3_msb = U3_idelay_value_out[39:20];

// Very basic pipelining of read process
reg [23:0] lb_addr_r=0;
always @ (posedge lb_clk) begin
	if (lb_strobe)
		lb_addr_r <= lb_addr;
end

// Stupid test rig -- help us, Vamsi!
reg [31:0]
	reg_bank_0=0,
	reg_bank_1=0,
	reg_bank_2=0,
	reg_bank_3=0,
	reg_bank_4=0,
	reg_bank_5=0;
always @(posedge lb_clk) begin
	case (lb_addr[3:0])
		4'h0: reg_bank_0 <= hello_0;
		4'h1: reg_bank_0 <= hello_1;
		4'h2: reg_bank_0 <= hello_2;
		4'h3: reg_bank_0 <= hello_3;
		4'h4: reg_bank_0 <= llspi_status;
		4'h5: reg_bank_0 <= llspi_result;
		4'h6: reg_bank_0 <= clk_status;  // alias: clk_status_out
		4'h7: reg_bank_0 <= ffffffff;
		4'h8: reg_bank_0 <= frequency_adc;
		4'h9: reg_bank_0 <= frequency_4xout;
		4'ha: reg_bank_0 <= frequency_clkout3;
		4'hb: reg_bank_0 <= frequency_dac_dco;  // alias: frequency_dco
		4'hc: reg_bank_0 <= U2dout_lsb;
		4'hd: reg_bank_0 <= U2dout_msb;
		4'he: reg_bank_0 <= idelay_value_out_U2_lsb;
		4'hf: reg_bank_0 <= idelay_value_out_U2_msb;
		default: reg_bank_0 <= 32'hfaceface;
	endcase
	case (lb_addr[3:0])
		4'h0: reg_bank_1 <= U3dout_lsb;
		4'h1: reg_bank_1 <= U3dout_msb;
		4'h2: reg_bank_1 <= idelay_value_out_U3_lsb;
		4'h3: reg_bank_1 <= idelay_value_out_U3_msb;
		4'ha: reg_bank_1 <= dtrace_status;
		4'hc: reg_bank_1 <= ctrace_status;  // alias: ctrace_running
		4'hd: reg_bank_1 <= frequency_gtx_tx;
		4'he: reg_bank_1 <= frequency_gtx_rx;
		4'hf: reg_bank_1 <= hist_status;
		default: reg_bank_1 <= 32'hfaceface;
	endcase
	case (lb_addr[3:0])
		//  xxxx20  unused
		//  xxxx21  unused
		//  xxxx22  unused
		//  xxxx23  unused
		//  xxxx24  unused
		//  xxxx25  unused
		//  xxxx26  unused
		//  xxxx27  unused
		//  xxxx28  unused
		//  xxxx29  unused
		//  xxxx2a  unused
		//  xxxx2b  unused
		//  xxxx2c  unused
		//  xxxx2d  unused
		4'he: reg_bank_2 <= phasex_status;
		4'hf: reg_bank_2 <= phase_status_U2;  // alias: clk_phase_diff_out_U2
		default: reg_bank_2 <= 32'hfaceface;
	endcase
	case (lb_addr[3:0])
		4'h0: reg_bank_3 <= phase_status_U3;  // alias: clk_phase_diff_out_U3
		4'h1: reg_bank_3 <= crc_errors;
		4'h2: reg_bank_3 <= cavity0_detune;
		4'h3: reg_bank_3 <= cavity1_detune;
		4'h4: reg_bank_3 <= cavity0_sat_count;
		4'h5: reg_bank_3 <= cavity1_sat_count;
		4'h6: reg_bank_3 <= dac_enabled;
		//  xxxx37  unused
		4'h8: reg_bank_3 <= U15_spi_addr_rdbk;  // alias: U15_spi_rdbk
		4'h9: reg_bank_3 <= U15_spi_status;
		4'ha: reg_bank_3 <= cct1_cavity0_detune_valid;
		4'hb: reg_bank_3 <= cct1_cavity1_detune_valid;
		4'hc: reg_bank_3 <= U18_spi_addr_rdbk;  // alias: U18_spi_rdbk
		4'hd: reg_bank_3 <= U18_spi_status;
		//  xxxx3e  unused
		4'hf: reg_bank_3 <= J18_debug;
		default: reg_bank_3 <= 32'hfaceface;
	endcase
	case (lb_addr[3:0])
		4'h2: reg_bank_4 <= banyan_status;
		4'h3: reg_bank_4 <= slow_chain_out;
		4'h4: reg_bank_4 <= trace_status1;
		4'h5: reg_bank_4 <= trace_status2;
		4'h7: reg_bank_4 <= slow_data_ready;
		4'h8: reg_bank_4 <= telem_monitor;
		default: reg_bank_4 <= 32'hfaceface;
	endcase
	case (lb_addr[3:0])
		// Most of these are in the wrong clock domain
		4'h0: reg_bank_5 <= ccr1_summary;
		4'h1: reg_bank_5 <= ccr1_counts;
		4'h2: reg_bank_5 <= ccr1_cavity0_status;
		4'h3: reg_bank_5 <= ccr1_cavity1_status;
		4'h4: reg_bank_5 <= ccr1_rev_id;
		4'h5: reg_bank_5 <= cc1_latency;
		4'h6: reg_bank_5 <= cct1_local_frame_counter;
		default: reg_bank_5 <= 32'hfaceface;
	endcase
	// All of the following rhs have had one stage of decode pipeline;
	// either the reg_bank_x multiplexer above, or a dpram clock cycle.
	// Thus the address is also one cycle delayed.
	casex (lb_addr_r)
	  //24'b1xxx_xxxx_xxxx_xxxx_xxxx_xxxx: lb_din <= mirror_out_0;  // automatic address map
		24'h10xxxx: lb_din <= hist_dout;
		24'h11xxxx: lb_din <= phasex_dout;
		24'h13xxxx: lb_din <= scanner_result_val;
		24'h14xxxx: lb_din <= trace_data;
		24'h18xxxx: lb_din <= slow_data[7:0];
		24'h1cxxxx: lb_din <= trace_lb_out;
		24'h2xxxxx: lb_din <= banyan_data;
		24'bxxxx_xxxx_xxxx_1xxx_xxxx_xxxx: lb_din <= config_rom_out;  // xxx800 through xxxfff, 2K
		24'hxxxx0x: lb_din <= reg_bank_0;
		24'hxxxx1x: lb_din <= reg_bank_1;
		24'hxxxx2x: lb_din <= reg_bank_2;
		24'hxxxx3x: lb_din <= reg_bank_3;
		24'hxxxx4x: lb_din <= reg_bank_4;
		24'hxxxx5x: lb_din <= reg_bank_5;
		24'bxxxx_xxxx_xxxx_xxxx_0111_xxxx: lb_din <= idelay_mirror_val;  // xxxxf0 through xxxff
		default: lb_din <= 32'hfaceface;
	endcase
end

// llspi routing
wire llspi_sdi = U2_sdi;
wire llspi_sdo;
assign U3_sdo = llspi_sdo;
assign U2_sdo = llspi_sdo;
assign U3_sdio_as_i = U27dir;
assign U2_sdio_as_i = U27dir;

wire rawadc_trig_x;
digitizer_config digitizer_config // auto
(
	.lb_clk(lb_clk),
	.lb_strobe(lb_strobe),
	.lb_rd(lb_rd),
	.lb_addr(lb_addr),
	.lb_dout(lb_dout),
	.U1_clkout3(U1_clkout3),
	.U2_clk_div_bufg(U2_clk_div_bufg),
	.U2_clk_div_bufr(U2_clk_div_bufr),
	.U3_clk_div_bufr(U3_clk_div_bufr),
	.bmb7_U7_clk4xout(bmb7_U7_clk4xout),
	.U4_dco_clk_out(U4_dco_clk_out),
	.U18_clk_in(U18_clk_in),
	.U33U1_pwr_sync(U33U1_pwr_sync),
	.U2_idelay_ld(U2_idelay_ld),
	.U3_idelay_ld(U3_idelay_ld),
	.U2_idelay_value_in(U2_idelay_value_in),
	.U3_idelay_value_in(U3_idelay_value_in),
	.U15_spi_start(U15_spi_start),
	.U15_spi_read(U15_spi_read),
	.U15_spi_data(U15_spi_data),
	.U15_spi_addr(U15_spi_addr),
	.U18_spi_start(U18_spi_start),
	.U18_spi_read(U18_spi_read),
	.U18_spi_data(U18_spi_data),
	.U18_spi_addr(U18_spi_addr),
	.U4_reset(U4_reset),
	.mmcm_reset(mmcm_reset),
	.mmcm_locked(mmcm_locked),
	.U33U1_pwr_en(U33U1_pwr_en),
	.idelayctrl_reset(idelayctrl_reset),
	.U2_pdwn(U2_pdwn),
	.U3_pdwn(U3_pdwn),
	.U2_sclk_in(U2_sclk_in),
	.U4_sdio_inout(U4_sdio_inout),
	.U1_leuwire_in(U1_leuwire_in),
	.U27dir(U27dir),
	.U2_csb_in(U2_csb_in),
	.U3_csb_in(U3_csb_in),
	.U4_csb_in(U4_csb_in),
	.U4_sdo_out(U4_sdo_out),
	.U15_miso_out(U15_miso_out),
	.U18_miso_out(U18_miso_out),
	.llspi_sdi(llspi_sdi),
	.llspi_sdo(llspi_sdo),
	.U2_clk_reset(U2_clk_reset),
	.U3_clk_reset(U3_clk_reset),
	.U2_bitslip(U2_bitslip),
	.U3_bitslip(U3_bitslip),
	.U2_iserdes_reset(U2_iserdes_reset),
	.U3_iserdes_reset(U3_iserdes_reset),
	.rawadc_trig_x(rawadc_trig_x),
	.adc_clk(adc_clk),
	.adc_data(adc_data),
	.banyan_status(banyan_status),
	.phasex_dout(phasex_dout),
	.phase_status_U2(phase_status_U2),
	.phase_status_U3(phase_status_U3),
	.phasex_ready(phasex_ready),
	.phasex_present(phasex_present),
	.llspi_status(llspi_status),
	.llspi_result(llspi_result),
	.idelay_mirror_val(idelay_mirror_val),
	.scanner_result_val(scanner_result_val),
	.banyan_data(banyan_data),
	.frequency(frequency_adc),
	.frequency_4xout(frequency_4xout),
	.frequency_clkout3(frequency_clkout3),
	.frequency_dac_dco(frequency_dac_dco),
	.clk_status(clk_status),
	.llspi_re(llspi_re),
	.autoset_enable(autoset_enable),
	.scan_trigger(scan_trigger),
	`AUTOMATIC_digitizer_config
);

wire slow_snap = rawadc_trig_x;
digitizer_slowread digitizer_slowread // auto
(
	.lb_clk(lb_clk),
	.adc_clk(adc_clk),
	.adc_data(adc_data),
	.slow_snap(slow_snap),
	.slow_chain_out(slow_chain_out),
	.slow_read_lb(slow_read_lb),
	.tag_now(tag_now)
	//`AUTOMATIC_digitizer_slowread
);


// Need a better home for these
assign U2_mmcm_psclk = lb_clk;
assign U2_mmcm_psen = adc_mmcm_psen;
assign U2_mmcm_psincdec = adc_mmcm_psincdec;
// Maybe no need to attach to U2_mmcm_psdone
assign U3_mmcm_psclk = 0;
assign U3_mmcm_psen = 0;
assign U3_mmcm_psincdec = 0;
// Do not attach to U3_mmcm_psdone

assign clk200=bmb7_U7_clk4xout; // clk200 should be 200MHz +/- 10MHz or 300MHz +/- 10MHz
assign U4_dci = U4_dco_clk_out;

assign D4rgb[0] = 1'b1;
assign D5rgb[0] = 1'b1;
assign D4rgb[1] = 1'b1;
assign D5rgb[1] = 1'b1;
assign D4rgb[2] = 1'b1;
assign D5rgb[2] = 1'b1;

endmodule
