import argparse

from migen import *

from litex.tools.litex_sim import SimSoC, SimConfig

from litex.soc.integration.builder import *
from litex.soc.integration.soc_core import soc_core_args, soc_core_argdict
from litex.soc.cores.bitbang import I2CMaster
from liteeth.core import LiteEthUDPIPCore
from liteeth.common import convert_ip

from data_pipe import DataPipeWithoutBypass as DataPipe
from litex_boards.platforms import marble
from zest import Zest

from targets.marble import BaseSoC

class SDRAMLoopbackSoC(BaseSoC):
    '''
    SDRAM loopback tester over ethernet
    '''
    def __init__(self, ip="192.168.19.70", **kwargs):
        super().__init__(with_ethernet=True, **kwargs)
        self.submodules.udp_core = LiteEthUDPIPCore(self.ethphy, 0x12345678abcd,
                                                    convert_ip(ip),
                                                    clk_freq=self.sys_clk_freq)
        self.add_csr("udp_core")
        self.udp_port = udp_port = self.udp_core.udp.crossbar.get_port(4321, 8)

        ddr_wr_port, ddr_rd_port = self.sdram.crossbar.get_port("write"), self.sdram.crossbar.get_port("read")
        self.submodules.data_pipe = DataPipe(ddr_wr_port, ddr_rd_port, udp_port)
        self.add_csr("data_pipe")


class SDRAMDevSoC(SDRAMLoopbackSoC):
    def __init__(self, **kwargs):
        from litescope import LiteScopeAnalyzer
        super().__init__(**kwargs)
        analyzer_signals = [
            # self.data_pipe.dram_fifo.ctrl.writable,
            # self.data_pipe.dram_fifo.ctrl.readable,
            self.data_pipe.dram_fifo.dram_fifo.ctrl.level,
            # #self.data_pipe.buffer_fifo.source,

            # self.data_pipe.udp_fragmenter.sink,

            # self.data_pipe.dram_fifo.source,
            # self.data_pipe.dram_fifo.reader.reader.sink,
            # self.data_pipe.udp_fragmenter.source,
            # self.udp_port.sink,

            # self.data_pipe.adcs.source,
            # # self.data_pipe.dram_fifo.writer.sink,
            self.data_pipe.read_from_dram_fifo,
            # self.data_pipe.dram_fifo.dram_cnt,
            # self.data_pipe.dram_fifo.dram_inc_mod,
            # self.data_pipe.dram_fifo.dram_dec_mod,
            self.data_pipe.dram_fifo.pre_fifo.sink,
            self.data_pipe.dram_fifo.pre_converter.sink,
            # self.data_pipe.dram_fifo.pre_converter.converter.strobe_all,
            self.data_pipe.dram_fifo.pre_converter.source,
            # self.data_pipe.buffer_fifo.source,
            self.data_pipe.dram_fifo.sink,
            # self.data_pipe.dram_fifo.dram_bypass,
            # self.data_pipe.stride_converter.sink,
            # self.data_pipe.stride_converter.source,
            self.data_pipe.fifo_error.status,

            # self.data_pipe.dram_fifo.source,
            # self.ethphy.sink,
            # self.ethphy.source,

            # self.data_pipe.receive_count,
            # self.data_pipe.dram_fifo.ctrl.write,
            # self.data_pipe.dram_fifo.ctrl.read,
            # self.data_pipe.dram_fifo.ctrl.read_address,
            # self.data_pipe.dram_fifo.ctrl.write_address,
            # self.data_pipe.dram_fifo.reader.reader.port.rdata,
            # self.data_pipe.dram_fifo.reader.reader.rsv_level,
            # # self.data_pipe.dram_fifo.writer.writer.port.cmd,
            # # self.data_pipe.dram_fifo.writer.writer.port.wdata,
            # # self.data_pipe.dram_fifo.writer.writer.port.flush,
            # # self.data_pipe.dram_fifo.writer.writer.port.lock,
            # # self.data_pipe.dram_fifo.writer.writer.fifo.sink.ready,
            # #self.data_pipe.dram_fifo.writer.writer.sink,
            # self.data_pipe.load_fifo,
            # self.data_pipe.fifo_read.storage,
            self.data_pipe.fifo_counter,
            # self.data_pipe.buffer_fifo.level,
            # self.data_pipe.first_sample,
            # self.data_pipe.last_sample,
        ]
        self.submodules.analyzer = LiteScopeAnalyzer(analyzer_signals, 1024,
                                                     csr_csv="analyzer.csv")
        self.add_csr("analyzer")

# Build --------------------------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="SDRAM Loopback SoC on Marble*")
    builder_args(parser)
    soc_core_args(parser)
    parser.add_argument("--ip", default="192.168.19.70",
                        help="Assign an ip address")
    parser.add_argument("--ethernet-phy", default="rgmii",
                        help="select Ethernet PHY (rgmii or 1000basex)")
    parser.add_argument("-p", "--program-only", action="store_true",
                        help="Don't build, just program the existing bitfile")
    parser.add_argument("--build", action="store_true",
                        help="Build FPGA bitstream")
    parser.add_argument("--load", action="store_true",
                        help="program FPGA")
    parser.add_argument("--threads", default=4,
                        help="set number of threads (default=4)")
    parser.add_argument("--trace", action="store_true",
                        help="enable VCD tracing")
    parser.add_argument("-s", "--sim", action="store_true",
                        help="Simulate")
    args = parser.parse_args()

    if args.sim:
        soc_kwargs = soc_core_argdict(args)
        sim_config = SimConfig(default_clk="sys_clk")
        soc_kwargs["integrated_main_ram_size"] = 0x10000
        soc_kwargs = soc_core_argdict(args)
        soc_kwargs["uart_name"] = "sim"
        #sim_config.add_module("serial2console", "serial")
        sim_config.add_module(
            'ethernet',
            "eth",
            args={"interface": "xxx1",
                  "ip": "192.168.88.101",
                  "vcd_name": "foo.vcd"})
        soc = SDRAMSimSoC(phy="rgmii",
                          with_ethernet=True,
                          with_etherbone=True,
                          with_sdram=True,
                          etherbone_ip_address="192.168.88.50",
                          etherbone_mac_address=0x12345678abcd,
                          **soc_kwargs)
        builder = Builder(soc, **builder_argdict(args))
        vns = builder.build(
            threads=args.threads,
            trace=args.trace,
            sim_config=sim_config)

    if args.build:
        kwargs = soc_core_argdict(args)
        soc = SDRAMLoopbackSoC(ip=args.ip, phy=args.ethernet_phy, **kwargs)
        builder = Builder(soc, **builder_argdict(args))
        vns = builder.build(run=not args.program_only)

    if args.load:
        prog = marble.Platform().create_programmer()
        prog.load_bitstream(os.path.join("build", "marble", "gateware", "marble.bit"))


if __name__ == "__main__":
    main()
