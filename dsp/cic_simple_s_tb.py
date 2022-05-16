'''
    cocotb based test bench of cic_simple_s.v

    Requires iverilog (Icarus Verilog) in PATH and the following python packages:

    * cocotb >= 1.7.0
    * pathlib
    * matplotlib
    * numpy
    * python >= 3.10
'''

import os
import numpy as np
import matplotlib.pyplot as plt
import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import RisingEdge

CIC_BITS = 16
CIC_AMP = 2**(CIC_BITS - 1)
CIC_DECIMATION = 1024
TRACE_LEN = 2**20

NOISE = CIC_AMP / 64

S1_AMP = CIC_AMP / 4
S2_AMP = CIC_AMP / 5
S3_AMP = CIC_AMP / 16

S1_FREQ = 5
S2_FREQ = 10
S3_FREQ = 12

SAMPLE_RATE = 8


@cocotb.test()
async def cic_simple_s_test(dut):
    '''
        Sends a signal in cic_simple_s and reads the result
    '''
    angle = np.linspace(0.0, 2.0*np.pi, TRACE_LEN)
    trace = NOISE * np.random.normal(size=TRACE_LEN)
    trace += S1_AMP * np.sin(S1_FREQ * angle)
    trace += S2_AMP * np.sin(S2_FREQ * angle)
    trace += S3_AMP * np.sin(S3_FREQ * angle)
    trace = trace.astype(int)

    trace_time = np.linspace(0, TRACE_LEN * SAMPLE_RATE, TRACE_LEN)

    clock = Clock(dut.clk, 10)
    cocotb.start_soon(clock.start())

    filtered_trace = []
    filtered_trace_time = []

    await RisingEdge(dut.clk)

    for i, value in enumerate(trace):
        if (i % 1000 == 0):
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

    plt.figure()
    plt.plot(trace_time, trace,
             label="Before decimation")

    plt.plot(filtered_trace_time, filtered_trace,
             label="After decimation")

    plt.xlabel("Sample")
    plt.ylabel("Amplitude (a.u.)")
    plt.legend()
    plt.show()




def main():
    '''
        Main entry point
    '''
    sim = os.getenv("SIM", "icarus")

    verilog_sources = ["cic_simple_s.v"]

    runner = get_runner(sim)()
    runner.build(verilog_sources=verilog_sources,
                 toplevel="cic_simple_s")

    runner.test(toplevel="cic_simple_s", py_module="cic_simple_s_tb")


if __name__ == '__main__':
    main()
