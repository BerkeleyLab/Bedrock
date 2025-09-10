import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge


class TB:
    def __init__(self, dut):
        self.dut = dut
        self.fcnt_width = dut.FCNT_WIDTH.value
        # update this to try different reference frequency
        self.gt_refclk_freq = 125e6
        gt_refclk = Clock(
            dut.gt_refclk_p, 1e12 // self.gt_refclk_freq, units="ps")
        cocotb.start_soon(Clock(dut.sys_clk, 10, units="ns").start())
        cocotb.start_soon(Clock(dut.dsp_clk, 4, units="ns").start())
        cocotb.start_soon(gt_refclk.start())

        # Init other DUT inputs
        self.dut.gt_rxp.setimmediatevalue(0)
        self.dut.gt_rxn.setimmediatevalue(0)
        self.dut.evcode.setimmediatevalue(0)
        self.dut.evr_oc_delay.setimmediatevalue(0)

    def convert_freq_to_hz(self, f_cnt, f_ref=100e6):
        return (f_cnt / 2**self.fcnt_width) * f_ref

    def check_freq(self, freq, freq_expect, tolerance_ppm=2000.0):
        ppm = ((freq / freq_expect) - 1.0) * 1e6
        assert abs(ppm) < tolerance_ppm, \
            f"Freq is out of spec by {ppm:3.0f} ppm"

    async def cycle_reset(self):
        self.dut.reset_all.value = 0
        await ClockCycles(self.dut.sys_clk, 5)
        self.dut.reset_all.value = 1
        await ClockCycles(self.dut.sys_clk, 5)
        self.dut.reset_all.value = 0


# timeout_time=total amount of time for the outputs to settle down
@cocotb.test(timeout_time=5, timeout_unit='us')
async def test_reset(dut):
    tb = TB(dut)
    # Toggle reset_all directly
    for value in [0, 1]:
        dut.reset_all.value = value
        await ClockCycles(dut.sys_clk, 5)
    # Wait for alignment
    await ClockCycles(dut.sys_clk, 100)
    reset_rx_done = dut.rx_reset_done_sys.value.integer
    assert reset_rx_done == 1, "reset_rx_done is not set"

    await ClockCycles(dut.sys_clk, 150)
    rx_aligned = dut.rx_aligned_sys.value.integer
    assert rx_aligned == 1, "rx_aligned is not set"


@cocotb.test(timeout_time=6, timeout_unit='us')
async def test_freq_counter(dut):
    tb = TB(dut)
    await tb.cycle_reset()

    # Wait for the frequency counter to stabilize
    await ClockCycles(dut.sys_clk, 500)

    # Read raw counter values directly
    gt_refclk_freq = tb.convert_freq_to_hz(dut.gt_ref_freq.value.integer)
    gt_rx_freq = tb.convert_freq_to_hz(dut.gt_rx_freq.value.integer)

    dut._log.info(f"gt_ref_freq: {gt_refclk_freq/1e6} MHz")
    dut._log.info(f"gt_rx_freq:  {gt_rx_freq/1e6} MHz")

    tb.check_freq(gt_refclk_freq, tb.gt_refclk_freq)
    tb.check_freq(gt_rx_freq, tb.gt_refclk_freq)
