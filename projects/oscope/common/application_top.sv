`define LB_DECODE_application_top

`define AUTOMATIC_decode
`define AUTOMATIC_digitizer_config
`define AUTOMATIC_digitizer_slowread

`include "application_top_auto.vh"

module application_top(
        input             lb_clk,
        input             lb_write,
        input             lb_strobe,
        input             lb_rd,
        input [23:0]      lb_addr,
        input [31:0]      lb_data,
        output reg [31:0] lb_din,

	input             clk200,

	// Zest related
	zest_cfg_if.master zif_cfg,

	output [2:0]      D4rgb,
	output [2:0]      D5rgb,
	inout [3:0]       J17_pmod_4321, // top row of pins,       J17_pmod_4321[3] next to ground pin
	inout [3:0]       J17_pmod_a987, // row adjacent to board, J17_pmod_a987[3] next to ground pin
	inout [3:0]       J18_pmod_4321, // top row of pins,       J18_pmod_4321[3] next to ground pin
	inout [3:0]       J18_pmod_a987, // row adjacent to board, J18_pmod_a987[3] next to ground pin
	inout [5:0]       J19_hdmi_data,
	inout [5:0]       J19_hdmi_ctrl


	// inout          U1_datauwire_inout,  TODO: current status is skeptical

	// input          U3_sdi,
);



//wire clk=bmb7_U7_clkout;
//`define BMB7_STANDALONE
`ifdef BMB7_STANDALONE
	// Clock DSP with 125 MHz
	wire adc_clk=rxusrclk_u50_i[0];
`elsif VERILATOR
        // To be force-set by hierarchical reference in simulation
        reg sim_adc_clk /*verilator public_flat_rw */;
        wire adc_clk = sim_adc_clk;
`else
	// Clock DSP from external clock source at 1320/14 MHz
	wire adc_clk=zif_cfg.U2_clk_div_bufg;
`endif

// Magic
// Needs placing before usage of any top-level registers
wire clk1x_clk, clk2x_clk, lb4_clk;

(* external, signal_type="single-cycle" *) reg [0:0] lamp_test_trig = 0;  // top-level single-cycle
(* external *) reg [31:0] icc_cfg = 0;             // top-level
(* external *) reg [7:0] tag_now = 0;              // top-level
(* external *) reg [1:0] domain_jump_realign = 0;  // top-level

`AUTOMATIC_decode

wire buf_trig_out;  // sourced later by digitizer_dsp
wire trig_ext;  // used by digitizer_dsp
wire [8:0] ow_up_conv, ow_down_conv;
wire [1:0] cav0_state, cav1_state;  // for LEDs
wire [1:0] clk_status;
wire clock_ok = clk_status==2;
wire gtx_crc_fault_x;  // sourced much later

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
reg scan_trigger=0; always @(posedge lb_clk) scan_trigger <= we_digitizer_config_scan_trigger_we & lb_data[0:0];
reg autoset_enable=0; always @(posedge lb_clk) if (we_digitizer_config_scan_trigger_we) autoset_enable <= lb_data[1:1];


// Most reads are passive; these are not
// TODO: There is no real way to automate this before we start automating the read address space
wire slow_read_lb = lb_strobe & lb_rd & (lb_addr==(24'h190000 + 8'h43));
// llspi lb address decoding
wire llspi_re = lb_strobe &  lb_rd & (lb_addr==(24'h190000 + 5));

// ADC channel data setup and mapping
reg signed [15:0] U2DA=0, U2DB=0, U2DC=0, U2DD=0;
reg signed [15:0] U3DA=0, U3DB=0, U3DC=0, U3DD=0;
always @(posedge adc_clk) begin
	U2DA <= zif_cfg.U2_dout[63:48];
	U2DB <= zif_cfg.U2_dout[47:32];
	U2DC <= zif_cfg.U2_dout[31:16];
	U2DD <= zif_cfg.U2_dout[15: 0];
	U3DA <= zif_cfg.U3_dout[63:48];
	U3DB <= zif_cfg.U3_dout[47:32];
	U3DC <= zif_cfg.U3_dout[31:16];
	U3DD <= zif_cfg.U3_dout[15: 0];
end
wire [127:0] adc_data = {U2DD, U2DC, U2DB, U2DA, U3DD, U3DC, U3DB, U3DA};

// Signals that feed into the local bus read multiplexer
wire [27:0] frequency_adc;
wire [27:0] frequency_4xout;
wire [27:0] frequency_clkout3;
wire [27:0] frequency_dac_dco;
wire [15:0] hist_dout=0;
wire  [1:0] hist_status=0;
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
// banyan status register was constructed without regard to clock domains - please revisit
wire [31:0] banyan_status_x;
reg  [31:0] banyan_status;  always @(posedge lb_clk) banyan_status <= banyan_status_x;
wire [31:0] trace_data=0;
wire [31:0] trace_status1=0;
wire [31:0] trace_status2=0;
wire [7:0] slow_data=0;
wire [0:0] slow_data_ready=0;
wire [31:0] phase_status_U2;
wire [31:0] phase_status_U3;
reg [15:0] crc_errors=0;
wire [6:0] idelay_mirror_val;
wire [7:0] scanner_result_val;
wire [7:0] slow_chain_out;
wire [19:0] icc_data_U50, icc_data_U32;
wire [8:0] qsfp_result;
wire signed [13:0] fdbk_drive_lb_out;
wire [25:0] freq_multi_count_out;
wire [31:0] U15_spi_addr_rdbk = {zif_cfg.U15_sdo_addr,  zif_cfg.U15_spi_rdbk};
wire [1:0] U15_spi_status     = {zif_cfg.U15_spi_ready, zif_cfg.U15_sdio_as_sdo};
wire [31:0] U18_spi_addr_rdbk = {zif_cfg.U18_sdo_addr,  zif_cfg.U18_spi_rdbk};
wire [1:0] U18_spi_status     = {zif_cfg.U18_spi_ready, zif_cfg.U18_sdio_as_sdo};
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
wire [31:0] U2dout_lsb = zif_cfg.U2_dout[31:0];
wire [31:0] U2dout_msb = zif_cfg.U2_dout[63:32];
wire [31:0] U3dout_lsb = zif_cfg.U3_dout[31:0];
wire [31:0] U3dout_msb = zif_cfg.U3_dout[63:32];
wire [19:0] idelay_value_out_U2_lsb = zif_cfg.U2_idelay_value_out[19:0];
wire [19:0] idelay_value_out_U2_msb = zif_cfg.U2_idelay_value_out[39:20];
wire [19:0] idelay_value_out_U3_lsb = zif_cfg.U3_idelay_value_out[19:0];
wire [19:0] idelay_value_out_U3_msb = zif_cfg.U3_idelay_value_out[39:20];

// Very basic pipelining of read process
reg [23:0] lb_addr_r=0;
always @ (posedge lb_clk) begin
	if (lb_strobe)
		lb_addr_r <= lb_addr;
end

// reverse_json_offset : 1638400
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
		//  xxxx37  unused
		4'h8: reg_bank_3 <= U15_spi_addr_rdbk;  // alias: U15_spi_rdbk
		4'h9: reg_bank_3 <= U15_spi_status;
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
		default: reg_bank_4 <= 32'hfaceface;
	endcase
	case (lb_addr[3:0])
		4'h1: reg_bank_5 <= 1;
		default: reg_bank_5 <= 32'hfaceface;
	endcase
	// All of the following rhs have had one stage of decode pipeline;
	// either the reg_bank_x multiplexer above, or a dpram clock cycle.
	// Thus the address is also one cycle delayed.
	casez (lb_addr_r)
	  //24'b1???_????_????_????_????_????: lb_din <= mirror_out_0;  // automatic address map
		24'h10????: lb_din <= hist_dout;
		24'h11????: lb_din <= phasex_dout;
		24'h13????: lb_din <= scanner_result_val;
		24'h14????: lb_din <= trace_data;
		24'h18????: lb_din <= slow_data[7:0];
		24'h19??0?: lb_din <= reg_bank_0;
		24'h19??1?: lb_din <= reg_bank_1;
		24'h19??2?: lb_din <= reg_bank_2;
		24'h19??3?: lb_din <= reg_bank_3;
		24'h19??4?: lb_din <= reg_bank_4;
		24'h19??5?: lb_din <= reg_bank_5;
		24'h19??7?: lb_din <= idelay_mirror_val;  // xx70 through xx7f
		24'b0001_11??_????_????_????_????: lb_din <= banyan_data;
		24'b????_????_????_1???_????_????: lb_din <= config_rom_out;  // xxx800 through xxxfff, 2K
		default: lb_din <= 32'hfaceface;
	endcase
end

wire rawadc_trig_x;
(* lb_automatic *)
digitizer_config digitizer_config // auto
  (
   .lb_clk(lb_clk),
   .lb_strobe(lb_strobe),
   .lb_rd(lb_rd),
   .lb_addr(lb_addr),
   .lb_dout(lb_data),
   .zif_cfg(zif_cfg),
   .clk200(clk200),
   .rawadc_trig_x(rawadc_trig_x),
   .adc_clk(adc_clk),
   .adc_data(adc_data),
   .banyan_status(banyan_status_x),
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
(* lb_automatic *)
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



assign zif_cfg.U4_dci = zif_cfg.U4_dco_clk_out;

// UNUSED BMB7/QF2 stuff
assign D4rgb[0] = 1'b1;
assign D5rgb[0] = 1'b1;
assign D4rgb[1] = 1'b1;
assign D5rgb[1] = 1'b1;
assign D4rgb[2] = 1'b1;
assign D5rgb[2] = 1'b1;

endmodule
