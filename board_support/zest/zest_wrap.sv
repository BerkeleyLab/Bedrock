// Generic wrappers for Zest (digitizer) peripherals

module zest_wrap #(parameter u15_u18_spi_mode="passthrough") (
   input clk_200,
   // Zest peripheral pins
   zest_if.carrier   zif,
   // HW config interface
   zest_cfg_if.slave zif_cfg
);

   // LMK01801 - U1 - Dual Clock Distribution
   wire U1_DATAUWIRE;

   lmk01801 U1_lmk01801 (
      .CLKOUT3_INV     (zif.U1_CLKOUT3_INV),
      .CLKOUT3         (zif.U1_CLKOUT3),
      .CLKUWIRE        (), // P2_SCLK
      .DATAUWIRE       (U1_DATAUWIRE),
      .LEUWIRE         (zif.U1_LEUWIRE),
      .DATAUWIRE_IN    (1'b0),  // unused
      .clkuwire_in     (1'b0),
      .datauwire_inout (zif_cfg.U1_datauwire_inout),
      .leuwire_in      (zif_cfg.U1_leuwire_in),
      .clkout          (zif_cfg.U1_clkout)
   );

   // IDELAY control
   // clk200 should be 200MHz +/- 10MHz or 300MHz +/- 10MHz
   `ifndef SIMULATE
   (* IODELAY_GROUP = "IODELAY_200" *)
   IDELAYCTRL idelayctrl (
	.RST(zif_cfg.IDELAY_ctrl_rst),
	.REFCLK(clk_200),
	.RDY(zif_cfg.IDELAY_ctrl_rdy)
	);
   `endif

   // 2x AD9653 - U2, U3 - Fast ADC

   wire P2_ADC_DIR, P2_ADC_SDI, P2_ADC_SDO, P2_SCLK;
   ad9653 #(.FLIP_D(8'b11111111),.FLIP_DCO(1'b1),.FLIP_FRAME(1'b1),.BANK_CNT(1),
            .INFER_IOBUF(1)) // Use inferred IOBUF so it propagates to top-level
   U2_ad9653 (
      .D0NA (zif.U2_D0NA), .D0NB (zif.U2_D0NB),
      .D0NC (zif.U2_D0NC), .D0ND (zif.U2_D0ND),
      .D0PA (zif.U2_D0PA), .D0PB (zif.U2_D0PB),
      .D0PC (zif.U2_D0PC), .D0PD (zif.U2_D0PD),
      .D1NA (zif.U2_D1NA), .D1NB (zif.U2_D1NB),
      .D1NC (zif.U2_D1NC), .D1ND (zif.U2_D1ND),
      .D1PA (zif.U2_D1PA), .D1PB (zif.U2_D1PB),
      .D1PC (zif.U2_D1PC), .D1PD (zif.U2_D1PD),
      .DCON (zif.U2_DCON), .DCOP (zif.U2_DCOP),
      .FCON (zif.U2_FCON), .FCOP (zif.U2_FCOP),
      .PDWN (zif.U2_PDWN), .SYNC (),
      .CSB  (zif.U2_CSB),  .SCLK (zif.U2_SCLK), // Shared - P2_SCLK
      `ifndef VERILATOR
      // Shared - P2_ADC_SDIO
      .SDIO (zif.U4[1]), // True bi-dir connection
      `endif
      .csb_in           (zif_cfg.U2_csb_in),
      .sclk_in          (P2_SCLK),
      .sdi              (P2_ADC_SDI),
      .sdo              (P2_ADC_SDO),
      .sdio_as_i        (P2_ADC_DIR),
      .clk_reset        (zif_cfg.U2_clk_reset),
      .mmcm_reset       (zif_cfg.U2_mmcm_reset),
      .mmcm_locked      (zif_cfg.U2_mmcm_locked),
      .mmcm_psclk       (zif_cfg.U2_mmcm_psclk),
      .mmcm_psen        (zif_cfg.U2_mmcm_psen),
      .mmcm_psincdec    (zif_cfg.U2_mmcm_psincdec),
      .mmcm_psdone      (zif_cfg.U2_mmcm_psdone),
      .iserdes_reset    (zif_cfg.U2_iserdes_reset),
      .bitslip          (zif_cfg.U2_bitslip),
      .idelay_ce        (8'b0),
      .dout             (zif_cfg.U2_dout),
      .clk_div_bufr     (zif_cfg.U2_clk_div_bufr),
      .clk_div_bufg     (zif_cfg.U2_clk_div_bufg),
      .clk_div_in       (zif_cfg.U2_clk_div_in),
      .dco_clk_out      (zif_cfg.U2_dco_clk_out),
      .dco_clk_in       (zif_cfg.U2_dco_clk_in),
      .idelay_value_in  (zif_cfg.U2_idelay_value_in),
      .idelay_value_out (zif_cfg.U2_idelay_value_out),
      .idelay_ld        (zif_cfg.U2_idelay_ld),
      .pdwn_in          (zif_cfg.U2_pdwn));

   // SPI programming pins are shared (P2_{SCLK, SDIO, ADC_DIR})
   // Driving P2 pins through U2 wrapper above
   assign P2_SCLK    = zif_cfg.U2_sclk_in |
                       zif_cfg.U3_sclk_in |
                       zif_cfg.U1_clkuwire_in |
                       zif_cfg.U4_sclk_in;

   assign P2_ADC_DIR = zif_cfg.U2_sdio_as_i | zif_cfg.U3_sdio_as_i;
   assign P2_ADC_SDO = zif_cfg.U2_sdo | zif_cfg.U3_sdo; // Mutually exclusive
   assign zif_cfg.U2_sdi = P2_ADC_SDI;
   assign zif_cfg.U3_sdi = P2_ADC_SDI;

   ad9653 #(.FLIP_D(8'b11111111),.FLIP_DCO(1'b1),.FLIP_FRAME(1'b1),.BANK_CNT(2),
            .BANK_SEL({2'b0,2'b0,2'b0,2'b0,2'b1,2'b1,2'b1,2'b1}),
            .INFER_IOBUF(1))
   U3_ad9635 (
      .D0NA (zif.U3_D0NA), .D0NB (zif.U3_D0NB),
      .D0NC (zif.U3_D0NC), .D0ND (zif.U3_D0ND),
      .D0PA (zif.U3_D0PA), .D0PB (zif.U3_D0PB),
      .D0PC (zif.U3_D0PC), .D0PD (zif.U3_D0PD),
      .D1NA (zif.U3_D1NA), .D1NB (zif.U3_D1NB),
      .D1NC (zif.U3_D1NC), .D1ND (zif.U3_D1ND),
      .D1PA (zif.U3_D1PA), .D1PB (zif.U3_D1PB),
      .D1PC (zif.U3_D1PC), .D1PD (zif.U3_D1PD),
      .DCON (zif.U3_DCON), .DCOP (zif.U3_DCOP),
      .FCON (zif.U3_FCON), .FCOP (zif.U3_FCOP),
      .PDWN (zif.U3_PDWN), .SYNC (),
      .CSB  (zif.U3_CSB),  .SDIO (),
      .SCLK (), // P2_SCLK
      .csb_in           (zif_cfg.U3_csb_in),
      .sclk_in          (1'b0),
      .sdi              (zif_cfg.U3_sdi),  // TODO: Be consistent with above
      .sdo              (zif_cfg.U3_sdo),
      .sdio_as_i        (zif_cfg.U3_sdio_as_i),
      .clk_reset        (zif_cfg.U3_clk_reset),
      .mmcm_reset       (zif_cfg.U3_mmcm_reset),
      .mmcm_locked      (zif_cfg.U3_mmcm_locked),
      .mmcm_psclk       (zif_cfg.U3_mmcm_psclk),
      .mmcm_psen        (zif_cfg.U3_mmcm_psen),
      .mmcm_psincdec    (zif_cfg.U3_mmcm_psincdec),
      .mmcm_psdone      (zif_cfg.U3_mmcm_psdone),
      .iserdes_reset    (zif_cfg.U3_iserdes_reset),
      .bitslip          (zif_cfg.U3_bitslip),
      .idelay_ce        (8'b0),
      .dout             (zif_cfg.U3_dout),
      .clk_div_bufr     (zif_cfg.U3_clk_div_bufr),
      .clk_div_bufg     (zif_cfg.U3_clk_div_bufg),
      .clk_div_in       (zif_cfg.U3_clk_div_in),
      .dco_clk_out      (zif_cfg.U3_dco_clk_out),
      .dco_clk_in       (zif_cfg.U3_dco_clk_in),
      .idelay_value_in  (zif_cfg.U3_idelay_value_in),
      .idelay_value_out (zif_cfg.U3_idelay_value_out),
      .idelay_ld        (zif_cfg.U3_idelay_ld),
      .pdwn_in          (zif_cfg.U3_pdwn));

   // AD9781 - U4 - Fast DAC
   wire U4_SDIO;
   ad9781 U4_ad9781 (
      .D0N   (zif.U4_D0N),  .D0P  (zif.U4_D0P),
      .D1N   (zif.U4_D1N),  .D1P  (zif.U4_D1P),
      .D2N   (zif.U4_D2N),  .D2P  (zif.U4_D2P),
      .D3N   (zif.U4_D3N),  .D3P  (zif.U4_D3P),
      .D4N   (zif.U4_D4N),  .D4P  (zif.U4_D4P),
      .D5N   (zif.U4_D5N),  .D5P  (zif.U4_D5P),
      .D6N   (zif.U4_D6N),  .D6P  (zif.U4_D6P),
      .D7N   (zif.U4_D7N),  .D7P  (zif.U4_D7P),
      .D8N   (zif.U4_D8N),  .D8P  (zif.U4_D8P),
      .D9N   (zif.U4_D9N),  .D9P  (zif.U4_D9P),
      .D10N  (zif.U4_D10N), .D10P (zif.U4_D10P),
      .D11N  (zif.U4_D11N), .D11P (zif.U4_D11P),
      .D12N  (zif.U4_D12N), .D12P (zif.U4_D12P),
      .D13N  (zif.U4_D13N), .D13P (zif.U4_D13P),
      .DCIN  (zif.U4_DCIN), .DCIP (zif.U4_DCIP),
      .DCON  (zif.U4_DCON), .DCOP (zif.U4_DCOP),
      .RESET (zif.U4_RESET),
      .CSB   (zif.U4_CSB),
      .SDIO  (U4_SDIO),
      .SDO   (zif.U4_SDO), .SCLK (), // P2_SCLK
      .csb_in      (zif_cfg.U4_csb_in),
      .sclk_in     (1'b0),
      .sdo_out     (zif_cfg.U4_sdo_out),
      .sdio_inout  (zif_cfg.U4_sdio_inout),
      .data_i      (zif_cfg.U4_data_i),
      .data_q      (zif_cfg.U4_data_q),
      .dco_clk_out (zif_cfg.U4_dco_clk_out),
      .dci         (zif_cfg.U4_dci),
      .reset_in    (zif_cfg.U4_reset));

   // Shared - P2_SDI
   assign zif.U4_SDIO = U4_SDIO | U1_DATAUWIRE;

   // NXP_74AVC4T245 - U27 - Bi-dir direction selector; P2_ADC_DIR
   assign zif.U27_dir = zif_cfg.U27_dir;

   // TPS62110 - U33U1 - DC-DC converter
   assign zif.U33U1_pwr_en   = zif_cfg.U33U1_pwr_en;
   assign zif.U33U1_pwr_sync = zif_cfg.U33U1_pwr_sync;

   // AMC7823 - U15 - Multichannel ADC/DAC for monitoring/control

   amc7823 #(.SPIMODE(u15_u18_spi_mode)) U15_amc7823 (
      .ss          (zif.U15_SS),
      .miso        (zif.U15_MISO),
      .mosi        (zif_cfg.U15_mosi_out),
      .sclk        (zif_cfg.U15_sclk_out),
      .clk         (zif_cfg.U15_clk),
      .spi_start   (zif_cfg.U15_spi_start),
      .spi_addr    (zif_cfg.U15_spi_addr),
      .spi_read    (zif_cfg.U15_spi_read),
      .spi_data    (zif_cfg.U15_spi_data),
      .sdo_addr    (zif_cfg.U15_sdo_addr),
      .spi_rdbk    (zif_cfg.U15_spi_rdbk),
      .spi_ready   (zif_cfg.U15_spi_ready),
      .sdio_as_sdo (zif_cfg.U15_sdio_as_sdo),
      .sclk_in     (zif_cfg.U15_sclk_in),
      .mosi_in     (zif_cfg.U15_mosi_in),
      .ss_in       (zif_cfg.U15_ss_in),
      .miso_out    (zif_cfg.U15_miso_out),
      .spi_ssb_in  (zif_cfg.U15_spi_ssb_in),
      .spi_ssb_out (zif_cfg.U15_spi_ssb_out));

   // AD7794 - U18 - Thermometer readout

   ad7794 #(.SPIMODE(u15_u18_spi_mode)) U18_ad7794 (
      .CLK         (zif.U18_CLK),
      .CS          (zif.U18_CS),
      .DOUT_RDY    (zif.U18_DOUT_RDY),
      .DIN         (zif_cfg.U18_mosi_out),
      .SCLK        (zif_cfg.U18_sclk_out),
      .clkin       (zif_cfg.U18_clkin),
      .spi_start   (zif_cfg.U18_spi_start),
      .spi_addr    (zif_cfg.U18_spi_addr),
      .spi_read    (zif_cfg.U18_spi_read),
      .spi_data    (zif_cfg.U18_spi_data),
      .sdo_addr    (zif_cfg.U18_sdo_addr),
      .spi_rdbk    (zif_cfg.U18_spi_rdbk),
      .spi_ready   (zif_cfg.U18_spi_ready),
      .sdio_as_sdo (zif_cfg.U18_sdio_as_sdo),
      .sclk_in     (zif_cfg.U18_sclk_in),
      .mosi_in     (zif_cfg.U18_mosi_in),
      .ss_in       (zif_cfg.U18_ss_in),
      .miso_out    (zif_cfg.U18_miso_out),
      .spi_ssb_in  (zif_cfg.U18_spi_ssb_in),
      .spi_ssb_out (zif_cfg.U18_spi_ssb_out),
      .adcclk      (zif_cfg.U18_adcclk));

   generate if (u15_u18_spi_mode == "passthrough") begin: passthrough
     assign zif.U18_DIN  = zif_cfg.U18_mosi_out | zif_cfg.U15_mosi_out;
     assign zif.U18_SCLK = zif_cfg.U18_sclk_out | zif_cfg.U15_sclk_out;
   end else begin
     assign zif.U18_DIN  = zif_cfg.U15_U18_mosi;
     assign zif.U18_SCLK = zif_cfg.U15_U18_sclk;
   end endgenerate

endmodule
