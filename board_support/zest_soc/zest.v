module zest #(
    parameter [7:0] BASE_ADDR = 8'h05,
    parameter DSP_FREQ_MHZ = 119.0,
    parameter FCNT_WIDTH = 16,  // to speed up simulaiton. 125M / 2**16 = 1.9kHz update rate.
    parameter PH_DIFF_DW = 13,
    parameter real DAC_INTERP_COEFF_R = 1.0,
    localparam integer  N_ADC = 2,
    localparam integer  N_CH = N_ADC*4,
    localparam real     CLKIN_PERIOD = 1000.0 / DSP_FREQ_MHZ / 2,    // ns
    localparam integer  PH_DIFF_ADV = DSP_FREQ_MHZ / 200.0 * (2**PH_DIFF_DW),
    localparam [14:0]  DAC_INTERP_COEFF = DAC_INTERP_COEFF_R / 2 * (2**14)
) (
    // Hardware pins
    // U24 74LVC8T245
    output              ADC_PDWN,
    output              ADC_CSB_0,
    output              ADC_SYNC,
    output              SCLK,       // ADC0/1, DAC, LMK
    output              SDI,        // LMK, DAC_SDIO
    output              ADC_CSB_1,
    // U25 74LVC8T245
    output              LMK_LEUWIRE,
    output              PWR_SYNC,
    output              PWR_EN,
    output              AD7794_FCLK,
    // U26 74LVC8T245
    output              DAC_CSB,
    output              AMC7823_SPI_SS,
    output              AD7794_CSB,
    output              DAC_RESET,
    output              POLL_SCLK,  // AMC7823, AD7794
    output              POLL_MOSI,  // AMC7823, AD7794
    // U27 74LVC8T245
    output              ADC_SDIO_DIR,
    inout               ADC_SDIO,   // ADC0, ADC1
    // U28 74LVC8T245
    input               AMC7823_SPI_MISO,
    input               LMK_DATAUWIRE,
    input               AD7794_DOUT,
    input               DAC_SDO,

    // From U1 LMK0801
    // CLKout4_7 divider group
    input               CLK_TO_FPGA_P,
    input               CLK_TO_FPGA_N,

    // U2/U3 AD9563
    // CLKout0_3 divider group
    input [N_CH-1:0]    ADC_D0_P,
    input [N_CH-1:0]    ADC_D0_N,
    input [N_CH-1:0]    ADC_D1_P,
    input [N_CH-1:0]    ADC_D1_N,
    input [N_ADC-1:0]   ADC_DCO_P,
    input [N_ADC-1:0]   ADC_DCO_N,
    input [N_ADC-1:0]   ADC_FCO_P,
    input [N_ADC-1:0]   ADC_FCO_N,

    // U4 AD9781
    // CLKout4_7 divider group
    output [13:0]       DAC_D_P,
    output [13:0]       DAC_D_N,
    output              DAC_DCI_P,
    output              DAC_DCI_N,
    input               DAC_DCO_P,
    input               DAC_DCO_N,

    // Data interface
    output               dsp_clk_out,
    output [N_ADC-1:0]   clk_div_out,
    output [N_CH-1:0]    adc_out_clk,
    output [16*N_CH-1:0] adc_out_data,
    output               dac_clk_out,
    input  [13:0]        dac_in_data_i,
    input  [13:0]        dac_in_data_q,

    input  clk_200,
    // PicoRV32 packed MEM Bus interface
    input  clk,
    input  rst,
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret
);
//   attribute IODELAY_GROUP of IDELAYCTRL_adc_inst       : label is "in_delay_adc_grp";

// (* IODELAY_GROUP="in_delay_adc_grp" *)
// IDELAYCTRL idelayctrl_inst (
//   .RST          ( rst ),
//   .REFCLK       ( clk_200      ),
//   .RDY          (              )
// );
initial begin
    $display("CLKIN_PERIOD: %f ns, PH_DIFF_ADV: %d", CLKIN_PERIOD, PH_DIFF_ADV);
end

wire [32:0] mem_packed_rets [N_CH-1:0];
wire [32:0] mem_packed_ret_spi;
wire [32:0] mem_packed_ret_sfr;
wire [32:0] mem_packed_ret_wfm;
wire [32:0] mem_packed_ret_awg;
reg  [32:0] mem_packed_ret_r=0;
integer jx;
always @(*) begin
    mem_packed_ret_r = 0;
    for (jx=0; jx < N_CH; jx=jx+1)
        mem_packed_ret_r = mem_packed_ret_r | mem_packed_rets[jx];
end
assign mem_packed_ret = mem_packed_ret_r |
    mem_packed_ret_sfr |
    mem_packed_ret_spi |
    mem_packed_ret_wfm |
    mem_packed_ret_awg;

//--------------------------------------------------------------
// BASE2 Address offsets
//--------------------------------------------------------------
/// #define ZEST_BASE2_ADC   0x000000
/// #define ZEST_BASE2_SFR   0x200000
/// #define ZEST_BASE2_SPI   0x210000
/// #define ZEST_BASE2_WFM   0x220000
/// #define ZEST_BASE2_AWG   0x230000
localparam [7:0] BASE_ADC = 8'h00;
localparam [7:0] BASE_SFR = 8'h20;
localparam [7:0] BASE_SPI = 8'h21;
localparam [7:0] BASE_WFM = 8'h22;
localparam [7:0] BASE_AWG = 8'h23;

//--------------------------------------------------------------
// PicoRV SPI master
//--------------------------------------------------------------
wire spi_ss;
wire spi_sck;
wire spi_dio;
wire spi_oe;
wire spi_dio_en;
wire spi_mosi;
wire spi_miso;

zest_spi_dio_pack #(
    .BASE_ADDR      ( BASE_ADDR ),
    .BASE2_ADDR     ( BASE_SPI  )
) spi_master (
    .clk            ( clk      ),
    .rst            ( rst      ),
    .spi_ss         ( spi_ss   ),
    .spi_sck        ( spi_sck  ),
    .spi_mosi       ( spi_mosi ),
    .spi_miso       ( spi_miso ),
    .dio_en         ( spi_dio_en),
    .spi_dio        ( spi_dio  ),
    .spi_oe         ( spi_oe   ),
    .mem_packed_fwd (mem_packed_fwd ),
    .mem_packed_ret (mem_packed_ret_spi)
);

//--------------------------------------------------------------
// PicoRV SFR (GPIO pins)
//--------------------------------------------------------------
wire [2*32-1:0] sfRegsWrStr, sfRegsOut, sfRegsInp;

sfr_pack #(
    .N_REGS         ( 2 ),
    .BASE_ADDR      ( BASE_ADDR ),
    .BASE2_ADDR     ( BASE_SFR)
) sfr_reset (
    .clk            ( clk        ),
    .rst            ( rst        ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_ret_sfr ),
    .sfRegsOut      ( sfRegsOut ),
    .sfRegsIn       ( sfRegsInp ),
    .sfRegsWrStr    ( sfRegsWrStr )
);

// SFR_OUT_REG0
/// #define SFR_OUT_BYTE_PH_SEL     0
/// #define SFR_OUT_BYTE_FCLK_SEL   1
/// #define SFR_OUT_BYTE_CSB_SEL    2
/// #define SFR_OUT_BIT_ADC_PDWN    24
/// #define SFR_OUT_BIT_DAC_RESET   25
/// #define SFR_OUT_BIT_ADC_SYNC    26
/// #define SFR_OUT_BIT_PWR_SYNC    27
/// #define SFR_OUT_BIT_PWR_ENB     28
/// #define SFR_OUT_BIT_BUFR_A_RST  29
/// #define SFR_OUT_BIT_BUFR_B_RST  30
/// #define SFR_OUT_BIT_DSPCLK_RST  31
/// #define SFR_IN_REG_PCNT         0
/// #define SFR_IN_REG_FCNT         1
/// #define SFR_IN_BIT_DSPCLK_LOCKED 16
wire [7:0] phs_sel  = sfRegsOut[7:0];
wire [7:0] fclk_sel = sfRegsOut[15:8];
wire [7:0] csb_sel  = sfRegsOut[(2*8)+:8];
wire adc_pdwn       = sfRegsOut[24];
wire dac_reset      = sfRegsOut[25];
wire adc_sync       = sfRegsOut[26];
wire pwr_sync       = sfRegsOut[27];
wire pwr_en_b       = sfRegsOut[28];
wire [1:0] bufr_reset= sfRegsOut[30:29];
wire dspclk_reset   = sfRegsOut[31];
// SFR_OUT_REG1
/// #define SFR_OUT_REG1            1
/// #define SFR_OUT_BIT_DAC0_SRCSEL 0
/// #define SFR_OUT_BIT_DAC0_ENABLE 1
/// #define SFR_OUT_BIT_DAC1_SRCSEL 2
/// #define SFR_OUT_BIT_DAC1_ENABLE 3
wire dac0_src_sel   = sfRegsOut[32*1+0];
wire dac0_enable    = sfRegsOut[32*1+1];
wire dac1_src_sel   = sfRegsOut[32*1+2];
wire dac1_enable    = sfRegsOut[32*1+3];

// Chip Select Bar for SPI
wire [6:0] ic_csb = ~(1 << csb_sel);
///     ZEST_DEV_AD9653A   =  0x00,     // U2 ADC
///     ZEST_DEV_AD9653B   =  0x01,     // U3 ADC
///     ZEST_DEV_AD9781    =  0x02,     // U4 DAC
///     ZEST_DEV_LMK01801  =  0x03,     // U1 Clk
///     ZEST_DEV_AD7794    =  0x04,     // U18 SPI ADC (Thermistors)
///     ZEST_DEV_AMC7823   =  0x05      // U15 housekeeping
///     ZEST_DEV_AD9653_BOTH =  0x06,     // U2+U3 ADC, write only
assign ADC_CSB_0        = spi_ss | (ic_csb[0] & ic_csb[6]);
assign ADC_CSB_1        = spi_ss | (ic_csb[1] & ic_csb[6]);
assign DAC_CSB          = spi_ss | ic_csb[2];
assign LMK_LEUWIRE      = spi_ss | ic_csb[3];
assign AD7794_CSB       = spi_ss | ic_csb[4];
assign AMC7823_SPI_SS   = spi_ss | ic_csb[5];

// SPI tree 1: ADC0/1, DAC, LMK
// SPI tree 2: AMC7823, AD7794
assign SCLK         = spi_sck;
assign POLL_SCLK    = spi_sck;
assign ADC_SDIO     = spi_dio;
assign ADC_SDIO_DIR = spi_oe;
assign spi_dio_en   = ~ic_csb[1] || ~ic_csb[0];
wire [6:0] spi_miso_list = {
    1'b0, AMC7823_SPI_MISO, AD7794_DOUT, LMK_DATAUWIRE,
    DAC_SDO, ADC_SDIO, ADC_SDIO};
assign spi_miso     = spi_miso_list[csb_sel];
assign SDI          = spi_mosi;
assign POLL_MOSI    = spi_mosi;

assign ADC_PDWN     = adc_pdwn;
assign DAC_RESET    = dac_reset;
assign ADC_SYNC     = adc_sync;
assign PWR_SYNC     = pwr_sync;
assign PWR_EN       = ~pwr_en_b;

// ADC0_DIV, ADC1_DIV, DAC_DCO
wire signed [PH_DIFF_DW-1:0] phdiff [N_ADC:0];
wire [N_ADC:0] phdiff_val;
// DSP_CLK, ADC0_DIV, ADC1_DIV, DAC_DCO
wire [27:0] f_clks [N_ADC+1:0];
wire pll_locked;

assign sfRegsInp[ 0+:PH_DIFF_DW] = phdiff[phs_sel];        // SFR_IN_REG_PCNT
assign sfRegsInp[32+:32] = f_clks[fclk_sel];       // SFR_IN_REG_FCNT
assign sfRegsInp[16] = pll_locked;          // SFR_IN_BIT_DSPCLK_LOCKED

//--------------------------------------------------------------
// CLK
//--------------------------------------------------------------
wire dac_dco_clk;

xilinx7_clocks #(
    .DIFF_CLKIN("TRUE"),
    .CLKIN_PERIOD(CLKIN_PERIOD),  // REFCLK: about 240 MHz
    .MULT     (5),      // 240 X 5   = 1200 MHz
    .DIV0     (10),     // 1200 / 10 =  120 MHz
    .DIV1     (5)       // 1200 / 5  =  240 MHz
) clocks_i (
    .sysclk_p (DAC_DCO_P),
    .sysclk_n (DAC_DCO_N),
    .reset    (dspclk_reset),
    .clk_out1 (dac_dco_clk),
    .clk_out2 (dsp_clk_out),    // 90 deg
    .locked   (pll_locked)
);

//--------------------------------------------------------------
// ADC
//--------------------------------------------------------------
wire [N_ADC-1:0] clk_dco_buf;
wire [N_ADC-1:0] clk_div;
wire [N_ADC-1:0] clk_div_buf;
wire [N_ADC-1:0] clk_dco_frame;
wire [N_ADC-1:0] clk_div_frame;
wire [N_CH-1:0] clk_dco_data;
wire [N_CH-1:0] clk_div_data;

wire [1:0] in_p [N_CH-1:0];
wire [1:0] in_n [N_CH-1:0];

zest_clk_map #(
    .N_ADC       (N_ADC)
) clk_map_i (
    .clk_dco_in     (clk_dco_buf),
    .clk_div_in     (clk_div),
    .clk_dco_frame  (clk_dco_frame),        // not used
    .clk_div_frame  (clk_div_frame),        // not used
    .clk_dco_data   (clk_dco_data),
    .clk_div_data   (clk_div_data)
);

freq_count #(
    .refcnt_width   (FCNT_WIDTH)
) fcnt_dsp (
    .sysclk     (clk),
    .f_in       (dsp_clk_out),
	.frequency  (f_clks[3])
);

genvar ix;
generate for (ix=0; ix<N_ADC; ix=ix+1) begin: ic_map
    dco_buf dco_buf_i (
        .clk_reset    (bufr_reset[ix]),
        .dco_n        (ADC_DCO_P[ix]),  // flip
        .dco_p        (ADC_DCO_N[ix]),  // flip
        .clk_div      (clk_div[ix]),
        .clk_dco_buf  (clk_dco_buf[ix]),
        .clk_div_buf  (clk_div_buf[ix])
    );

    phase_diff #(.adv(PH_DIFF_ADV), .dw(PH_DIFF_DW+1)) phase_diff_i (
        .uclk1      (dsp_clk_out),
        .ext_div1   (1'b0),
        .uclk2      (clk_div[ix]),
        .ext_div2   (1'b0),
        .sclk       (clk_200),
        .rclk       (clk),
        .dval       (phdiff_val[ix]),
        .phdiff_out (phdiff[ix])
    );

    freq_count #(
        .refcnt_width   (FCNT_WIDTH)
    ) fcnt_dco_i (
        .sysclk     (clk),
        .f_in       (clk_div[ix]),
        .frequency  (f_clks[ix])
    );
end endgenerate

wire [15:0] adc_out [N_CH-1:0];
genvar ch;
generate for (ch=0; ch<N_CH; ch=ch+1) begin: ch_map
    assign in_n[ch] = {ADC_D1_P[ch], ADC_D0_P[ch]};  // inverted due to hardware
    assign in_p[ch] = {ADC_D1_N[ch], ADC_D0_N[ch]};  // inverted due to hardware

    // 2-Lane, 16-Bit DDR
    iserdes_pack #(
        .DW            (2),
        .BASE_ADDR     (BASE_ADDR),
        .BASE2_ADDR    (BASE_ADC + ch)
    ) iserdes_i (
        // Hardware interface
        .clk_dco       ( clk_dco_data[ch] ),
        .clk_div       ( clk_div_data[ch] ),
        .in_p          ( in_p[ch]         ),
        .in_n          ( in_n[ch]         ),
        .dout          ( adc_out[ch]      ), // bytewise mode
        // .bitwise_out   ( adc_out[ch]      ), // bitwise mode

        // PicoRV32 packed MEM Bus interface
        .clk            ( clk            ),
        .rst            ( rst            ),
        .mem_packed_fwd ( mem_packed_fwd ),
        .mem_packed_ret ( mem_packed_rets[ch] )
    );
    // assign adc_out_data[16*ch+:16] = adc_out[ch]; // inverted by 0x14=0x7
end endgenerate
    // Remap to SMA order
    assign adc_out_data[16*7+:16] = adc_out[4]; // J11 to ADC1 A
    assign adc_out_data[16*6+:16] = adc_out[5]; // J10 to ADC1 B
    assign adc_out_data[16*5+:16] = adc_out[6]; //  J9 to ADC1 C
    assign adc_out_data[16*4+:16] = adc_out[7]; //  J8 to ADC1 D
    assign adc_out_data[16*3+:16] = adc_out[0]; //  J7 to ADC0 A
    assign adc_out_data[16*2+:16] = adc_out[1]; //  J6 to ADC0 B
    assign adc_out_data[16*1+:16] = adc_out[2]; //  J5 to ADC0 C
    assign adc_out_data[16*0+:16] = adc_out[3]; //  J4 to ADC0 D

assign adc_out_clk = clk_div_data;
assign clk_div_out = clk_div;

wfm_pack #(
    .BASE_ADDR      ( BASE_ADDR ),
    .BASE2_ADDR     ( BASE_WFM  ),
    .N_CH           ( N_CH )
) wfm_i (
    // Hardware interface
    .dsp_clk      (dsp_clk_out),
    .adc_out_data (adc_out_data),
    // PicoRV32 packed MEM Bus interface
    .clk           (clk),
    .rst           (rst),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret_wfm )
);

//--------------------------------------------------------------
// DAC
//--------------------------------------------------------------

// F_RATIO = 2. See phasex_tb.v
phase_diff #(
    .adv            (PH_DIFF_ADV),
    .dw             (PH_DIFF_DW+1),
    .order1         (2),
    .order2         (1)
) phase_diff_dac (
    .uclk1      (dac_dco_clk),
    .ext_div1   (1'b0),
    .uclk2      (dsp_clk_out),
    .ext_div2   (1'b0),
    .sclk       (clk_200),
    .rclk       (clk),
    .dval       (phdiff_val[2]),
    .phdiff_out (phdiff[2])
);

freq_count #(
    .refcnt_width   (FCNT_WIDTH)
) fcnt_dac_i (
    .sysclk     (clk),
    .f_in       (dac_dco_clk),
    .frequency  (f_clks[2])
);

assign dac_clk_out = dac_dco_clk;

// interpolator, crossing from dsp_clk to dac_clk domain
wire signed [13:0] dac0_in_data;
zest_dac_interp #(.DW(14)) dac_interp_a (
    .dsp_clk        (dsp_clk_out),
    .din            (dac_in_data_i),
    .coeff          (DAC_INTERP_COEFF),
    .dac_clk        (dac_clk_out),
    .dout           (dac0_in_data)
);

wire signed [13:0] dac1_in_data;
zest_dac_interp #(.DW(14)) dac_interp_b (
    .dsp_clk        (dsp_clk_out),
    .din            (dac_in_data_q),
    .coeff          (DAC_INTERP_COEFF),
    .dac_clk        (dac_clk_out),
    .dout           (dac1_in_data)
);

// DMA to generate arbitary waveform for DAC BIST
wire [13:0] awg_out_data;
wire awg_out_valid;

awg_pack #(
    .BASE_ADDR     (BASE_ADDR),
    .BASE2_ADDR    (BASE_AWG)
) awg_i (
    // Data interface
    .dsp_clk        (dac_clk_out),
    .d_out_data     (awg_out_data),
    .d_out_valid    (awg_out_valid),
    // PicoRV32 packed MEM Bus interface
    .clk           (clk),
    .rst           (rst),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret_awg )
);

// pipeline awg_out_data for better timing
reg [13:0] awg_out_data1=0;
always @(posedge dac_clk_out) begin
    awg_out_data1 <= awg_out_valid ? awg_out_data : 14'h0;
end

// Mux DAC data source
wire [13:0] dac0_in_data_mux = dac0_enable ? (dac0_src_sel ? awg_out_data1 : dac0_in_data) : 14'h0;
wire [13:0] dac1_in_data_mux = dac1_enable ? (dac1_src_sel ? awg_out_data1 : dac1_in_data) : 14'h0;

// UG471 Fig 2-19, D2 @ rising edge == dac0, match AD9781 datasheet Fig 57.
wire [14:0] dac_oddr_buf;
wire [14:0] dac_oddr_d1 = {1'b0, dac1_in_data_mux};     // Q DAC
wire [14:0] dac_oddr_d2 = {1'b1, dac0_in_data_mux};     // I DAC
wire [14:0] dac_oddr_out_p;
wire [14:0] dac_oddr_out_n;
assign DAC_DCI_P = dac_oddr_out_p[14];
assign DAC_DCI_N = dac_oddr_out_n[14];
assign DAC_D_P   = dac_oddr_out_p[13:0];
assign DAC_D_N   = dac_oddr_out_n[13:0];

genvar iy;
generate for (iy=0; iy < 15; iy=iy+1) begin: in_cell
	ODDR #(.DDR_CLK_EDGE("SAME_EDGE")) oddr(
        .C  (dac_clk_out),
        .CE (1'b1),
        .D1 (dac_oddr_d1[iy]),
        .D2 (dac_oddr_d2[iy]),
        .Q  (dac_oddr_buf[iy])
    );
	OBUFDS obuf_d(
		.I  (dac_oddr_buf[iy]),
		.O  (dac_oddr_out_p[iy]),
		.OB (dac_oddr_out_n[iy])
	);
end
endgenerate

endmodule
