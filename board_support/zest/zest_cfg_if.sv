interface zest_cfg_if;

   // IDELAYCTRL
   wire IDELAY_ctrl_rst, IDELAY_ctrl_rdy;

   // LMK01801 - U1 - Dual Clock Distribution
   wire U1_datauwire_inout, U1_leuwire_in, U1_clkuwire_in, U1_clkout;

   // 2x AD9653 - U2, U3 - Fast ADC
   wire [63:0] U2_dout;
   wire [39:0] U2_idelay_value_in, U2_idelay_value_out;
   wire [ 7:0] U2_bitslip, U2_idelay_ld;
   wire U2_csb_in, U2_sclk_in, U2_sdi, U2_sdo, U2_sdio_as_i,
        U2_clk_reset, U2_mmcm_reset, U2_mmcm_locked, U2_mmcm_psclk,
        U2_mmcm_psen, U2_mmcm_psincdec, U2_mmcm_psdone, U2_iserdes_reset,
        U2_clk_div_bufr, U2_clk_div_bufg,
        U2_clk_div_in, U2_dco_clk_out, U2_dco_clk_in, U2_pdwn;
   wire [63:0] U3_dout;
   wire [39:0] U3_idelay_value_in, U3_idelay_value_out;
   wire [ 7:0] U3_bitslip, U3_idelay_ld;
   wire [ 1:0] U3_dco_clk_in, U3_clk_div_in, U3_iserdes_reset;
   wire U3_csb_in, U3_sclk_in, U3_sdi, U3_sdo, U3_sdio_as_i,
        U3_clk_reset, U3_mmcm_reset, U3_mmcm_locked, U3_mmcm_psclk, U3_mmcm_psen,
        U3_mmcm_psincdec, U3_mmcm_psdone,
        U3_clk_div_bufr, U3_clk_div_bufg, U3_dco_clk_out, U3_pdwn;

   // AD9781 - U4 - Fast DAC
   wire [13:0] U4_data_i, U4_data_q;
   wire U4_csb_in, U4_sclk_in, U4_sdo_out, U4_sdio_inout,
        U4_dco_clk_out, U4_dci, U4_reset;

   // NXP_74AVC4T245 - U27 - Bi-dir direction selector
   wire U27_dir;

   // TPS62110 - U33U1 - DC-DC converter
   wire U33U1_pwr_en, U33U1_pwr_sync;

   // AMC7823 - U15 - Multichannel ADC/DAC for monitoring/control
   wire [15:0] U15_spi_addr, U15_spi_data, U15_sdo_addr, U15_spi_rdbk;
   wire U15_mosi, U15_sclk, U15_clk, U15_spi_start, U15_spi_read,
        U15_spi_ready, U15_sdio_as_sdo, U15_sclk_in,
        U15_mosi_in, U15_ss_in, U15_miso_out, U15_spi_ssb_in,
        U15_spi_ssb_out;
   wire U15_sclk_out;
   wire U15_mosi_out;

   // AD7794 - U18 - Thermometer readout
   wire [ 7:0] U18_spi_addr, U18_sdo_addr;
   wire [23:0] U18_spi_data, U18_spi_rdbk;
   wire U18_DIN, U18_SCLK, U18_clkin, U18_spi_start, U18_spi_read,
        U18_spi_ready, U18_sdio_as_sdo, U18_sclk_in,
        U18_mosi_in, U18_ss_in, U18_miso_out, U18_spi_ssb_in,
        U18_spi_ssb_out, U18_adcclk;
   wire U18_sclk_out;
   wire U18_mosi_out;
   wire U15_U18_mosi, U15_U18_sclk;

   modport master (
      // IDELAY_mst
      input  IDELAY_ctrl_rdy, output IDELAY_ctrl_rst,
      // LMK01801_mst
      output U1_datauwire_inout, U1_leuwire_in, U1_clkuwire_in, input U1_clkout,
      // AD9653_mst
      input  U2_dout, U2_dco_clk_out, U2_idelay_value_out, U2_mmcm_psdone,
             U2_mmcm_locked, U2_sdi, U2_clk_div_bufg, U2_clk_div_bufr,
      output U2_idelay_value_in, U2_bitslip, U2_idelay_ld, U2_pdwn,
             U2_iserdes_reset, U2_clk_reset, U2_mmcm_psclk, U2_mmcm_psen,
             U2_mmcm_psincdec, U2_mmcm_reset, U2_sdo,
             U2_dco_clk_in, U2_clk_div_in,
             U2_sdio_as_i, U2_csb_in, U2_sclk_in,
      input  U3_dout, U3_dco_clk_out, U3_idelay_value_out, U3_mmcm_psdone,
             U3_mmcm_locked, U3_sdi, U3_clk_div_bufg, U3_clk_div_bufr,
      output U3_idelay_value_in, U3_bitslip, U3_idelay_ld, U3_pdwn,
             U3_iserdes_reset, U3_clk_reset, U3_mmcm_psclk, U3_mmcm_psen,
             U3_mmcm_psincdec, U3_mmcm_reset, U3_sdo,
             U3_dco_clk_in, U3_clk_div_in,
             U3_sdio_as_i, U3_csb_in, U3_sclk_in,
      // AD9781_mst
      output U4_csb_in, U4_sclk_in, U4_sdio_inout, U4_data_i, U4_data_q,
             U4_dci, U4_reset,

      input  U4_sdo_out, U4_dco_clk_out,
      // NXP_74AVC4T245_mst
      output U27_dir,
      // TPS62110_mst
      output U33U1_pwr_en, U33U1_pwr_sync,
      // AMC7823_mst
      output U15_clk, U15_spi_start, U15_spi_addr, U15_spi_read,
             U15_spi_data, U15_sclk_in, U15_mosi_in, U15_ss_in,
             U15_spi_ssb_in,
      input  U15_sdo_addr, U15_spi_rdbk, U15_spi_ready, U15_sdio_as_sdo,
             U15_miso_out, U15_sclk, U15_mosi, U15_spi_ssb_out,
      input  U15_sclk_out, U15_mosi_out,
      // AD7794_mst
      output U18_sclk_in, U18_mosi_in, U18_spi_ssb_in, U18_adcclk,
             U18_ss_in, U18_clkin, U18_spi_start, U18_spi_addr,
             U18_spi_read, U18_spi_data,
      input  U18_SCLK, U18_DIN, U18_miso_out, U18_spi_ssb_out,
             U18_sdo_addr, U18_spi_rdbk, U18_spi_ready, U18_sdio_as_sdo,
      input  U18_sclk_out, U18_mosi_out,
      output U15_U18_mosi, U15_U18_sclk);

   modport slave (
      // IDELAY_slv
      output IDELAY_ctrl_rdy, input IDELAY_ctrl_rst,
      // LMK01801_slv
      input  U1_datauwire_inout, U1_leuwire_in, U1_clkuwire_in, output U1_clkout,
      // AD9653_slv
      output U2_dout, U2_dco_clk_out, U2_idelay_value_out, U2_mmcm_psdone,
             U2_mmcm_locked, U2_sdi, U2_clk_div_bufg, U2_clk_div_bufr,
      input  U2_idelay_value_in, U2_bitslip, U2_idelay_ld, U2_pdwn,
             U2_iserdes_reset, U2_clk_reset, U2_mmcm_psclk, U2_mmcm_psen,
             U2_mmcm_psincdec, U2_mmcm_reset, U2_sdo,
             U2_dco_clk_in, U2_clk_div_in,
             U2_sdio_as_i, U2_csb_in, U2_sclk_in,
      output U3_dout, U3_dco_clk_out, U3_idelay_value_out, U3_mmcm_psdone,
             U3_mmcm_locked, U3_sdi, U3_clk_div_bufg, U3_clk_div_bufr,
      input  U3_idelay_value_in, U3_bitslip, U3_idelay_ld, U3_pdwn,
             U3_iserdes_reset, U3_clk_reset, U3_mmcm_psclk, U3_mmcm_psen,
             U3_mmcm_psincdec, U3_mmcm_reset, U3_sdo,
             U3_dco_clk_in, U3_clk_div_in,
             U3_sdio_as_i, U3_csb_in, U3_sclk_in,
      // AD9781_slv
      input  U4_csb_in, U4_sclk_in, U4_sdio_inout, U4_data_i, U4_data_q,
             U4_dci, U4_reset,
      output U4_sdo_out, U4_dco_clk_out,
      // NXP_74AVC4T245_slv
      input  U27_dir,
      // TPS62110_slv
      input  U33U1_pwr_en, U33U1_pwr_sync,
      // AMC7823_slv
      input  U15_clk, U15_spi_start, U15_spi_addr, U15_spi_read,
             U15_spi_data, U15_sclk_in, U15_mosi_in, U15_ss_in,
             U15_spi_ssb_in,
      output U15_sdo_addr, U15_spi_rdbk, U15_spi_ready, U15_sdio_as_sdo,
             U15_miso_out, U15_sclk, U15_mosi, U15_spi_ssb_out,
      output U15_sclk_out, U15_mosi_out,
      // AD7794_slv
      input  U18_sclk_in, U18_mosi_in, U18_spi_ssb_in, U18_adcclk,
             U18_ss_in, U18_clkin, U18_spi_start, U18_spi_addr,
             U18_spi_read, U18_spi_data,
      output U18_SCLK, U18_DIN, U18_miso_out, U18_spi_ssb_out,
             U18_sdo_addr, U18_spi_rdbk, U18_spi_ready, U18_sdio_as_sdo,
      output U18_sclk_out, U18_mosi_out,
      input  U15_U18_mosi, U15_U18_sclk);


endinterface
