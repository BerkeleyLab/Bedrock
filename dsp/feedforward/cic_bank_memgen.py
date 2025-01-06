from simple import quad_setup

import json
from sys import argv


# spread integer val across npt nearly-evenly distributed bins
def expand(val, npt):
    xx = [int(x*val/npt) for x in range(npt)] + [val]
    return [b-a for a, b in zip(xx[:-1], xx[1:])]


def fill0(xx):
    return sum([[x, 0, 0, 0] for x in xx], [])


def fill1(xx):
    return sum([[0, x, 0, 0] for x in xx], [])


def add_header(xx):
    sz = len(xx) + 4
    if sz > (2048):
        print("Calculated table (%d) does not fit in available memory. Aborting" % sz)
        exit(-1)
    return [sz, 0, 0, 0] + xx


# dt = 0.0186 maximally flat with cavity_decay -77500
# dt = 0.0200 maximally flat with cavity_decay -83030
# XXX explain
def pulse_setup(dt_arg=0.02, d_amp=50000, t_fill_arg=1.728, t_flat_arg=1.0, ramp_x=0.94, tau=0.095):
    # All time parameters are in units of cavity tau
    dt = dt_arg / tau
    t_fill = t_fill_arg / tau
    t_flat = t_flat_arg / tau
    # d_amp is equilibrium drive amplitude (at flat top)
    # suggest keeping t_fill in range (1.50, 2.0)
    # ramp_x is normalized transition time
    kc0, equilib = quad_setup(t_fill)
    slp = 2*kc0/equilib*t_fill
    t_ramp = -1.0/slp
    # equilib = 0.7072
    # t_ramp = 2.086
    d_amp1 = d_amp/equilib  # initial drive amplitude
    shift_fact = 32  # 1 << stage
    # triangle such that 1 = ramp_x * (ramp_x + r2)
    fudge = 0.9979
    r2 = 1.0/ramp_x - ramp_x
    n1 = int(t_fill*ramp_x/dt+0.5)
    n2 = int(t_fill*r2/dt+0.5)
    qxa = -(d_amp1 - d_amp) * shift_fact*2 / t_fill  # idealized area
    # Adjust the triangle height based on the quantized times.
    # Tries to make the flat-top as close as possible to configured value.
    qx = qxa * fudge * t_fill / float(n1+n2)
    # print(n1, n2, qx)
    #
    n0 = 4
    n3 = int(t_flat/dt)
    n4 = int(t_ramp/dt)
    #
    a = [0]*4
    a += fill0(expand(int(d_amp1), n0))
    # a += fill1(expand(int(qx), n1))
    # Combine first three time slices into one
    # to minimize the persistent effect the four-cycle rise-time (n0)
    # has on the pulse shape.
    xx = expand(int(qx), n1)
    xx = [sum(xx[:3])] + xx[3:]
    a += fill1(xx)
    a += fill1(expand(-int(qx), n2))
    a += [0, 0, 0, 0] * n3
    a += fill0(expand(-int(d_amp), n4))
    return add_header(a)


def square_pulse_setup(dt_arg=0.02, d_amp=50000, t_fill_arg=0.5, t_flat_arg=1.0, ramp_x=0.94, tau=0.095):
    # All time parameters are in SI units
    dt = dt_arg
    t_flat = t_flat_arg

    # d_amp is equilibrium drive amplitude (at flat top)

    n_rise_fall = 1
    n_flat = int(t_flat/dt)
    a = fill0(expand(int(d_amp), n_rise_fall))
    a += fill0(expand(0, n_flat))
    a += fill0(expand(-int(d_amp), n_rise_fall))
    a += fill0(expand(0, 260))  # Decay time
    return add_header(a)


def gen_array(pulse_vals, print_me=True):
    filln = 4*512 - len(pulse_vals)
    pulse_vals += [0] * filln

    if print_me:
        for x in pulse_vals:
            print(x)

    return pulse_vals


if __name__ == "__main__":
    with open(argv[1]) as json_input:
        cfg = json.load(json_input)

    pulse_vals = pulse_setup(cfg["dt"], cfg["d_amp"], cfg["t_fill"],
                             cfg["t_flat"], cfg["ramp_x"], cfg["tau"])

    gen_array(pulse_vals)  # print the values, do not store array
    # output to cic_bankx_in.dat, which is read by
    # both cic_bank (compiled from cic_bank.c) and cic_bankx_tb.
