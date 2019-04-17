import argparse
import math as M
import os

from migen import *

from litex.soc.interconnect import wishbone

from litex.boards.targets.ac701 import EthernetSoC

from litex.build.sim.config import SimConfig

from litex.soc.integration.soc_core import *
from litex.soc.integration.soc_sdram import *
from litex.soc.integration.builder import *

from liteeth.frontend.etherbone import LiteEthEtherbone
from litex.utils.litex_sim import SimSoC
from litex.soc.cores.xadc import XADC

DEADBEEF_ADDR = (0xb0000000 + 0x80000) >> 2

class Cryomodule(Module):
    name = "cryomodule"

    def __init__(self,
                 platform,
                 bus,
                 clk1x,
                 clk2x,
                 lb_clk,
                 circle_buf_size=8192,
                 mode_count=3,
                 n_mech_modes=7,
                 df_scale=9,
                 cavity_count=2,
                 sr_length=4 * 8):

        cryomodule_params = {
            "p_circle_aw": int(M.log(circle_buf_size, 2)),
            "p_mode_count": mode_count,
            "p_mode_shift": 9,
            "p_n_mech_modes": n_mech_modes,
            "p_cavity_count": cavity_count,
            "p_cavity_ln": M.ceil(M.log(cavity_count, 2)),
            "p_df_scale": df_scale,
            "p_n_cycles": n_mech_modes * 2,
            "p_interp_span": M.ceil(M.log(n_mech_modes * 2, 2)),
            "p_sr_length": sr_length
        }
        self.dat_r = Signal(32)
        cry_stb  = Signal()
        self.specials += Instance(
            "cryomodule",
            **cryomodule_params,
            i_clk1x=clk1x,
            i_clk2x=clk2x,
            i_lb_clk=lb_clk,
            i_lb_data=bus.dat_w,
            i_lb_addr=bus.adr[:17],
            i_lb_write=bus.we & cry_stb,
            i_lb_read=bus.stb & (bus.we == 0) & cry_stb,
            o_lb_out=self.dat_r)
        self.comb += [
            cry_stb.eq(bus.adr[26:] == 0xb)
        ]
        # add verilog sources
        self.add_sources(platform)

    @staticmethod
    def add_sources(platform):
        vdir = os.path.join(os.path.abspath(os.path.dirname(__file__)))
        platform.add_source(os.path.join(vdir, "cryomodule_EXPAND.v"))


class CryomoduleEthSoC(EthernetSoC):
    # csr_peripherals = [
    #     "cryo",
    # ]
    # csr_map_update(SoCSDRAM.csr_map, csr_peripherals)
    mem_map = {
        "cryo": 0x30000000,  # (shadow @0xb0000000)
    }
    mem_map.update(EthernetSoC.mem_map)
    def __init__(self, sim_only=True, **kwargs):
        EthernetSoC.__init__(self, **kwargs)
        self.submodules.etherbone = LiteEthEtherbone(
            self.core.udp, 1234, mode="master")
        self.submodules.xadc = XADC()

        bus = self.etherbone.wishbone.bus
        self.add_wb_master(bus)
        stb_d1, stb_d2, stb_d3 = Signal(), Signal(), Signal()
        data_out = Signal(32)
        self.sync += [
            stb_d1.eq(bus.stb),
            stb_d2.eq(stb_d1),
            stb_d3.eq(stb_d2)
        ]
        crg = self.crg
        self.submodules.cryomodule = cm = Cryomodule(self.platform, bus, crg.cd_clk1x.clk,
                        crg.cd_clk200.clk, crg.cd_sys.clk)
        self.sync += [
            If(bus.stb & (bus.we == 0),
               If((bus.adr > DEADBEEF_ADDR) & (bus.adr < DEADBEEF_ADDR + 0x1000),
                  data_out.eq(0xDEADBEE0 + bus.adr[0:2])
               ).Else(
                   data_out.eq(cm.dat_r)))
        ]
        self.comb += [
            bus.ack.eq(stb_d3),
            bus.dat_r.eq(data_out)
        ]


class CryomoduleSimSoC(SimSoC):
    mem_map = {
        "cryo": 0x30000000,  # (shadow @0xb0000000)
    }
    mem_map.update(SimSoC.mem_map)
    def __init__(self, **kwargs):
        SimSoC.__init__(self, with_etherbone=True,
                        etherbone_ip_address="192.168.1.51",
                        **kwargs)
        clk = self.crg.cd_sys.clk
        bus = self.etherbone.wishbone.bus
        # self.add_wb_master(self.etherbone.wishbone.bus)

        stb_d1, stb_d2, stb_d3 = Signal(), Signal(), Signal()
        data_out = Signal(32)
        self.sync += [
            stb_d1.eq(bus.stb),
            stb_d2.eq(stb_d1),
            stb_d3.eq(stb_d2)
        ]
        self.submodules.cryomodule = cm = Cryomodule(self.platform, bus, clk, clk, clk)
        self.sync += [
            If(bus.stb & (bus.we == 0),
               If((bus.adr > DEADBEEF_ADDR) & (bus.adr < DEADBEEF_ADDR + 0x1000),
                  data_out.eq(0xDEADBEE0 + bus.adr[0:2])
               ).Else(
                   data_out.eq(cm.dat_r)))
        ]
        self.comb += [
            bus.ack.eq(stb_d3),
            bus.dat_r.eq(data_out)
        ]


def main():
    parser = argparse.ArgumentParser(
        description="Cryomodule upon Litex on AC701")
    builder_args(parser)
    soc_sdram_args(parser)
    parser.add_argument(
        "--sim-only", action="store_true", help="run in Simulation")
    parser.add_argument("--threads", default=4,
                        help="set number of threads (default=4)")
    parser.add_argument("--trace", action="store_true",
                        help="enable VCD tracing")
    args = parser.parse_args()
    soc_kwargs = soc_sdram_argdict(args)
    builder_kwargs = builder_argdict(args)

    if args.sim_only:
        sim_config = SimConfig(default_clk="sys_clk")
        sim_config.add_module("serial2console", "serial")
        soc_kwargs["integrated_main_ram_size"] = 0x10000

        sim_config.add_module(
            'ethernet',
            "eth",
            args={"interface": "tap1",
                  "ip": "192.168.1.101"})

        soc = CryomoduleSimSoC(**soc_kwargs)
        builder_kwargs["csr_csv"] = "csr.csv"
        builder = Builder(soc, **builder_kwargs)
        vns = builder.build(
            run=False,
            threads=args.threads,
            sim_config=sim_config,
            trace=args.trace)
        builder.build(
            build=False,
            threads=args.threads,
            sim_config=sim_config,
            trace=args.trace)

    else:
        soc = CryomoduleEthSoC(**soc_sdram_argdict(args))
        builder = Builder(soc, **builder_argdict(args))
        builder.build()
    prog = soc.platform.create_programmer()
    prog.load_bitstream("soc_cryomoduleethsoc_ac701/gateware/top.bit")


if __name__ == "__main__":
    main()
