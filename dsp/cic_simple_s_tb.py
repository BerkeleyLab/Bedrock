'''
    cocotb based test bench of cic_simple_s.v

    Requires iverilog (Icarus Verilog) in PATH and the following python packages:

    * cocotb
    * pathlib
    * matplotlib
    * numpy
'''

import numpy as np
#import matplotlib.pyplot as plt
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

CIC_BITS = 16
CIC_AMP = 2**(CIC_BITS - 1)
CIC_DECIMATION = 2**5
TRACE_LEN = 2**14

NOISE = CIC_AMP / 32
MAX_ERR = 1000

S1_AMP = CIC_AMP / 4
S2_AMP = CIC_AMP / 5
S3_AMP = CIC_AMP / 16

S1_PERIOD = 2
S2_PERIOD = 3
S3_PERIOD = 4

SAMPLE_RATE = 8


@cocotb.test()
async def cic_simple_s_test_no_noise(dut):
    '''
        Sends a signal in cic_simple_s and reads the result. No noise
    '''
    trace_time, trace = prepare_traces()
    original_trace = np.copy(trace)
    trace = trace.astype(int)
    filtered_trace_time, filtered_trace = await run_simulation(dut, trace)
    test_trace(filtered_trace_time,
               filtered_trace,
               trace_time,
               original_trace)


@cocotb.test()
async def cic_simple_s_test_noise(dut):
    '''
        Sends a signal in cic_simple_s and reads the result. Noisy input
    '''
    trace_time, trace = prepare_traces()
    original_trace = np.copy(trace)
    noise = NOISE * np.random.normal(size=TRACE_LEN)
    trace += noise
    trace = trace.astype(int)
    trace_time = np.linspace(0, TRACE_LEN * SAMPLE_RATE, TRACE_LEN)
    filtered_trace_time, filtered_trace = await run_simulation(dut, trace)
    print('Max noise amplitude', np.max(np.abs(noise)))
    test_trace(filtered_trace_time,
               filtered_trace,
               trace_time,
               original_trace)


def prepare_traces():
    '''
        Generates input traces
    '''
    angle = np.linspace(0.0, 2.0*np.pi, TRACE_LEN)
    trace = np.zeros(TRACE_LEN)
    trace += S1_AMP * np.sin(S1_PERIOD * angle)
    trace += S2_AMP * np.sin(S2_PERIOD * angle)
    trace += S3_AMP * np.sin(S3_PERIOD * angle)
    trace_time = np.linspace(0, TRACE_LEN * SAMPLE_RATE, TRACE_LEN)
    return trace_time, trace


def test_trace(filtered_trace_time,
               filtered_trace,
               trace_time,
               original_trace):
    '''
        Asserts the equality of filtered_trace and original_trace
    '''
    original_decimated = np.interp(filtered_trace_time,
                                   trace_time + SAMPLE_RATE * CIC_DECIMATION,
                                   original_trace)
    max_diff = np.max(np.abs(filtered_trace - original_decimated))
    print('Max diff', max_diff)

    assert max_diff < MAX_ERR

    # plt.figure()
    # plt.plot(filtered_trace)
    # plt.plot(original_decimated)
    # plt.show()


async def run_simulation(dut, trace):
    '''
        Runs the simulation with a given trace and DUT, returns the produced data.
    '''
    clock = Clock(dut.clk, 10)
    cocotb.start_soon(clock.start())

    filtered_trace = []
    filtered_trace_time = []

    await RisingEdge(dut.clk)

    for i, value in enumerate(trace):
        if i % 1000 == 0:
            print(i, '/', len(trace))

        dut.data_in_gate.value = True
        dut.data_in.value = int(value)

        for j in range(SAMPLE_RATE):
            if dut.data_out_gate.value.integer:
                filtered_trace.append(dut.data_out.value.signed_integer)
                filtered_trace_time.append(i*SAMPLE_RATE + j)

            await RisingEdge(dut.clk)
            dut.data_in_gate.value = False

    filtered_trace = np.array(filtered_trace)
    filtered_trace_time = np.array(filtered_trace_time)

    return filtered_trace_time, filtered_trace
