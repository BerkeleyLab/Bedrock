import argparse

from migen import *

from litex.tools.litex_sim import SimSoC, SimConfig
from litex_boards.targets.kc705 import BaseSoC
from litex.soc.integration.builder import *
from litex.soc.integration.soc_core import soc_core_args, soc_core_argdict
from liteeth.core import LiteEthUDPIPCore
from liteeth.common import convert_ip

from data_pipe import DataPipe
from litex_boards.platforms import kc705

class SDRAMLoopbackSoC(BaseSoC):
    '''
    SDRAM loopback tester over ethernet
    '''
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        ip = "192.168.19.70"
        print(f"setting to {ip}")
        self.submodules.udp_core = LiteEthUDPIPCore(self.ethphy, 0x12345678abcd,
                                                    convert_ip(ip),
                                                    clk_freq=self.sys_clk_freq)
        self.add_csr("udp_core")
        self.udp_port = udp_port = self.udp_core.udp.crossbar.get_port(4321, 8)

        ddr_wr_port, ddr_rd_port = self.sdram.crossbar.get_port("write"), self.sdram.crossbar.get_port("read")
        self.submodules.data_pipe = DataPipe(ddr_wr_port, ddr_rd_port, udp_port)
        self.add_csr("data_pipe")

def main():
    parser = argparse.ArgumentParser(description="SDRAM Loopback SoC on Marble*")
    builder_args(parser)
    soc_core_args(parser)
    parser.add_argument("--with-ethernet", action="store_true",
                        help="enable Ethernet support")
    parser.add_argument("--ethernet-phy", default="rgmii",
                        help="select Ethernet PHY (rgmii or 1000basex)")
    parser.add_argument("-p", "--program-only", action="store_true",
                        help="Don't build, just program the existing bitfile")
    parser.add_argument("--build", action="store_true",
                        help="Build FPGA bitstream")
    parser.add_argument("--load", action="store_true",
                        help="program FPGA")
    args = parser.parse_args()


    if args.build:
        soc = SDRAMLoopbackSoC(
            with_ethernet = args.with_ethernet,
            **soc_core_argdict(args))
        builder = Builder(soc, **builder_argdict(args))
        vns = builder.build(run=not args.program_only)

    if args.load:
        prog = kc705.Platform().create_programmer()
        prog.load_bitstream(os.path.join("build", "kc705", "gateware", "kc705.bit"))


if __name__ == "__main__":
    main()
