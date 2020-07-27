module zest #(
    parameter N_ADC = 2,
    parameter N_CH = N_ADC*4,
    parameter FCNT_WIDTH = 16,
    parameter [7:0] BASE_ADDR = 8'h05
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

    input               CLK_TO_FPGA_P,
    input               CLK_TO_FPGA_N,

    input [N_CH-1:0]    ADC_D0_P,
    input [N_CH-1:0]    ADC_D0_N,
    input [N_CH-1:0]    ADC_D1_P,
    input [N_CH-1:0]    ADC_D1_N,
    input [N_ADC-1:0]   ADC_DCO_P,
    input [N_ADC-1:0]   ADC_DCO_N,
    input [N_ADC-1:0]   ADC_FCO_P,
    input [N_ADC-1:0]   ADC_FCO_N,

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
    input  [13:0]        dac_in_data_i,
    input  [13:0]        dac_in_data_q,

    input  clk_200,
    // PicoRV32 packed MEM Bus interface
    input  clk,
    input  rst,
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret
);

wire [32:0] mem_packed_rets [N_CH-1:0];
wire [32:0] mem_packed_ret_spi;
wire [32:0] mem_packed_ret_sfr;
wire [32:0] mem_packed_ret_wfm;
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
    mem_packed_ret_wfm;

//--------------------------------------------------------------
// BASE2 Address offsets
//--------------------------------------------------------------
/// #define ZEST_BASE2_ADC   0x000000
/// #define ZEST_BASE2_SFR   0x200000
/// #define ZEST_BASE2_SPI   0x210000
/// #define ZEST_BASE2_WFM   0x220000
localparam [7:0] BASE_ADC = 8'h00;
localparam [7:0] BASE_SFR = 8'h20;
localparam [7:0] BASE_SPI = 8'h21;
localparam [7:0] BASE_WFM = 8'h22;

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
// PicoRV SFR (GPIO output pins)
//--------------------------------------------------------------
wire [31:0] sfRegsWrStr, sfRegsOut, sfRegsInp;

sfr_pack #(
    .N_REGS         ( 1 ),
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

/// #define SFR_OUT_BYTE_PH_SEL     0
/// #define SFR_OUT_BYTE_FCLK_SEL   1
/// #define SFR_OUT_BYTE_CSB_SEL    2
/// #define SFR_OUT_BIT_ADC_PDWN    24
/// #define SFR_OUT_BIT_DAC_RESET   25
/// #define SFR_OUT_BIT_ADC_SYNC    26
/// #define SFR_OUT_BIT_PWR_SYNC    27
/// #define SFR_OUT_BIT_PWR_ENB     28
/// #define SFR_WST_BIT_BUFR_A_RST  29
/// #define SFR_WST_BIT_BUFR_B_RST  30
/// #define SFR_IN_BYTE_PCNT        0
/// #define SFR_IN_BYTE_FCNT        2
wire [7:0] phs_sel  = sfRegsOut[7:0];
wire [7:0] fclk_sel = sfRegsOut[15:8];
wire [7:0] csb_sel  = sfRegsOut[(2*8)+:8];
wire adc_pdwn       = sfRegsOut[24];
wire dac_reset      = sfRegsOut[25];
wire adc_sync       = sfRegsOut[26];
wire pwr_sync       = sfRegsOut[27];
wire pwr_en_b       = sfRegsOut[28];
wire [1:0] bufr_reset= sfRegsOut[30:29];

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

wire [12:0] phdiff [3:0];
wire [15:0] f_clks [3:0];
assign sfRegsInp[    0+:16] = phdiff[phs_sel];        // SFR_IN_BYTE_PCNT
assign sfRegsInp[(2*8)+:16] = f_clks[fclk_sel];       // SFR_IN_BYTE_FCNT

//--------------------------------------------------------------
// CLK
//--------------------------------------------------------------
wire clk_to_fpga;
IBUFDS #(
    .DIFF_TERM("TRUE")
) ibuf_clk(
    .I      (CLK_TO_FPGA_P),
    .IB     (CLK_TO_FPGA_N),
    .O      (clk_to_fpga)
);

BUFG bufg_i (
    .I      (clk_to_fpga),
    .O      (dsp_clk_out)
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
    .refcnt_width   (FCNT_WIDTH),
    .freq_width     (16)
) fcnt_dsp (
    .sysclk     (clk),
    .f_in       (dsp_clk_out),
	.frequency  (f_clks[0])
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

    // ADV: 500*11/48/200/2*(1<<14) = 4693
    phase_diff #(.adv(4693)) phase_diff_i (
        .uclk1      (dsp_clk_out),
        .ext_div1   (1'b0),
        .uclk2      (clk_div[ix]),
        .ext_div2   (1'b0),
        .sclk       (clk_200),
        .rclk       (clk),
        .phdiff_out (phdiff[ix])
    );

    freq_count #(
        .refcnt_width   (FCNT_WIDTH),
        .freq_width     (16)
    ) fcnt_dco_i (
        .sysclk     (clk),
        .f_in       (clk_div[ix]),
        .frequency  (f_clks[ix+1])
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
    assign adc_out_data[16*ch+:16] = adc_out[ch]; // inverted by 0x14=0x7
end endgenerate

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
wire dac_dco_clk;
wire dac_dco_buf;
IBUFDS #(
    .DIFF_TERM("TRUE")
) ibuf_dco(
    .I      (DAC_DCO_P),
    .IB     (DAC_DCO_N),
    .O      (dac_dco_buf)
);

BUFG dco_bufg (
    .I      (dac_dco_buf),
    .O      (dac_dco_clk)
);

// ADV: 500*11/48/200/2*(1<<14) = 4693
phase_diff #(.adv(4693)) phase_diff_dac (
    .uclk1      (dsp_clk_out),
    .ext_div1   (1'b0),
    .uclk2      (dac_dco_clk),
    .ext_div2   (1'b0),
    .sclk       (clk_200),
    .rclk       (clk),
    .phdiff_out (phdiff[2])
);

freq_count #(
    .refcnt_width   (FCNT_WIDTH),
    .freq_width     (16)
) fcnt_dac_i (
    .sysclk     (clk),
    .f_in       (dac_dco_clk),
    .frequency  (f_clks[3])
);

wire [14:0] dac_oddr_buf;
wire [14:0] dac_oddr_d1 = {1'b0, dac_in_data_i};
wire [14:0] dac_oddr_d2 = {1'b1, dac_in_data_q};
wire [14:0] dac_oddr_out_p;
wire [14:0] dac_oddr_out_n;
assign DAC_DCI_P = dac_oddr_out_p[14];
assign DAC_DCI_N = dac_oddr_out_n[14];
assign DAC_D_P   = dac_oddr_out_p[13:0];
assign DAC_D_N   = dac_oddr_out_n[13:0];

genvar iy;
generate for (iy=0; iy < 15; iy=iy+1) begin: in_cell
	ODDR oddr(
        .C  (dsp_clk_out),
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
