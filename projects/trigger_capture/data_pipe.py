import argparse

from migen import log2_int, If, Signal, Module, Cat, FSM, NextValue, NextState

from litedram.frontend.fifo import LiteDRAMFIFO
from litex.soc.integration.builder import builder_args, Builder, builder_argdict
from litex.tools.litex_sim import SimSoC, SimConfig
from litex.soc.integration.soc_core import soc_core_args, soc_core_argdict

from litex.soc.interconnect import stream
from litex.soc.interconnect.csr import CSRStatus, AutoCSR, CSRStorage
from litex.soc.interconnect.packet import Header, HeaderField, Packetizer
from litex.soc.interconnect.stream import EndpointDescription
from liteeth.common import eth_udp_user_description, convert_ip
# from liteeth.frontend.stream import LiteEthStream2UDPTX


fragmenter_header_length = 8
fragmenter_header_fields = {
    "total_fragmets":    HeaderField(0, 0, 32),
    "fragment_id":       HeaderField(4, 0, 32),
}
fragmenter_header = Header(fragmenter_header_fields,
                           fragmenter_header_length,
                           swap_field_bytes=True)


def udp_fragmenter_description(dw):
    param_layout = [
        ("length",     32),
    ]
    payload_layout = fragmenter_header.get_layout() + [
        ("data",       dw),
    ]
    return EndpointDescription(payload_layout, param_layout)


class UDPFragmenterPacketizer(Packetizer):
    def __init__(self, dw=8):
        Packetizer.__init__(self,
            udp_fragmenter_description(dw),
            eth_udp_user_description(dw),
            fragmenter_header)


class UDPFragmenter(Module):
    '''
    UDP Fragmenter that respects liteth.common.eth_mtu and breaking up data
    from sink into multiple packets, by manipulating the source which is
    tied into IPV4Packetizer
    TODO:
    1. Further investigate if the DELAY state is necessary.
    2. IP_MTU calculation -30 seems pretty arbitrary, need to find refs
    3. NextValue is it recommended?
    '''
    # TODO: compute this from eth_mtu

    def __init__(self, dw=8):
        self.UDP_FRAG_MTU = UDP_FRAG_MTU = 1472 - 8  # The -8 is because of FRAGMENTER header
        self.sink   = sink = stream.Endpoint([("data", dw), ("length", 32)])
        self.source = source = stream.Endpoint(eth_udp_user_description(dw))
        self.packetizer = packetizer = UDPFragmenterPacketizer()
        self.submodules += packetizer

        self.mf = mf = Signal(reset=0)  # mf == More Fragments
        self.fragment_offset = fragment_offset = Signal(32, reset=0)
        self.identification = identification = Signal(16, reset=0)
        self.fragment_id = fragment_id = Signal(32, reset=0)

        self.comb += [
            sink.connect(packetizer.sink, omit={"length"}),
            packetizer.sink.total_fragmets.eq(identification),
            packetizer.sink.fragment_id.eq(fragment_id),
            packetizer.source.connect(source),
        ]

        ww = dw // 8

        # counter logic ;)
        self.foo_counter = counter = Signal(32)
        counter_reset = Signal()
        counter_ce = Signal()
        self.sync += \
            If(counter_reset,
                counter.eq(0)
            ).Elif(counter_ce,
                counter.eq(counter + ww)
            )
        bytes_in_fragment = Signal(16, reset=0)

        self.submodules.fsm = fsm = FSM(reset_state="IDLE")
        fsm.act("IDLE",
                sink.ready.eq(packetizer.sink.ready),
                If(sink.valid,
                   If(sink.length < UDP_FRAG_MTU,
                      sink.connect(packetizer.sink, omit={"length"}),
                      # TODO
                      source.length.eq(sink.length)
                   ).Else(
                       sink.ready.eq(0),
                       source.length.eq(UDP_FRAG_MTU + 8),
                       counter_reset.eq(1),
                       NextValue(mf, 1),
                       NextValue(fragment_offset, 0),
                       NextValue(fragment_id, 0),
                       NextValue(identification, identification + 1),
                       NextValue(bytes_in_fragment, UDP_FRAG_MTU),
                       NextState("FRAGMENTED_PACKET_SEND")
                   )
                )
            )

        fsm.act("FRAGMENTED_PACKET_SEND",
                sink.connect(packetizer.sink, omit={"length"}),
                packetizer.sink.length.eq(bytes_in_fragment),
                source.length.eq(bytes_in_fragment + 8),
                If(sink.valid & packetizer.sink.ready,
                   counter_ce.eq(1)
                ),
                If(counter == (bytes_in_fragment - ww),
                   NextValue(fragment_offset,
                             fragment_offset + (bytes_in_fragment >> 3)),
                   packetizer.sink.last.eq(1),
                   If(((fragment_offset << 3) + counter + ww) == sink.length,
                      NextValue(fragment_offset, 0),
                      NextState("IDLE")
                   ).Else(
                       counter_ce.eq(0),
                       NextState("NEXT_FRAGMENT"))
                )
        )

        fsm.act("NEXT_FRAGMENT",
                counter_ce.eq(0),
                sink.ready.eq(0),
                packetizer.sink.valid.eq(0),
                packetizer.sink.length.eq(bytes_in_fragment),
                source.length.eq(bytes_in_fragment + 8),
                counter_reset.eq(1),
                If((sink.length - (fragment_offset << 3)) > UDP_FRAG_MTU,
                    NextValue(bytes_in_fragment, UDP_FRAG_MTU),
                ).Else(
                    NextValue(bytes_in_fragment,
                              sink.length - (fragment_offset << 3)),
                    NextValue(mf, 0),
                ),
                NextValue(fragment_id, fragment_id + 1),
                NextState("FRAGMENTED_PACKET_SEND")
        )


class Counter(Module):
    def __init__(self, nbits, enable_on_reset=1):
        self.count = Signal(nbits)
        self.en = Signal(reset=enable_on_reset)
        self.sync += If(self.en,
                        self.count.eq(self.count + 1))


class ADCStream(Module):
    def __init__(self, nch=4, bits=16, cycles_per_sample=1, ramp=True):
        self.dw = nch * bits
        self.source = source = stream.Endpoint([("data", self.dw)])
        assert cycles_per_sample == 1
        self.submodules.ramp = ramp = Counter(bits)
        valid = Signal(reset=0)
        self.sync += valid.eq(~valid)
        self.comb += [source.data.eq(Cat(*[ramp.count + ch for ch in range(nch)])),
                      source.valid.eq(valid)]


class DataPipeWithoutBypass(Module, AutoCSR):
    def __init__(self, ddr_wr_port, ddr_rd_port, udp_port, adc_source, adc_dw):
        SIZE = 1024 * 1024
        self.fifo_full  = CSRStatus(reset=0)
        self.fifo_error = CSRStatus(reset=0)
        self.fifo_load  = CSRStorage(reset=0)
        self.fifo_read  = CSRStorage(reset=0)
        self.fifo_size  = CSRStorage(32, reset=SIZE)
        self.dst_ip     = CSRStorage(32, reset=convert_ip("192.168.1.114"))
        self.dst_port   = CSRStorage(16, reset=7778)

        self.fifo_counter = fifo_counter = Signal(24)
        self.load_fifo    = load_fifo    = Signal()

        dw = ddr_wr_port.data_width

        print(f"Write port: A ({ddr_wr_port.address_width})/ D ({ddr_wr_port.data_width})")
        print(f"Read port: A ({ddr_rd_port.address_width})/ D ({ddr_rd_port.data_width})")
        print(f"dw: {dw}; adc_dw: {adc_dw}")
        self.submodules.dram_fifo = dram_fifo = LiteDRAMFIFO(
            data_width  = dw,
            base        = 0,
            depth       = SIZE,
            write_port  = ddr_wr_port,
            read_port   = ddr_rd_port,
        )

        self.adc_data = adc_data = Signal(dw)
        DW_RATIO = dw // adc_dw
        log_dw_ratio = log2_int(DW_RATIO)
        word_count = Signal(log_dw_ratio)
        word_count_d = Signal(log_dw_ratio)

        self.sync += [
            If(adc_source.valid,
               adc_data.eq(Cat(adc_data[adc_dw:], adc_source.data)),
               word_count.eq(word_count + 1)
            ),
            word_count_d.eq(word_count),
        ]

        self.comb += [
            dram_fifo.sink.valid.eq((word_count == 0) & (word_count_d != 0) & load_fifo),
            dram_fifo.sink.data.eq(adc_data)
        ]

        fifo_size = Signal(32)
        self.sync += [
            fifo_size.eq(self.fifo_size.storage),
            If(self.fifo_load.re & self.fifo_load.storage,
               fifo_counter.eq(0),
               load_fifo.eq(1)
            ),
            If(load_fifo & adc_source.valid,
               self.fifo_full.status.eq(0),
               self.fifo_error.status.eq(~dram_fifo.dram_fifo.ctrl.writable),
               fifo_counter.eq(fifo_counter + 1)
            ),
            If((fifo_counter == fifo_size - 1) & adc_source.valid,
               load_fifo.eq(0),
               self.fifo_full.status.eq(1)
            ),
        ]

        # fifo --> stride converter
        self.submodules.stride_converter = sc = stream.Converter(dw, udp_port.dw)

        self.read_from_dram_fifo = read_from_dram_fifo = Signal()
        self.comb += [
            dram_fifo.source.connect(sc.sink)
        ]
        self.receive_count = receive_count = Signal(24)
        self.sync += [
            If(dram_fifo.source.valid & dram_fifo.source.ready,
               receive_count.eq(receive_count + 1)
            ).Elif(read_from_dram_fifo == 0,
                   receive_count.eq(0)
            )
        ]
        # --> udp fragmenter -->
        self.submodules.udp_fragmenter = udp_fragmenter = UDPFragmenter(udp_port.dw)

        self.sync += read_from_dram_fifo.eq(self.fifo_read.storage)
        self.comb += If(read_from_dram_fifo,
                        # TODO: There is a bug somewhere in the converter,
                        # its source.last somehow gets set, no idea why. That signal is of no real use
                        # for the fragmenter anyways, so we live without it
                        sc.source.connect(udp_fragmenter.sink, omit={'total_size', 'last'}))

        # TODO: 8 should be adcstream data width // 8
        self.comb += udp_fragmenter.sink.length.eq(SIZE << log2_int(adc_dw//8))
        self.comb += udp_fragmenter.source.connect(udp_port.sink)
        self.comb += [
            # param
            udp_port.sink.src_port.eq(4321),
            udp_port.sink.dst_port.eq(self.dst_port.storage),
            udp_port.sink.ip_address.eq(self.dst_ip.storage),
            # udp_port.sink.ip_address.eq(convert_ip("192.168.88.101")),
            # payload
            udp_port.sink.error.eq(0)
        ]


class DataPipe(Module, AutoCSR):

    def __init__(self, ddr_wr_port, ddr_rd_port, udp_port):
        SIZE = 1024 * 1024
        SIZE = 1024
        self.fifo_full = CSRStatus(reset=0)
        self.fifo_error = CSRStatus(reset=0)
        self.fifo_load = CSRStorage(reset=0)  # Load the coefficients in memory to the ROI Summer
        self.fifo_read = CSRStorage(reset=0)
        self.fifo_size = CSRStorage(32, reset=SIZE)
        self.dst_ip = CSRStorage(32, reset=convert_ip("192.168.1.114"))
        self.dst_port = CSRStorage(16, reset=7778)

        dw = 64
        print(f"Write port: A ({ddr_wr_port.address_width})/ D ({ddr_wr_port.data_width})")
        print(f"Read port: A ({ddr_rd_port.address_width})/ D ({ddr_rd_port.data_width})")
        self.submodules.dram_fifo = dram_fifo = LiteDRAMFIFO(
            data_width  = dw,
            base        = 0,
            depth       = SIZE,
            write_port  = ddr_wr_port,
            read_port   = ddr_rd_port,
            with_bypass = True,
        )
        # self.mf = mf = Signal(reset=0)  # mf == More Fragments
        # self.fragment_offset = fragment_offset = Signal(13, reset=0)
        # self.identification = identification = Signal(16, reset=0)

        self.submodules.adcs = adcs = ADCStream(1, dw)
        self.fifo_counter = fifo_counter = Signal(24)
        self.load_fifo = load_fifo = Signal()

        # adc --> buffer_fifo
        self.submodules.buffer_fifo = buffer_fifo = stream.SyncFIFO(stream.EndpointDescription([("data", dw)]),
                                                                    256,
                                                                    buffered=True)
        # buffer_fifo --> dram_fifo
        fifo_size = Signal(32)
        self.sync += [
            fifo_size.eq(self.fifo_size.storage),
            If(self.fifo_load.re & self.fifo_load.storage,
               fifo_counter.eq(0),
               load_fifo.eq(1)
            ),
            If(load_fifo & adcs.source.valid,
               self.fifo_full.status.eq(0),
               self.fifo_error.status.eq(~dram_fifo.dram_fifo.ctrl.writable),
               fifo_counter.eq(fifo_counter + 1)
            ),
            If((fifo_counter == fifo_size - 1) & adcs.source.valid,
               load_fifo.eq(0),
               self.fifo_full.status.eq(1)
            ),
        ]

        self.comb += [
            buffer_fifo.sink.data.eq(adcs.source.data),
            buffer_fifo.sink.valid.eq(adcs.source.valid & load_fifo),
            buffer_fifo.source.connect(dram_fifo.sink),
        ]

        # fifo --> stride converter
        self.submodules.stride_converter = sc = stream.Converter(dw, udp_port.dw)

        self.read_from_dram_fifo = read_from_dram_fifo = Signal()
        self.comb += [
            dram_fifo.source.connect(sc.sink)
        ]
        self.receive_count = receive_count = Signal(24)
        self.sync += [
            If(dram_fifo.source.valid & dram_fifo.source.ready,
               receive_count.eq(receive_count + 1)
            ).Elif(read_from_dram_fifo == 0,
                   receive_count.eq(0)
            )
        ]
        # --> udp fragmenter -->
        self.submodules.udp_fragmenter = udp_fragmenter = UDPFragmenter(udp_port.dw)

        self.sync += read_from_dram_fifo.eq(self.fifo_read.storage)
        self.comb += If(read_from_dram_fifo,
                        # TODO: There is a bug somewhere in the converter,
                        # its source.last somehow gets set, no idea why. That signal is of no real use
                        # for the fragmenter anyways, so we live without it
                        sc.source.connect(udp_fragmenter.sink, omit={'total_size', 'last'}))

        # TODO: 8 should be adcstream data width // 8
        self.comb += udp_fragmenter.sink.length.eq(fifo_size << log2_int(dw//8))
        self.comb += udp_fragmenter.source.connect(udp_port.sink)
        self.comb += [
            # param
            udp_port.sink.src_port.eq(4321),
            udp_port.sink.dst_port.eq(self.dst_port.storage),
            udp_port.sink.ip_address.eq(self.dst_ip.storage),
            # udp_port.sink.ip_address.eq(convert_ip("192.168.88.101")),
            # payload
            udp_port.sink.error.eq(0)
        ]

        # debug
        self.first_sample, self.last_sample = Signal(16), Signal(16)
        self.sync += [
            If(fifo_counter == 1, self.first_sample.eq(adcs.source.data[:16])),
            If(fifo_counter == SIZE - 2, self.last_sample.eq(adcs.source.data[:16])),
        ]


class SDRAMSimSoC(SimSoC):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.udp_port = udp_port = self.udp.crossbar.get_port(4321, 8)

        ddr_wr_port, ddr_rd_port = self.sdram.crossbar.get_port("write"), self.sdram.crossbar.get_port("read")
        adc_dw = 16
        adcs = ADCStream(1, adc_dw)
        self.submodules.data_pipe = DataPipeWithoutBypass(ddr_wr_port, ddr_rd_port, udp_port, adcs.source, adc_dw)
        self.add_csr("data_pipe")


def main():
    parser = argparse.ArgumentParser(description="Datapipe simulation SoC*")
    builder_args(parser)
    soc_core_args(parser)
    # soc_core_args(parser)
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
    parser.add_argument("--threads", default=4,
                        help="set number of threads (default=4)")
    parser.add_argument("--trace", action="store_true",
                        help="enable VCD tracing")
    args = parser.parse_args()

    soc_kwargs = soc_core_argdict(args)
    sim_config = SimConfig(default_clk="sys_clk")
    soc_kwargs["integrated_main_ram_size"] = 0x10000
    soc_kwargs = soc_core_argdict(args)
    soc_kwargs["uart_name"] = "sim"
    # sim_config.add_module("serial2console", "serial")
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
    # discard result, or save in vns?
    builder.build(
        threads=args.threads,
        trace=args.trace,
        sim_config=sim_config)


if __name__ == "__main__":
    main()
