import cocotb
import numpy as np
import random
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


def calc_dds(num, den, dwh, dwl):
    m, modulo = divmod((1 << dwl), den)
    r = (1 << dwh) * num
    phase_step_h = int(r / den)
    phase_step_l = int(r % den * m)
    return phase_step_h, phase_step_l, modulo


@cocotb.test()
async def test_dds(dut):
    # try random clocks
    clk_period_ns = random.randint(1, 20)
    f_clk_mhz = 1000 / clk_period_ns
    cocotb.start_soon(Clock(dut.clk, clk_period_ns, unit="ns").start())
    # have any possible ratios
    allowed_ratios = [(7, 33), (4, 11), (4, 23), (3, 14), (11, 28), (8, 11)]
    num, den = random.choice(allowed_ratios)
    # Calculate expected frequency
    expected_f_out_mhz = f_clk_mhz * (num / den)
    dwh = dut.DWH.value.to_unsigned()
    dwl = dut.DWL.value.to_unsigned()
    # get register values
    step_h, step_l, mod = calc_dds(num, den, dwh, dwl)
    dut.phase_step_h.value = step_h
    dut.phase_step_l.value = step_l
    dut.modulo.value = mod
    dut.amplitude.value = 75000
    dut.phase_shift.value = 0
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 100)
    await RisingEdge(dut.clk)
    i_val = dut.cos_out.value.to_signed()
    q_val = dut.sin_out.value.to_signed()
    baseline_phs = np.angle(i_val + 1j * q_val, deg=True)
    # measure frequency
    prev_phs = baseline_phs
    mfreq = []
    for _ in range(10):
        await RisingEdge(dut.clk)
        i_val = dut.cos_out.value.to_signed()
        q_val = dut.sin_out.value.to_signed()
        current_phs = np.angle(i_val + 1j * q_val, deg=True)
        m_step_deg = (current_phs - prev_phs) % 360
        freq_produced_mhz = f_clk_mhz * (m_step_deg / 360.0)
        mfreq.append(freq_produced_mhz)
        prev_phs = current_phs

    actual_f_out_mhz = np.mean(mfreq)
    # try random phase shift
    random_target_deg = random.uniform(1, 359)
    if random_target_deg > 180.0:
        signed_target_deg = random_target_deg - 360.0
    else:
        signed_target_deg = random_target_deg
    ps_width = dut.DWLO.value.to_unsigned() + 1
    hw_phs_shift = int((signed_target_deg / 360.0) * (1 << ps_width))
    expected_shift_deg = ((hw_phs_shift / (1 << ps_width)) * 360.0) % 360
    dut.phase_shift.value = hw_phs_shift
    dut.reset.value = 1
    await ClockCycles(dut.clk, 2)
    dut.reset.value = 0
    await ClockCycles(dut.clk, 100)
    await RisingEdge(dut.clk)
    i_val = dut.cos_out.value.to_signed()
    q_val = dut.sin_out.value.to_signed()
    shifted_phs = np.angle(i_val + 1j * q_val, deg=True)
    measured_shift_deg = (shifted_phs - baseline_phs) % 360

    error_mhz = abs(expected_f_out_mhz - actual_f_out_mhz)
    error_phase = abs(expected_shift_deg - measured_shift_deg)

    cocotb.log.info(f"Config:          ratio = {num}/{den}, clock = {f_clk_mhz:.2f} MHz")
    cocotb.log.info(f"Expected freq:   {expected_f_out_mhz:.2f} MHz")
    cocotb.log.info(f"Measured freq:   {actual_f_out_mhz:.2f} MHz")
    cocotb.log.info("---")
    cocotb.log.info(f"Target phase shift:    {random_target_deg:.2f} deg (reg val: {hw_phs_shift})")
    cocotb.log.info(f"Measured phase shift:  {measured_shift_deg:.2f} deg")
    assert error_mhz < 0.05, (f"Freq mismatch: expected {expected_f_out_mhz:.2f} MHz, "
                              f"measured {actual_f_out_mhz:.2f} MHz")
    assert error_phase < 1.0, (f"Phase shift mismatch: expected {expected_shift_deg:.2f} deg, "
                               f"measured {measured_shift_deg:.2f} deg")
