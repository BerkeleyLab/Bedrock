import argparse

from migen import Signal, Memory, If, Cat, Module, ClockSignal
from migen.genlib.cdc import PulseSynchronizer
# from migen.genlib.fifo import AsyncFIFO

from litex.soc.cores.freqmeter import FreqMeter
from litex.soc.cores import spi
from litex.soc.interconnect import wishbone
from litex.soc.integration.soc_sdram import soc_sdram_args, soc_sdram_argdict
from litex.soc.integration.builder import builder_args, builder_argdict, Builder
from litex.soc.interconnect.csr import CSRStatus, CSRField, AutoCSR, CSRStorage

from litex_boards.platforms import ltc
from litex_boards.targets.marblemini import EthernetSoC, BaseSoC

from ltc_phy import LTCPhy


class DumpToRAM(Module, AutoCSR):
    def __init__(self, width, depth, port, **kwargs):
        self.adc_data = adc_data = Signal(width)
        acq_start, acq_start_x = Signal(reset=0), Signal(reset=0)
        self._buf_full = CSRStatus(fields=[
            CSRField("acq_complete", size=1, offset=0)])
        self._acq_start = CSRStorage(fields=[
            CSRField("acq_start", size=1, offset=0, pulse=True)])
        w_addr = Signal(16, reset=0)
        self.comb += [
            self._buf_full.fields.acq_complete.eq(w_addr == depth),
            acq_start.eq(self._acq_start.fields.acq_start),
            port.adr.eq(w_addr),
            port.dat_w.eq(adc_data),
            port.we.eq(w_addr != depth)
        ]
        self.submodules.ps = PulseSynchronizer("sys", "sample")
        self.comb += [
            self.ps.i.eq(acq_start),
            acq_start_x.eq(self.ps.o)
        ]
        self.sync.sample += [
            If(acq_start_x & (w_addr == depth),
               w_addr.eq(0)).Elif(w_addr != depth, w_addr.eq(w_addr + 1))
        ]


class LTCSocDev(EthernetSoC, AutoCSR):
    csr_peripherals = [
        "lvds",
        "spi",
        "f_sample",
        "acq"
    ]

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.platform.add_extension(ltc.ltc_pads)
        self.submodules.lvds = LTCPhy(self.platform, self.sys_clk_freq, 120e6)
        self.platform.add_false_path_constraints(
            self.crg.cd_sys.clk,
            self.lvds.pads_dco
        )
        # Frequency counter for received sample clock
        self.submodules.f_sample = FreqMeter(self.sys_clk_freq)
        self.comb += self.f_sample.clk.eq(ClockSignal("sample"))

        spi_pads = self.platform.request("LTC_SPI")
        self.submodules.spi = spi.SPIMaster(spi_pads, 16, self.sys_clk_freq, self.sys_clk_freq/32)

        width, depth = 16*2, 8192
        storage = Memory(width, depth, init=[0x1234, 0xCAFECAFE, 0x00C0FFEE])
        self.specials += storage
        self.submodules.adc_data_buffer = wishbone.SRAM(storage, read_only=True)
        port = storage.get_port(write_capable=True, clock_domain="sample")
        self.register_mem(
            "adc_data_buffer",
            0x10000000,
            self.adc_data_buffer.bus,
            depth * 8
        )

        self.specials += port
        self.submodules.acq = DumpToRAM(width, depth, port)
        self.sync.sample += self.acq.adc_data.eq(Cat(Signal(2), self.lvds.sample_outs[0],
                                                     Signal(2), self.lvds.sample_outs[1]))
        self.sync += self.lvds.init_running.eq(self.ctrl.reset)
        for p in LTCSocDev.csr_peripherals:
            self.add_csr(p)


def main():
    parser = argparse.ArgumentParser(description="LiteX SoC on MarbleMini")
    builder_args(parser)
    soc_sdram_args(parser)
    # soc_core_args(parser)
    parser.add_argument("--with-ethernet", action="store_true",
                        help="enable Ethernet support")
    parser.add_argument("--ethernet-phy", default="rgmii",
                        help="select Ethernet PHY (rgmii or 1000basex)")
    parser.add_argument("-p", "--program-only", action="store_true",
                        help="select Ethernet PHY (rgmii or 1000basex)")
    args = parser.parse_args()

    if args.with_ethernet:
        soc = LTCSocDev(phy=args.ethernet_phy, **soc_sdram_argdict(args))
        # soc = EthernetSoC(phy=args.ethernet_phy, **soc_sdram_argdict(args))
        # soc = EthernetSoC(phy=args.ethernet_phy, **soc_core_argdict(args))
    else:
        soc = BaseSoC(**soc_sdram_argdict(args))

    builder = Builder(soc, **builder_argdict(args))
    if not args.program_only:
        vns = builder.build()

        if False:
            soc.analyzer.do_exit(vns)

    prog = soc.platform.create_programmer()
    import os
    prog.load_bitstream(os.path.join(builder.gateware_dir, "marblemini.bit"))


if __name__ == "__main__":
    main()
