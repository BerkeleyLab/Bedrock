#!/usr/bin/env python3
'''
---------------------
 LiteX SoC on Marble
---------------------
with support for SO-DIMM DDR3, ethernet and UART.
To synthesize, add --build, to configure the FPGA over jtag, add --load.

-----------------
 Example configs
-----------------
with ethernet and DDR3, default IP: 192.168.1.50/24
  ./marble.py --with-ethernet --with-bist --spd-dump VR7PU286458FBAMJT.txt

lightweight config
  ./marble.py --integrated-main-ram-size 16384 --cpu-type serv

etherbone: access wishbone over ethernet
  ./marble.py --with-etherbone --csr-csv build/csr.csv

make sure reset is not asserted (RTS signal), set PC IP to 192.168.1.100/24,
then test and benchmark the etherbone link:
  cd build
  litex/liteeth/bench/test_etherbone.py --udp --ident --access --sram --speed
'''

import os
import argparse

from migen import Signal, Module, ClockDomain

import sys
sys.path.append("..")
from trigger_capture.platforms import marble

# from litex.soc.cores.clock import *
from functools import reduce
from operator import or_
from litex.soc.cores.clock.xilinx_s7 import S7IDELAYCTRL, S7MMCM
from litex.soc.integration.soc_core import soc_core_args, soc_core_argdict, SoCCore
from litex.soc.integration.builder import builder_args, Builder, builder_argdict
from litex.soc.cores.led import LedChaser
from litex.soc.cores.bitbang import I2CMaster

# MT8JTF12864?
from litedram.modules import parse_spd_hexdump, SDRAMModule, MT41J256M8
from litedram.phy import s7ddrphy

from liteeth.phy.s7rgmii import LiteEthPHYRGMII


# CRG ----------------------------------------------------------------------------------------------
class _CRG(Module):
    def __init__(self, platform, sys_clk_freq, resets=[]):
        self.rst = Signal()
        self.clock_domains.cd_sys    = ClockDomain()
        self.clock_domains.cd_sys4x  = ClockDomain(reset_less=True)
        self.clock_domains.cd_sys4x_dqs = ClockDomain(reset_less=True)
        self.clock_domains.cd_idelay = ClockDomain()

        # # #

        self.submodules.pll = pll = S7MMCM(speedgrade=-2)

        resets.append(self.rst)
        self.comb += pll.reset.eq(reduce(or_, resets))
        pll.register_clkin(platform.request("clk125"), 125e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq)
        pll.create_clkout(self.cd_sys4x, 4*sys_clk_freq)
        # pll.create_clkout(self.cd_sys4x_dqs, 4*sys_clk_freq, phase=90)
        pll.create_clkout(self.cd_idelay, 200e6)
        # Ignore sys_clk to pll.clkin path created by SoC's rst.
        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin)
        platform.add_period_constraint(self.cd_sys.clk, 1e9/sys_clk_freq)
        platform.add_period_constraint(self.cd_idelay.clk, 1e9/200e6)
        platform.add_platform_command("set_property LOC IDELAYCTRL_X1Y1 [get_cells IDELAYCTRL]")
        platform.add_platform_command("set_property LOC IDELAYCTRL_X1Y2 [get_cells IDELAYCTRL_1]")
        platform.add_platform_command("set_property LOC IDELAYCTRL_X0Y3 [get_cells IDELAYCTRL_2]")
        platform.add_platform_command("set_property LOC IDELAYCTRL_X0Y4 [get_cells IDELAYCTRL_3]")
        platform.add_platform_command("set_property LOC IDELAYCTRL_X1Y0 [get_cells IDELAYCTRL_4]")
        # platform.add_platform_command("set_property IODELAY_GROUP IO_DLY1 [get_cells *IDELAYCTRL*]")
        # platform.add_platform_command("set_property IODELAY_GROUP IO_DLY1 [get_cells *ODELAYE2*]")
        # platform.add_platform_command("set_property IODELAY_GROUP IO_DLY1 [get_cells -hier *IDELAYE2*]")
        # platform.add_platform_command("set_property IODELAY_GROUP IO_DLY1 [get_cells -hier *idelaye2*]")
        platform.add_false_path_constraint(self.cd_idelay.clk, self.cd_sys.clk)
        for _ in range(5):
            self.submodules += S7IDELAYCTRL(self.cd_idelay)


# BaseSoC ------------------------------------------------------------------------------------------
class BaseSoC(SoCCore):
    def __init__(
        self,
        sys_clk_freq=int(125e6),
        with_ethernet=False,
        with_etherbone=False,
        with_rts_reset=False,
        with_led_chaser=True,
        spd_dump=None,
        **kwargs
    ):
        platform = marble.Platform()

        # SoCCore ----------------------------------------------------------------------------------
        SoCCore.__init__(
            self, platform, sys_clk_freq,
            ident          = "LiteX SoC on Marble",
            **kwargs)

        # CRG, resettable over USB serial RTS signal -----------------------------------------------
        resets = []
        if with_rts_reset:
            ser_pads = platform.lookup_request('serial')
            resets.append(ser_pads.rts)
        self.submodules.crg = _CRG(platform, sys_clk_freq, resets)

        # DDR3 SDRAM -------------------------------------------------------------------------------
        if not self.integrated_main_ram_size:
            self.submodules.ddrphy = s7ddrphy.K7DDRPHY(
                platform.request("ddram"),
                memtype      = "DDR3",
                nphases      = 4,
                sys_clk_freq = sys_clk_freq
            )

            if spd_dump is not None:
                ram_spd = parse_spd_hexdump(spd_dump)
                ram_module = SDRAMModule.from_spd_data(ram_spd, sys_clk_freq)
                print('DDR3: loaded config from', spd_dump)
            else:
                # ram_module = MT8JTF12864(sys_clk_freq, "1:4")  # KC705 chip, 1 GB
                ram_module = MT41J256M8(sys_clk_freq, "1:4")
                print('DDR3: No spd data specified, falling back to MT8JTF12864')

            self.add_sdram(
                "sdram",
                phy = self.ddrphy,
                module = ram_module,
                # size=0x40000000,  # Limit its size to 1 GB
                # l2_cache_size = kwargs.get("l2_size", 8192),
                # with_bist = kwargs.get("with_bist", False)
                origin                  = self.mem_map["main_ram"],
                size                    = kwargs.get("max_sdram_size", 0x40000000),
                l2_cache_size           = kwargs.get("l2_size", 8192),
                l2_cache_min_data_width = kwargs.get("min_l2_data_width", 128),
                l2_cache_reverse        = True
            )

        # Ethernet ---------------------------------------------------------------------------------
        if with_ethernet or with_etherbone:
            self.submodules.ethphy = LiteEthPHYRGMII(
                clock_pads = self.platform.request("eth_clocks"),
                pads = self.platform.request("eth"),
                tx_delay=0
            )

        # if with_ethernet:
        #     self.add_ethernet(
        #         phy=self.ethphy,
        #         dynamic_ip=False,
        #         software_debug=False
        #     )

        if with_etherbone:
            self.add_etherbone(phy=self.ethphy, buffer_depth=255)

        # System I2C (behind multiplexer) ----------------------------------------------------------
        i2c_pads = platform.request('i2c_fpga')
        self.submodules.i2c = I2CMaster(i2c_pads)
        self.add_csr("i2c")

        # Leds -------------------------------------------------------------------------------------
        if with_led_chaser:
            self.submodules.leds = LedChaser(
                pads         = platform.request_all("user_led"),
                sys_clk_freq = sys_clk_freq)


# Build --------------------------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("--build",         action="store_true", help="Build bitstream")
    parser.add_argument("--load",          action="store_true", help="Load bitstream")
    parser.add_argument("--sys-clk-freq",  default=125e6,       help="System clock frequency (default: 125MHz)")
    parser.add_argument("--with-ethernet", action="store_true", help="Enable Ethernet support")
    parser.add_argument("--with-etherbone", action="store_true", help="Enable Etherbone support")
    parser.add_argument("--with-rts-reset", action="store_true", help="Connect UART RTS line to sys_clk reset")
    parser.add_argument("--with-bist",     action="store_true", help="Add DDR3 BIST Generator/Checker")
    parser.add_argument("--spd-dump", type=str,
                        help="DDR3 configuration file, dumped using the `spdread` command in LiteX BIOS")
    builder_args(parser)
    soc_core_args(parser)
    args = parser.parse_args()

    soc = BaseSoC(
        sys_clk_freq  = int(float(args.sys_clk_freq)),
        with_ethernet = args.with_ethernet,
        with_etherbone = args.with_etherbone,
        with_bist = args.with_bist,
        spd_dump = args.spd_dump,
        **soc_core_argdict(args)
    )
    builder = Builder(soc, **builder_argdict(args))
    builder.build(run=args.build)

    if args.load:
        prog = soc.platform.create_programmer()
        prog.load_bitstream(os.path.join(builder.gateware_dir, soc.build_name + ".bit"))


if __name__ == "__main__":
    main()
