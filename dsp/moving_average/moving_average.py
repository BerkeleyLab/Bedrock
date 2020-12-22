'''
nMigen based
'''
from nmigen import Signal, Elaboratable, Module, Array
from nmigen.back import verilog, pysim


class MovingAverage(Elaboratable):
    def __init__(self, MAX_DELAY_BITS=5, dw=16):
        self._dw = dw
        self.MAX_DELAY_BITS = MAX_DELAY_BITS
        self._SREG_LEN = 2**MAX_DELAY_BITS
        self.i, self.o = (Signal((self._dw, True), name='i'),
                          Signal((self._dw, True), name='o'))
        self.data_valid = Signal(name='data_valid')
        # log_downsample_ratio must be a power of 2.
        self.log_downsample_ratio = Signal(MAX_DELAY_BITS, name='log_downsample_ratio')

    def elaborate(self, platform):
        m = Module()
        delay_tap = Signal(self._SREG_LEN)
        m.d.comb += delay_tap.eq(1 << self.log_downsample_ratio)
        # Dynamic delay shift register
        out_val = Signal((self._dw, True))
        delay_reg = Array(Signal((self._dw, True), reset=0) for _ in range(self._SREG_LEN))
        src = self.i
        for x in range(self._SREG_LEN):
            m.d.sync += delay_reg[x].eq(src)
            src = delay_reg[x]
        m.d.comb += out_val.eq(delay_reg[delay_tap - 1])
        counter = Signal((self._dw, True))
        with m.If(counter == delay_tap - 1):
            m.d.sync += counter.eq(0)
            m.d.comb += self.data_valid.eq(1)
        with m.Else():
            m.d.sync += counter.eq(counter + 1)

        moving_average_full = Signal((self._dw + self.MAX_DELAY_BITS, True))
        m.d.sync += moving_average_full.eq(moving_average_full + self.i - out_val)
        m.d.comb += [self.o.eq(moving_average_full >> self.log_downsample_ratio)]
        return m


if __name__ == "__main__":
    dut = MovingAverage()
    print(verilog.convert(dut, name='moving_average',
                          ports=[dut.i, dut.o, dut.data_valid, dut.log_downsample_ratio]))

    sim = pysim.Simulator(dut)
    log_downsample_ratio = 0
    signal_in, signal_out = [], []
    sim.add_clock(1e-6)

    def moving_average_tb():
        yield dut.log_downsample_ratio.eq(log_downsample_ratio)
        for i in range(200):
            yield dut.i.eq(i)
            signal_in.append(i)
            signal_out.append((yield dut.o))
            yield

    sim.add_sync_process(moving_average_tb)
    with sim.write_vcd('foo.vcd', 'foo.gtkw'):
        sim.run()
    try:
        from matplotlib import pyplot as plt
        plt.plot(signal_in)
        plt.plot(signal_out)
        plt.show()
    except Exception:
        print("// Skipped plot")
