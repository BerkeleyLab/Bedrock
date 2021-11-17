from migen import *

from litex.build.generic_platform import Subsignal, Pins, IOStandard, Misc
from litex.soc.interconnect.csr import AutoCSR

zest_pads = [
    ("ZEST_DAC_D", 0,
     Subsignal("p", Pins("LA14_P LA13_P LA12_P LA09_P LA08_P LA15_P LA11_P LA07_P LA04_P LA05_P LA06_P LA03_P LA00_P LA02_P ")),
     Subsignal("n", Pins("LA14_N LA13_N LA12_N LA09_N LA08_N LA15_N LA11_N LA07_N LA04_N LA05_N LA06_N LA03_N LA00_N LA02_N ")),
     IOStandard("LVDS_25")),
    ("ZEST_ADC_D", 0,
     Subsignal("p", Pins("FMC1_LPC:LA09_P FMC1_LPC:LA05_P FMC1_LPC:LA02_P FMC1_LPC:LA03_P FMC1_LPC:LA22_P FMC1_LPC:LA18_P_CC FMC1_LPC:LA15_P FMC1_LPC:LA14_P")),
     Subsignal("n", Pins("FMC1_LPC:LA09_N FMC1_LPC:LA05_N FMC1_LPC:LA02_N FMC1_LPC:LA03_N FMC1_LPC:LA22_N FMC1_LPC:LA18_N_CC FMC1_LPC:LA15_N FMC1_LPC:LA14_N")),
     IOStandard("LVDS_25")),
    ("ZEST_ADC_D", 1,
     Subsignal("p", Pins("FMC1_LPC:LA08_P FMC1_LPC:LA07_P FMC1_LPC:LA06_P FMC1_LPC:LA01_P FMC1_LPC:LA20_P FMC1_LPC:LA21_P FMC1_LPC:LA16_P FMC1_LPC:LA11_P")),
     Subsignal("n", Pins("FMC1_LPC:LA08_N FMC1_LPC:LA07_N FMC1_LPC:LA06_N FMC1_LPC:LA01_N FMC1_LPC:LA20_N FMC1_LPC:LA21_N FMC1_LPC:LA16_P FMC1_LPC:LA11_P")),
     IOStandard("LVDS_25")),
    ("ZEST_PMOD", 0,
     Pins("FMC1_LPC:LA29_P FMC1_LPC:LA25_P FMC1_LPC:LA27_P FMC1_LPC:LA26_P FMC1_LPC:LA29_N FMC1_LPC:LA25_N FMC1_LPC:LA27_N FMC1_LPC:LA26_N"),
     IOStandard("LVCMOS25")),
    ("ZEST_PMOD", 1,
     Pins("FMC1_LPC:LA18_P FMC1_LPC:LA18_N FMC1_LPC:LA23_P FMC1_LPC:LA23_N FMC1_LPC:LA20_P FMC1_LPC:LA20_N FMC1_LPC:LA25_P FMC1_LPC:LA25_N"),
     IOStandard("LVCMOS25")),
    ("ZEST_HDMI_DIFF", 0,
     Subsignal("ck_p", Pins("FMC1_LPC:LA32_P"), IOStandard("LVDS_25")),
     Subsignal("ck_n", Pins("FMC1_LPC:LA32_N"), IOStandard("LVDS_25")),
     Subsignal("D0_p", Pins("FMC1_LPC:LA30_P"), IOStandard("LVDS_25")),
     Subsignal("DO_n", Pins("FMC1_LPC:LA30_N"), IOStandard("LVDS_25")),
     Subsignal("D1_p", Pins("FMC1_LPC:LA28_P"), IOStandard("LVDS_25")),
     Subsignal("D1_n", Pins("FMC1_LPC:LA28_N"), IOStandard("LVDS_25")),
     Subsignal("D2_p", Pins("FMC1_LPC:LA24_P"), IOStandard("LVDS_25")),
     Subsignal("D2_n", Pins("FMC1_LPC:LA24_N"), IOStandard("LVDS_25")),
    ),
    ("ZEST_HDMI_REST", 0,
     Subsignal("sda", Pins("FMC1_LPC:LA33_P"), IOStandard("LVCMOS25")),
     Subsignal("scl", Pins("FMC1_LPC:LA31_N"), IOStandard("LVCMOS25")),
     Subsignal("cec", Pins("FMC1_LPC:LA31_P"), IOStandard("LVCMOS25")),
     Subsignal("det", Pins("FMC1_LPC:LA33_N"), IOStandard("LVCMOS25")),
    ),
    ("ZEST_CLK_TO_FPGA", 0,
     Subsignal("p", Pins("FMC1_LPC:LA10_P"), IOStandard("LVDS_25")),
     Subsignal("n", Pins("FMC1_LPC:LA10_N"), IOStandard("LVDS_25")),
    ),
    ("ZEST_CLK_TO_FPGA", 1,
     Subsignal("p", Pins("FMC2_LPC:CLK0_M2C_P"), IOStandard("LVDS_25")),
     Subsignal("n", Pins("FMC2_LPC:CLK0_M2C_N"), IOStandard("LVDS_25")),
    ),
    ("ZEST_ADC_PDWN"         , 0, Pins("FMC2_LPC:LA16_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_CSB_0"        , 0, Pins("FMC2_LPC:LA31_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SYNC"         , 0, Pins("FMC2_LPC:LA33_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SCLK"         , 0, Pins("FMC2_LPC:LA29_N"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SDI"          , 0, Pins("FMC2_LPC:LA29_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_CSB_1"        , 0, Pins("FMC2_LPC:LA31_N"), IOStandard("LVCMOS25")),
    ("ZEST_LMK_LEUWIRE"      , 0, Pins("FMC2_LPC:LA21_P"), IOStandard("LVCMOS25")),
    ("ZEST_PWR_SYNC"         , 0, Pins("FMC2_LPC:LA27_P"), IOStandard("LVCMOS25")),
    ("ZEST_PWR_EN"           , 0, Pins("FMC2_LPC:LA27_N"), IOStandard("LVCMOS25")),
    ("ZEST_AD7794_FCLK"      , 0, Pins("FMC2_LPC:LA22_P"), IOStandard("LVCMOS25")),
    ("ZEST_DAC_CSB"          , 0, Pins("FMC2_LPC:LA19_N"), IOStandard("LVCMOS25")),
    ("ZEST_AMC7823_SPI_SS"   , 0, Pins("FMC2_LPC:LA24_N"), IOStandard("LVCMOS25")),
    ("ZEST_AD7794_CSB"       , 0, Pins("FMC2_LPC:LA26_P"), IOStandard("LVCMOS25")),
    ("ZEST_DAC_RESET"        , 0, Pins("FMC2_LPC:LA21_N"), IOStandard("LVCMOS25")),
    ("ZEST_POLL_SCLK"        , 0, Pins("FMC2_LPC:LA16_N"), IOStandard("LVCMOS25")),
    ("ZEST_POLL_MOSI"        , 0, Pins("FMC2_LPC:LA33_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SDIO_DIR"     , 0, Pins("FMC2_LPC:LA28_N"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SDIO"         , 0, Pins("FMC2_LPC:LA28_P"), IOStandard("LVCMOS25")),
    ("ZEST_AMC7823_SPI_MISO" , 0, Pins("FMC2_LPC:LA24_P"), IOStandard("LVCMOS25")),
    ("ZEST_LMK_DATAUWIRE"    , 0, Pins("FMC2_LPC:LA22_N"), IOStandard("LVCMOS25")),
    ("ZEST_AD7794_DOUT"      , 0, Pins("FMC2_LPC:LA26_N"), IOStandard("LVCMOS25")),
    ("ZEST_DAC_SDO"          , 0, Pins("FMC2_LPC:LA19_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_DCO" , 0,
     Subsignal("p", Pins("FMC1_LPC:LA00_P FMC1_LPC:LALA17_P_CC"), IOStandard("LVDS_25")),
     Subsignal("n", Pins("FMC1_LPC:LA00_N FMC1_LPC:LALA17_N_CC"), IOStandard("LVDS_25")),
    ),
    ("ZEST_DAC_DCO" , 0,
     Subsignal("p", Pins("FMC1_LPC:LA17_P"), IOStandard("LVDS_25")),
     Subsignal("n", Pins("FMC1_LPC:LA17_N"), IOStandard("LVDS_25")),
    ),
    ("ZEST_CLK_TO_FPGA", 1,
     Subsignal("p", Pins("FMC2_LPC:CLK0_M2C_P"), IOStandard("LVCMOS25")),
     Subsignal("n", Pins("FMC2_LPC:CLK0_M2C_N"), IOStandard("LVCMOS25")),
    ),
]

class Zest(Module, AutoCSR):

    def add_sources(self, platform):
        sources = [
            "../../board_support/zest_soc/zest.v",
            "../../board_support/zest_soc/zest_clk_map.v",
            "../../board_support/zest_soc/zest_spi_dio_pack.v",
            "../../dsp/freq_count.v",
            "../../dsp/phase_diff.v",
            "../../dsp/flag_xdomain.v",
            "../../dsp/data_xdomain.v",
            "../../dsp/dpram.v",
            "../../soc/picorv32/gateware/sfr_pack.v",
            "../../soc/picorv32/gateware/munpack.v",
            "../../soc/picorv32/gateware/picorv32.v",
            "../../soc/picorv32/gateware/spi_engine.v",
            "../../board_support/fmc11x/dco_buf.v",
            "../../board_support/fmc11x/iserdes_pack.v",
            "../../board_support/fmc11x/idelays_pack.v",
            "../../board_support/fmc11x/wfm_pack.v",
        ]
        platform.add_sources("../", *sources)

    def __init__(self, platform):
        self.ADC_PDWN         = platform.request("ZEST_ADC_PDWN")
        self.ADC_CSB_0        = platform.request("ZEST_ADC_PDWN")
        self.ADC_SYNC         = platform.request("ZEST_ADC_PDWN")
        self.SCLK             = platform.request("ZEST_SCLK")
        self.SDI              = platform.request("ZEST_SDI")
        self.ADC_CSB_1        = platform.request("ZEST_ADC_CSB_1")
        self.LMK_LEUWIRE      = platform.request("ZEST_LMK_LEUWIRE")
        self.PWR_SYNC         = platform.request("ZEST_PWR_SYNC")
        self.PWR_EN           = platform.request("ZEST_PWR_EN")
        self.AD7794_FCLK      = platform.request("ZEST_AD7794_FCLK")
        self.DAC_CSB          = platform.request("ZEST_DAC_CSB")
        self.AMC7823_SPI_SS   = platform.request("ZEST_AMC7823_SPI_SS")
        self.AD7794_CSB       = platform.request("ZEST_AD7794_CSB")
        self.DAC_RESET        = platform.request("ZEST_DAC_RESET")
        self.POLL_SCLK        = platform.request("ZEST_POLL_SCLK")
        self.POLL_MOSI        = platform.request("ZEST_POLL_MOSI")
        self.ADC_SDIO_DIR     = platform.request("ZEST_ADC_SDIO_DIR")
        self.ADC_SDIO         = platform.request("ZEST_ADC_SDIO")
        self.AMC7823_SPI_MISO = platform.request("ZEST_AMC7823_SPI_MISO")
        self.LMK_DATAUWIRE    = platform.request("ZEST_LMK_DATAUWIRE")
        self.AD7794_DOUT      = platform.request("ZEST_AD7794_DOUT")
        self.DAC_SDO          = platform.request("ZEST_DAC_SDO")
        self.CLK_TO_FPGA_P    = platform.request("ZEST_CLK_TO_FPGA_P")
        self.CLK_TO_FPGA_N    = platform.request("ZEST_CLK_TO_FPGA_N")
        self.ADC_D0_P         = platform.request("ZEST_ADC_D0_P")
        self.ADC_D0_N         = platform.request("ZEST_ADC_D0_N")
        self.ADC_D1_P         = platform.request("ZEST_ADC_D1_P")
        self.ADC_D1_N         = platform.request("ZEST_ADC_D1_N")
        self.ADC_DCO_P        = platform.request("ZEST_ADC_DCO_P")
        self.ADC_DCO_N        = platform.request("ZEST_ADC_DCO_N")
        self.ADC_FCO_P        = platform.request("ZEST_ADC_FCO_P")
        self.ADC_FCO_N        = platform.request("ZEST_ADC_FCO_N")
        self.DAC_D_P          = platform.request("ZEST_DAC_D_P")
        self.DAC_D_N          = platform.request("ZEST_DAC_D_N")
        self.DAC_DCI_P        = platform.request("ZEST_DAC_DCI_P")
        self.DAC_DCI_N        = platform.request("ZEST_DAC_DCI_N")
        self.DAC_DCO_P        = platform.request("ZEST_DAC_DCO_P")
        self.DAC_DCO_N        = platform.request("ZEST_DAC_DCO_N")
        self.dsp_clk_out      = Signal()
        self.clk_div_out      = Signal(2)
        self.adc_out_clk      = Signal(8)
        self.adc_out_data     = Signal(128)
        self.dac_in_data_i    = Signal(14)
        self.dac_in_data_q    = Signal(14)
        self.clk_200          = Signal()
        self.clk              = Signal()
        self.rst              = Signal()
        self.mem_packed_fwd   = Signal(69)
        self.mem_packed_ret   = Signal(33)

        # # #
        self.dw = dw = 128
        self.source = source = stream.Endpoint([("data", dw)])
        self.comb += [source.data.eq(self.adc_out_data),
                      # TODO: Maybe have reset have an affect here?
                      source.valid.eq(1)]

        self.specials += Instance("zest",
                                  o_ADC_PDWN=self.ADC_PDWN,
                                  o_ADC_CSB_0=self.ADC_CSB_0,
                                  o_ADC_SYNC=self.ADC_SYNC,
                                  o_SCLK=self.SCLK,
                                  o_SDI=self.SDI,
                                  o_ADC_CSB_1=self.ADC_CSB_1,
                                  o_LMK_LEUWIRE=self.LMK_LEUWIRE,
                                  o_PWR_SYNC=self.PWR_SYNC,
                                  o_PWR_EN=self.PWR_EN,
                                  o_AD7794_FCLK=self.AD7794_FCLK,
                                  o_DAC_CSB=self.DAC_CSB,
                                  o_AMC7823_SPI_SS=self.AMC7823_SPI_SS,
                                  o_AD7794_CSB=self.AD7794_CSB,
                                  o_DAC_RESET=self.DAC_RESET,
                                  o_POLL_SCLK=self.POLL_SCLK,
                                  o_POLL_MOSI=self.POLL_MOSI,
                                  o_ADC_SDIO_DIR=self.ADC_SDIO_DIR,
                                  io_ADC_SDIO=self.ADC_SDIO,
                                  i_AMC7823_SPI_MISO=self.AMC7823_SPI_MISO,
                                  i_LMK_DATAUWIRE=self.LMK_DATAUWIRE,
                                  i_AD7794_DOUT=self.AD7794_DOUT,
                                  i_DAC_SDO=self.DAC_SDO,
                                  i_CLK_TO_FPGA_P=self.CLK_TO_FPGA_P,
                                  i_CLK_TO_FPGA_N=self.CLK_TO_FPGA_N,
                                  i_ADC_D0_P=self.ADC_D0_P,
                                  i_ADC_D0_N=self.ADC_D0_N,
                                  i_ADC_D1_P=self.ADC_D1_P,
                                  i_ADC_D1_N=self.ADC_D1_N,
                                  i_ADC_DCO_P=self.ADC_DCO_P,
                                  i_ADC_DCO_N=self.ADC_DCO_N,
                                  i_ADC_FCO_P=self.ADC_FCO_P,
                                  i_ADC_FCO_N=self.ADC_FCO_N,
                                  o_DAC_D_P=self.DAC_D_P,
                                  o_DAC_D_N=self.DAC_D_N,
                                  o_DAC_DCI_P=self.DAC_DCI_P,
                                  o_DAC_DCI_N=self.DAC_DCI_N,
                                  i_DAC_DCO_P=self.DAC_DCO_P,
                                  i_DAC_DCO_N=self.DAC_DCO_N,
                                  o_dsp_clk_out=self.dsp_clk_out,
                                  o_clk_div_out=self.clk_div_out,
                                  o_adc_out_clk=self.adc_out_clk,
                                  o_adc_out_data=self.adc_out_data,
                                  i_dac_in_data_i=self.dac_in_data_i,
                                  i_dac_in_data_q=self.dac_in_data_q,
                                  i_clk_200=self.clk_200,
                                  i_clk=self.clk,
                                  i_rst=self.rst,
                                  i_mem_packed_fwd=self.mem_packed_fwd,
                                  o_mem_packed_ret=self.mem_packed_ret,
        )

        self.add_sources(platform)
