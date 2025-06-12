'''
Migen based
'''
from migen import Signal, Module, Array, If, ClockDomain, run_simulation
from migen.fhdl import verilog
from sys import stderr


class MovingAverage(Module):
    def __init__(self, MAX_DELAY_BITS=5, dw=16):
        self._dw = dw
        self.MAX_DELAY_BITS = MAX_DELAY_BITS
        self._SREG_LEN = 2**MAX_DELAY_BITS
        self.i, self.o = (Signal(bits_sign=(self._dw, True), name='i'),
                          Signal(bits_sign=(self._dw, True), name='o'))
        self.data_valid = Signal(name='data_valid')

        # Workaround to rename default sys_clk and sys_rst to clk and rst
        self.clk = Signal()
        self.rst = Signal()
        self.clock_domains.cd_sys = ClockDomain("sys")
        self.comb += self.cd_sys.clk.eq(self.clk)
        self.comb += self.cd_sys.rst.eq(self.rst)

        # log_downsample_ratio must be a power of 2.
        self.log_downsample_ratio = Signal(MAX_DELAY_BITS, name='log_downsample_ratio')
        delay_tap = Signal(self._SREG_LEN)
        self.comb += delay_tap.eq(1 << self.log_downsample_ratio)

        # Dynamic delay shift register
        out_val = Signal(bits_sign=(self._dw, True))
        delay_reg = Array(Signal(bits_sign=(self._dw, True), reset=0) for _ in range(self._SREG_LEN))
        src = self.i
        for x in range(self._SREG_LEN):
            self.sync += delay_reg[x].eq(src)
            src = delay_reg[x]
        self.comb += out_val.eq(delay_reg[delay_tap - 1])
        counter = Signal(bits_sign=(self._dw, True))

        self.sync += [
            If(counter == delay_tap - 1,
               counter.eq(0)).Else(counter.eq(counter + 1))
        ]

        self.comb += [If(counter == delay_tap - 1,
                         self.data_valid.eq(1))]

        moving_average_full = Signal(bits_sign=(self._dw + self.MAX_DELAY_BITS, True))
        self.sync += moving_average_full.eq(moving_average_full + self.i - out_val)
        self.comb += [self.o.eq(moving_average_full >> self.log_downsample_ratio)]


if __name__ == "__main__":
    dut = MovingAverage()
    log_downsample_ratio = 0
    signal_in, signal_out = [], []
    print(verilog.convert(
        dut, ios={dut.i, dut.o, dut.clk, dut.rst, dut.data_valid,
                  dut.log_downsample_ratio}, name='moving_average'))

    def moving_average_tb(dut):
        yield dut.log_downsample_ratio.eq(log_downsample_ratio)
        for i in range(200):
            yield dut.i.eq(i)
            signal_in.append(i)
            signal_out.append((yield dut.o))
            yield

    dut = MovingAverage()
    run_simulation(dut, moving_average_tb(dut), clocks={"sys": 100}, vcd_name="basic1.vcd")
    print("Attempting plot; ignore warnings if running batch", file=stderr)
    try:
        from matplotlib import pyplot as plt
        plt.plot(signal_in)
        plt.plot(signal_out)
        plt.show()
    except Exception:
        print("Skipped plot", file=stderr)
