module fmc150 #(
    parameter BASE_ADDR = 8'h00
) (
    //-----------------------------------
    // PicoRV32 packed MEM Bus interface
    //-----------------------------------
    input           clk,
    input           reset,
    input  [68:0]   mem_packed_fwd,
    output [32:0]   mem_packed_ret,

    //-----------------------------------
    // FMC LPC connector pins
    //-----------------------------------
    // The 4 chips share common SPI clock and data lines
    output          FMC150_SPI_SCLK,
    output          FMC150_SPI_SDATA,
    // Reset lines
    output          FMC150_CDCE_N_RESET,
    output          FMC150_ADC_RESET,
    output          FMC150_MON_N_RESET,
    // Active Low SPI chip enable signals
    output          FMC150_CDCE_N_EN,  // CDCE72010
    output          FMC150_ADC_N_EN,   // ADS62P49
    output          FMC150_DAC_N_EN,   // DAC3283
    output          FMC150_TXENABLE,   // DAC3283
    output          FMC150_MON_N_EN,   // AMC7823
    output          FMC150_CDCE_N_PD,  // CDCE72010
    output          FMC150_REF_EN,     // CCPD-033 (active high)
    // MISO return lines from the 4 chips
    input           FMC150_CDCE_SDO,
    input           FMC150_ADC_SDO,
    input           FMC150_DAC_SDO,
    input           FMC150_MON_SDO,
    // ADS62P49 LVDS interface
    input           FMC150_CLK_AB_P,
    input           FMC150_CLK_AB_N,
    input [6:0]     FMC150_CHA_P,
    input [6:0]     FMC150_CHA_N,
    input [6:0]     FMC150_CHB_P,
    input [6:0]     FMC150_CHB_N,
    // DAC LVDS interface
    output          FMC150_FRAME_P,     // Frame marker
    output          FMC150_FRAME_N,
    output          FMC150_DAC_DCLK_P,  // LVDS data clock
    output          FMC150_DAC_DCLK_N,
    output [7:0]    FMC150_DAC_D_P,     // LVDS data lanes
    output [7:0]    FMC150_DAC_D_N,

    input           FMC150_CLK_TO_FPGA_P,
    input           FMC150_CLK_TO_FPGA_N,
    input           FMC150_PLL_STATUS,
    input           FMC150_PRSNT_M2C_L,
    output          FMC150_PG_C2M,

    //-----------------------------------
    // Samples & clks
    //-----------------------------------
    // Clock out
    output          clk_to_fpga_out,    // from CDCE72010, channel 4
    // ADC
    output [13:0]   ads62_outA,
    output [13:0]   ads62_outB,
    output          ads62_clkAB,
    // DAC
    input  [15:0]   dac_inA,
    input  [15:0]   dac_inB,
    output          dac_clk_out,        // DAC DATACLK
    input           dac_clk_in          // DAC DATACLK
);

wire [32:0] packed_sfr_ret;
wire [32:0] packed_spi_ret;
wire [32:0] packed_adc_ret;
wire [32:0] packed_dac_ret;

assign mem_packed_ret = packed_sfr_ret |
                        packed_spi_ret |
                        packed_adc_ret |
                        packed_dac_ret;

//--------------------------------------------------------------
// BASE2 Address offsets
//--------------------------------------------------------------
localparam BASE_SFR   = 8'h00;
localparam BASE_SPI   = 8'h01;
localparam BASE_ADC   = 8'h02; // Takes 2 addresses
localparam BASE_DAC   = 8'h04;

//--------------------------------------------------------------
// DAC3283 LVDS interface
//--------------------------------------------------------------
dac3283 #(
    .BASE_ADDR       (BASE_ADDR),
    .BASE2_OFFSET    (BASE_DAC)
) dac_inst (
    .FRAME_P          (FMC150_FRAME_P),
    .FRAME_N          (FMC150_FRAME_N),
    .DAC_DCLK_P       (FMC150_DAC_DCLK_P),
    .DAC_DCLK_N       (FMC150_DAC_DCLK_N),
    .DAC_D_P          (FMC150_DAC_D_P),
    .DAC_D_N          (FMC150_DAC_D_N),
    .dac_inA          (dac_inA),
    .dac_inB          (dac_inB),
    .dac_clk_in       (dac_clk_in),
    .dac_clk_out      (dac_clk_out),
    .clk              (clk             ),
    .rst              (reset           ),
    .mem_packed_fwd   (mem_packed_fwd  ),
    .mem_packed_ret   (packed_dac_ret  )
);

//--------------------------------------------------------------
// ADS62P49 LVDS interface
//--------------------------------------------------------------
ads62 #(
    .BASE_ADDR       (BASE_ADDR),
    .BASE2_OFFSET    (BASE_ADC), // Takes 2 addresses
    .REFCLK_FREQUENCY(200.0)
) ads62_inst (
    .clk_ab_p      (FMC150_CLK_AB_P ),
    .clk_ab_n      (FMC150_CLK_AB_N ),
    .inA_p         (FMC150_CHA_P    ),
    .inA_n         (FMC150_CHA_N    ),
    .inB_p         (FMC150_CHB_P    ),
    .inB_n         (FMC150_CHB_N    ),
    .outA          (ads62_outA      ),
    .outB          (ads62_outB      ),
    .clk_ab_del    (ads62_clkAB     ),
    .clk           (clk             ),
    .rst           (reset           ),
    .mem_packed_fwd(mem_packed_fwd  ),
    .mem_packed_ret(packed_adc_ret  )
);

//--------------------------------------------------------------
// PicoRV SFR (GPIO output pins)
//--------------------------------------------------------------
wire [31:0] gpio_o;
wire [31:0] sfRegsIn;
sfr_pack #(
    .BASE_ADDR      (BASE_ADDR      ),
    .BASE2_ADDR     (BASE_SFR       ),
    .N_REGS         (1              )
) sfrInst (
    .clk            (clk            ),
    .rst            (reset          ),
    .mem_packed_fwd (mem_packed_fwd ),
    .mem_packed_ret (packed_sfr_ret ),
    .sfRegsOut      (gpio_o         ),
    .sfRegsIn       (sfRegsIn       ),
    .sfRegsWrStr    ()
);
// Peripheral RESET pins
assign FMC150_CDCE_N_RESET= gpio_o[    0];
assign FMC150_ADC_RESET   = gpio_o[    1];
assign FMC150_MON_N_RESET = gpio_o[    2];
assign FMC150_CDCE_N_PD   = gpio_o[    3];
// Peripheral SPI /chip_select pins
assign FMC150_CDCE_N_EN   = gpio_o[    8];
assign FMC150_ADC_N_EN    = gpio_o[    9];
assign FMC150_DAC_N_EN    = gpio_o[   10];
assign FMC150_TXENABLE    = gpio_o[   11];
assign FMC150_MON_N_EN    = gpio_o[   12];
assign FMC150_REF_EN      = gpio_o[   13];
assign FMC150_PG_C2M      = gpio_o[   14];
assign sfRegsIn[14: 0]    = gpio_o[14: 0];
assign sfRegsIn[   15]    = FMC150_PRSNT_M2C_L;
assign sfRegsIn[   16]    = FMC150_PLL_STATUS;
assign sfRegsIn[31:17]    = 14'h0;

//--------------------------------------------------------------
// PicoRV SPI master
//--------------------------------------------------------------
// Only the slave which has its SS line low may speak to the master
wire spi_miso = (!FMC150_CDCE_N_EN) ? FMC150_CDCE_SDO :
                (!FMC150_ADC_N_EN ) ? FMC150_ADC_SDO  :
                (!FMC150_DAC_N_EN ) ? FMC150_DAC_SDO  :
                (!FMC150_MON_N_EN ) ? FMC150_MON_SDO  : 1'b0;
spi_pack #(
    .BASE_ADDR      (BASE_ADDR      ),
    .BASE2_ADDR     (BASE_SPI       ) // Takes 1 BASE2 slot at BASE_SPI
) spi_master (
    .clk            (clk            ),
    .rst            (reset          ),
    .spi_ss         (               ),
    .spi_sck        (FMC150_SPI_SCLK),
    .spi_mosi       (FMC150_SPI_SDATA),
    .spi_miso       (spi_miso       ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd (mem_packed_fwd ),
    .mem_packed_ret (packed_spi_ret)
);

wire clk_to_fpga_i;

IBUFDS #(
    .DIFF_TERM("TRUE")
) ibuf_clk(
    .I      (FMC150_CLK_TO_FPGA_P),
    .IB     (FMC150_CLK_TO_FPGA_N),
    .O      (clk_to_fpga_i)
);

BUFG bufg_i (
    .I      (clk_to_fpga_i),
    .O      (clk_to_fpga_out)
);
endmodule // fmc150
