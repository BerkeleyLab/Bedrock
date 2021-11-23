from migen import *

from litex.build.generic_platform import Subsignal, Pins, IOStandard, Misc
from litex.soc.interconnect.csr import AutoCSR
from litex.soc.interconnect import stream

zest_pads = [
    ("ZEST_DAC_D", 0,
     Subsignal("p", Pins("FMC2_LPC:LA14_P FMC2_LPC:LA13_P FMC2_LPC:LA12_P FMC2_LPC:LA09_P FMC2_LPC:LA08_P FMC2_LPC:LA15_P FMC2_LPC:LA11_P FMC2_LPC:LA07_P FMC2_LPC:LA04_P FMC2_LPC:LA05_P FMC2_LPC:LA06_P FMC2_LPC:LA03_P FMC2_LPC:LA00_P FMC2_LPC:LA02_P ")),
     Subsignal("n", Pins("FMC2_LPC:LA14_N FMC2_LPC:LA13_N FMC2_LPC:LA12_N FMC2_LPC:LA09_N FMC2_LPC:LA08_N FMC2_LPC:LA15_N FMC2_LPC:LA11_N FMC2_LPC:LA07_N FMC2_LPC:LA04_N FMC2_LPC:LA05_N FMC2_LPC:LA06_N FMC2_LPC:LA03_N FMC2_LPC:LA00_N FMC2_LPC:LA02_N ")),
     IOStandard("LVDS_25")),
    # WTF: This p/n inversion comes from the zest schematic
    ("ZEST_ADC_D", 0,
     Subsignal("n", Pins("FMC1_LPC:LA09_P FMC1_LPC:LA05_P FMC1_LPC:LA02_P FMC1_LPC:LA03_P FMC1_LPC:LA22_P FMC1_LPC:LA18_P_CC FMC1_LPC:LA15_P FMC1_LPC:LA14_P")),
     Subsignal("p", Pins("FMC1_LPC:LA09_N FMC1_LPC:LA05_N FMC1_LPC:LA02_N FMC1_LPC:LA03_N FMC1_LPC:LA22_N FMC1_LPC:LA18_N_CC FMC1_LPC:LA15_N FMC1_LPC:LA14_N")),
     IOStandard("LVDS_25")),
    ("ZEST_ADC_D", 1,
     Subsignal("n", Pins("FMC1_LPC:LA08_P FMC1_LPC:LA07_P FMC1_LPC:LA06_P FMC1_LPC:LA01_P FMC1_LPC:LA20_P FMC1_LPC:LA21_P FMC1_LPC:LA16_P FMC1_LPC:LA11_P")),
     Subsignal("p", Pins("FMC1_LPC:LA08_N FMC1_LPC:LA07_N FMC1_LPC:LA06_N FMC1_LPC:LA01_N FMC1_LPC:LA20_N FMC1_LPC:LA21_N FMC1_LPC:LA16_N FMC1_LPC:LA11_N")),
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
    ("ZEST_ADC_PDWN"        , 0, Pins("FMC2_LPC:LA16_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_CSB_0"       , 0, Pins("FMC2_LPC:LA31_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SYNC"        , 0, Pins("FMC2_LPC:LA33_P"), IOStandard("LVCMOS25")),
    ("ZEST_SCLK"            , 0, Pins("FMC2_LPC:LA29_N"), IOStandard("LVCMOS25")),
    ("ZEST_SDI"             , 0, Pins("FMC2_LPC:LA29_P"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_CSB_1"       , 0, Pins("FMC2_LPC:LA31_N"), IOStandard("LVCMOS25")),
    ("ZEST_LMK_LEUWIRE"     , 0, Pins("FMC2_LPC:LA21_P"), IOStandard("LVCMOS25")),
    ("ZEST_PWR_SYNC"        , 0, Pins("FMC2_LPC:LA27_P"), IOStandard("LVCMOS25")),
    ("ZEST_PWR_EN"          , 0, Pins("FMC2_LPC:LA27_N"), IOStandard("LVCMOS25")),
    ("ZEST_AD7794_FCLK"     , 0, Pins("FMC2_LPC:LA22_P"), IOStandard("LVCMOS25")),
    ("ZEST_DAC_CSB"         , 0, Pins("FMC2_LPC:LA19_N"), IOStandard("LVCMOS25")),
    ("ZEST_AMC7823_SPI_SS"  , 0, Pins("FMC2_LPC:LA24_N"), IOStandard("LVCMOS25")),
    ("ZEST_AD7794_CSB"      , 0, Pins("FMC2_LPC:LA26_P"), IOStandard("LVCMOS25")),
    ("ZEST_DAC_RESET"       , 0, Pins("FMC2_LPC:LA21_N"), IOStandard("LVCMOS25")),
    ("ZEST_POLL_SCLK"       , 0, Pins("FMC2_LPC:LA16_N"), IOStandard("LVCMOS25")),
    ("ZEST_POLL_MOSI"       , 0, Pins("FMC2_LPC:LA33_N"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SDIO_DIR"    , 0, Pins("FMC2_LPC:LA28_N"), IOStandard("LVCMOS25")),
    ("ZEST_ADC_SDIO"        , 0, Pins("FMC2_LPC:LA28_P"), IOStandard("LVCMOS25")),
    ("ZEST_AMC7823_SPI_MISO", 0, Pins("FMC2_LPC:LA24_P"), IOStandard("LVCMOS25")),
    ("ZEST_LMK_DATAUWIRE"   , 0, Pins("FMC2_LPC:LA22_N"), IOStandard("LVCMOS25")),
    ("ZEST_AD7794_DOUT"     , 0, Pins("FMC2_LPC:LA26_N"), IOStandard("LVCMOS25")),
    ("ZEST_DAC_SDO"         , 0, Pins("FMC2_LPC:LA19_P"), IOStandard("LVCMOS25")),
    # Zest schematic inversion
    ("ZEST_ADC_DCO", 0,
     Subsignal("n", Pins("FMC1_LPC:LA00_P"), IOStandard("LVDS_25")),
     Subsignal("p", Pins("FMC1_LPC:LA00_N"), IOStandard("LVDS_25"))),
    ("ZEST_ADC_DCO", 1,
     Subsignal("n", Pins("FMC1_LPC:LA17_P_CC"), IOStandard("LVDS_25")),
     Subsignal("p", Pins("FMC1_LPC:LA17_N_CC"), IOStandard("LVDS_25"))),
    ("ZEST_ADC_FCO" , 0,
     Subsignal("n", Pins("FMC1_LPC:LA04_P FMC1_LPC:LA19_P"), IOStandard("LVDS_25")),
     Subsignal("p", Pins("FMC1_LPC:LA04_N FMC1_LPC:LA19_N"), IOStandard("LVDS_25")),
    ),
    ("ZEST_DAC_DCO" , 0,
     Subsignal("p", Pins("FMC2_LPC:LA17_P"), IOStandard("LVDS_25")),
     Subsignal("n", Pins("FMC2_LPC:LA17_N"), IOStandard("LVDS_25")),
    ),
    ("ZEST_DAC_DCI" , 0,
     Subsignal("p", Pins("FMC2_LPC:LA10_P"), IOStandard("LVDS_25")),
     Subsignal("n", Pins("FMC2_LPC:LA10_N"), IOStandard("LVDS_25")),
    )
]

class Zest(Module, AutoCSR):

    def add_sources(self, platform):
        sources = [
            "board_support/zest_soc/zest.v",
            "board_support/zest_soc/zest_clk_map.v",
            "board_support/zest_soc/zest_spi_dio_pack.v",
            "dsp/freq_count.v",
            "dsp/phase_diff.v",
            "dsp/flag_xdomain.v",
            "dsp/data_xdomain.v",
            "dsp/phaset.v",
            "dsp/dpram.v",
            "soc/picorv32/gateware/sfr_pack.v",
            "soc/picorv32/gateware/munpack.v",
            "soc/picorv32/gateware/mpack.v",
            "soc/picorv32/gateware/spi_engine.v",
            "soc/picorv32/gateware/idelays_pack.v",
            "soc/picorv32/gateware/wfm_pack.v",
            "board_support/fmc11x/dco_buf.v",
            "board_support/fmc11x/idelay_wrap.v",
            "board_support/fmc11x/iserdes_pack.v",
        ]
        # set_property PROCESSING_ORDER LATE [get_files /home/w/work/lbl/bedrock/projects/trigger_capture/build/marble/gateware/marble.srcs/constrs_1/new/vivado_sucks_balls.xdc]
        platform.add_sources("../../", *sources)

    def __init__(self, platform, bus):
        clk_to_fpga_dummy = platform.request("ZEST_CLK_TO_FPGA", 0)
        clk_to_fpga = platform.request("ZEST_CLK_TO_FPGA", 1)
        adc_d0 = platform.request("ZEST_ADC_D", 0)
        adc_d1 = platform.request("ZEST_ADC_D", 1)
        adc_dco_0 = platform.request("ZEST_ADC_DCO", 0)
        adc_dco_1 = platform.request("ZEST_ADC_DCO", 1)
        adc_fco = platform.request("ZEST_ADC_FCO", 0)
        dac_dco = platform.request("ZEST_DAC_DCO", 0)
        dac_d   = platform.request("ZEST_DAC_D", 0)
        dac_dci = platform.request("ZEST_DAC_DCI", 0)
        self.ADC_PDWN         = platform.request("ZEST_ADC_PDWN")
        self.ADC_CSB_0        = platform.request("ZEST_ADC_CSB_0")
        self.ADC_SYNC         = platform.request("ZEST_ADC_SYNC")
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
        self.CLK_TO_FPGA_P    = clk_to_fpga.p
        self.CLK_TO_FPGA_N    = clk_to_fpga.n
        self.ADC_D0_P         = adc_d0.p
        self.ADC_D0_N         = adc_d0.n
        self.ADC_D1_P         = adc_d1.p
        self.ADC_D1_N         = adc_d1.n
        self.ADC_DCO_P        = Cat(adc_dco_0.p, adc_dco_1.p)
        self.ADC_DCO_N        = Cat(adc_dco_0.n, adc_dco_1.n)
        self.ADC_FCO_P        = adc_fco.p
        self.ADC_FCO_N        = adc_fco.n
        self.DAC_D_P          = dac_d.p
        self.DAC_D_N          = dac_d.n
        self.DAC_DCI_P        = dac_dci.p
        self.DAC_DCI_N        = dac_dci.n
        self.DAC_DCO_P        = dac_dco.p
        self.DAC_DCO_N        = dac_dco.n
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

        platform.add_period_constraint(clk_to_fpga, 8.7)
        # platform.add_period_constraint(clk_to_fpga_dummy, 8.7)
        platform.add_period_constraint(platform.lookup_request("ZEST_CLK_TO_FPGA", 1).p, 8.7)
        platform.add_period_constraint(platform.lookup_request("ZEST_ADC_DCO", 0).p, 1e9/500e6)
        platform.add_period_constraint(platform.lookup_request("ZEST_ADC_DCO", 1).p, 1e9/500e6)
        platform.add_period_constraint(platform.lookup_request("ZEST_DAC_DCO",    loose=True).p, 8.7)

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

            # idbus.adr.eq(mem_addr[2:]),
            # idbus.dat_w.eq(mem_wdata),
            # idbus.we.eq(mem_wstrb != 0),
            # idbus.sel.eq(mem_wstrb),
            # idbus.cyc.eq(mem_valid),
            # idbus.stb.eq(mem_valid),
            # idbus.cti.eq(0),
            # idbus.bte.eq(0),
            # mem_ready.eq(idbus.ack),
            # mem_rdata.eq(idbus.dat_r),

        self.specials += Instance("mpack",
                                  i_mem_packed_ret=self.mem_packed_ret,
                                  o_mem_packed_fwd=self.mem_packed_fwd,
                                  i_mem_wdata=bus.dat_w,
                                  i_mem_wstrb=bus.sel,
                                  i_mem_addr=bus.adr[2:],
                                  i_mem_valid=bus.stb,
                                  o_mem_ready=bus.ack,
                                  o_mem_rdata=bus.dat_r,
        )

        self.add_sources(platform)
