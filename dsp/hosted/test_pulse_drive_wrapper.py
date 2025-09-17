import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

ADC_CLK_CYCLE_NS = 10.606
DSP_CLK = 1320 / 14

# Fractional cycles per trigger for each repetition rate
CYCLES_PER_TRIGGER = {
    1_000_000: (1400 / 1300) * DSP_CLK,
    100_000:   (14000 / 1300) * DSP_CLK,
    10_000:    (140000 / 1300) * DSP_CLK,
}

REP_RATES = list(CYCLES_PER_TRIGGER.keys())

MIN_SWITCH = 1
MAX_SWITCH = 3

# Bit width limits for input amp and width
AMP_MIN = -(2**17)
AMP_MAX = (2**17) - 1
WTH_MIN = 0
WTH_MAX = (2**7) - 1

# Frequency at which to randomize amplitudes and widths
RANDOMIZE_INTERVAL = 3


@cocotb.test()
async def pulse_drive_fractional_cycles(dut):
    # Generate bunch_arrival_trig with fractional cycle accuracy,
    # measure real cycles between triggers,
    # and randomize wth and amps on rate switches.
    # Start DUT clock
    cocotb.start_soon(Clock(dut.clk, ADC_CLK_CYCLE_NS, units="ns").start())

    # Init DUT inputs
    dut.iq.value = 0
    dut.bunch_arrival_trig.value = 0

    # Assign initial random values
    if hasattr(dut, "ampx") and hasattr(dut, "ampy"):
        dut.ampx.value = random.randint(AMP_MIN, AMP_MAX)
        dut.ampy.value = random.randint(AMP_MIN, AMP_MAX)
    dut.wth.value = random.randint(WTH_MIN, WTH_MAX)

    await Timer(1, units="ns")
    cocotb.log.info(
        f"Initial ampx={dut.ampx.value.signed_integer}, "
        f"ampy={dut.ampy.value.signed_integer}, "
        f"wth={int(dut.wth.value)}"
    )

    # Start with a random rate
    current_rate = random.choice(REP_RATES)
    cycles_per_trigger = CYCLES_PER_TRIGGER[current_rate]
    phase = 0.0
    switch_count = random.randint(MIN_SWITCH, MAX_SWITCH)

    cocotb.log.info(f"Starting at {current_rate} Hz, target cycles = {cycles_per_trigger:.6f}")

    trigger_count = 0
    MAX_TRIGGERS = 20
    cycle_counter = 0
    last_trigger_time_ns = None

    while trigger_count < MAX_TRIGGERS:
        await RisingEdge(dut.clk)

        # Toggle iq every clock cycle
        dut.iq.value = (dut.iq.value + 1) & 0x1

        cycle_counter += 1
        phase += 1.0

        trigger_now = False
        if phase >= cycles_per_trigger:
            phase -= cycles_per_trigger
            trigger_now = True

        dut.bunch_arrival_trig.value = int(trigger_now)

        if trigger_now:
            trigger_count += 1
            now_ns = cocotb.utils.get_sim_time('ns')

            if last_trigger_time_ns is not None:
                time_diff_ns = now_ns - last_trigger_time_ns
                real_cycles = time_diff_ns / ADC_CLK_CYCLE_NS
                cocotb.log.info(
                    f"Trigger #{trigger_count}: "
                    f"Integer cycles = {cycle_counter}, "
                    f"Real cycles = {real_cycles:.2f}, "
                    f"Target = {cycles_per_trigger:.2f}, "
                    f"ampx={dut.ampx.value.signed_integer}, "
                    f"ampy={dut.ampy.value.signed_integer}, "
                    f"wth={int(dut.wth.value)}"
                )

            last_trigger_time_ns = now_ns
            cycle_counter = 0

            # Randomize amps and width every RANDOMIZE_INTERVAL triggers
            if trigger_count % RANDOMIZE_INTERVAL == 0:
                if hasattr(dut, "ampx") and hasattr(dut, "ampy"):
                    dut.ampx.value = random.randint(AMP_MIN, AMP_MAX)
                    dut.ampy.value = random.randint(AMP_MIN, AMP_MAX)
                dut.wth.value = random.randint(WTH_MIN, WTH_MAX)

            # Handle rate switch
            if switch_count == 0:
                new_rate = random.choice([r for r in REP_RATES if r != current_rate])
                current_rate = new_rate
                cycles_per_trigger = CYCLES_PER_TRIGGER[current_rate]

                cocotb.log.info(
                    f"Switching to {current_rate} Hz, "
                    f"target cycles = {cycles_per_trigger:.2f}"
                )

                switch_count = random.randint(MIN_SWITCH, MAX_SWITCH)
                phase = 0.0
            else:
                switch_count -= 1
