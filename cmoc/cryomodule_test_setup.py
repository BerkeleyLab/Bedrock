import os
import sys
from math import pi, sqrt, log
from numpy import exp as cexp
from numpy import ceil
# http://stackoverflow.com/questions/14132789/python-relative-imports-for-the-billionth-time
# Leaves me with only one choice ... :(
# Since I don't want to modify shell variables
sys.path.append(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))) +
    "/submodules/build")
from read_regmap import get_map, get_reg_info

cav_num = 0

regmap_cryomodule = get_map("./_autogen/regmap_cryomodule.json")

# Note that Tstep is the ADC time step, also clocks the LLRF controller.
# Divide by two for the cavity simulator (rtsim) clock time step.
Tstep = 10e-9  # s
f0 = 1300e6  # Hz
nyquist_sign = -1  # -1 represents frequency inversion,
# as with high-side LO or even-numbered Nyquist zones.

VPmax = 48.0  # V piezo drive max

# as we scale up, the following 10 parameters replicate per cavity:
PAmax = 6e3  # W RF amplifier max
PAbw = 1.5e6  # Hz bandwidth of power amplifier
cav_adc_max = 1.2  # sqrt(W)
rfl_adc_max = 180.0  # sqrt(W)
fwd_adc_max = 160.0  # sqrt(W)
phase_1 = 0  # forward monitor phase shift
phase_2 = 0  # reflected monitor prompt phase shift
cav_adc_off = 10
rfl_adc_off = 30
fwd_adc_off = 20


class Emode:
    """Cavity electrical mode"""

    def __init__(self, name):
        self.name = name


mode1 = Emode("pi")
mode1.RoverQ = 1036.0  # Ohm
mode1.foffset = 5.0  # Hz
mode1.peakV = 1.5e6  # V
mode1.Q_0 = 1e10  # internal loss
mode1.Q_1 = 8.1e4  # drive coupler (should be 4e7, maybe 8e4 for testing?)
mode1.Q_2 = 2e9  # field probe
mode1.phase_1 = 0
mode1.phase_2 = 0

mode2 = Emode("8pi/9")
mode2.RoverQ = 10.0  # Ohm
mode2.foffset = -8e5  # Hz
mode2.peakV = 0.15e6  # V
mode2.Q_0 = 1e10  # internal loss
mode2.Q_1 = 8.1e4  # drive coupler
mode2.Q_2 = 2e9  # field probe
mode2.phase_1 = 10.0
mode2.phase_2 = -180.0


class Mmode:
    """Cavity mechanical mode"""

    def __init__(self, name):
        self.name = name


# This mode is silly, but lets the frequency change on the time scale of
# software simulation = 40 us
mmode1 = Mmode("silly")
mmode1.freq = 30000  # Hz
mmode1.Q = 5.0  # unitless
mmode1.mx = 1.13  # sqrt(J)  full-scale for resonator.v state
mmode1.piezo_hack = 0
mmode1.lorentz_en = 1

mmode2 = Mmode("piezo")
mmode2.freq = 100000  # Hz
mmode2.Q = 5.0  # unitless
mmode2.mx = 0  # disable
mmode2.piezo_hack = 80000
mmode2.lorentz_en = 0

# DDS setup for simulator should be static
# this construction is for 20 MHz / 94.286 MHz = 7/33
dds_num = 7
dds_den = 33

# The following three parameters are set in the Verilog at compile-time,
# not run-time.  Top-level setting in larger.v needs to be mirrored here.
lp_shift = 9  # see lp_pair.v, a.k.a. mode_shift
n_mech_modes = 7  # number of mechanical modes handled
df_scale = 9  # see cav_freq.v

# ==== end of system configuration

# ==== the following dictionaries should get pulled in from Verilog somehow
regmap_global = {
    'dds_phstep':
    get_reg_info(regmap_cryomodule, [cav_num],
                 "cav_elec_phase_step")["base_addr"],
    'dds_modulo':
    get_reg_info(regmap_cryomodule, [cav_num], "cav_elec_modulo")["base_addr"],
    'amp_bw':
    get_reg_info(regmap_cryomodule, [cav_num], "amp_lp_bw")["base_addr"],
    'prompt':
    get_reg_info(regmap_cryomodule, [cav_num], "drive_couple_out_coupling")[
        "base_addr"],  # base address of 4 registers
    'cav_adc_off':
    get_reg_info(regmap_cryomodule, [cav_num], "a_cav_offset")["base_addr"],
    'rfl_adc_off':
    get_reg_info(regmap_cryomodule, [cav_num], "a_rfl_offset")["base_addr"],
    'fwd_adc_off':
    get_reg_info(regmap_cryomodule, [cav_num], "a_for_offset")["base_addr"],
    'res_prop':
    get_reg_info(regmap_cryomodule, [cav_num],
                 "resonator_prop_const")["base_addr"],
    'dot_0_k':
    get_reg_info(regmap_cryomodule, [cav_num], "dot_0_k_out")["base_addr"],
    'outer_0_k':
    get_reg_info(regmap_cryomodule, [cav_num],
                 "outer_prod_0_k_out")["base_addr"],
    'dot_1_k':
    get_reg_info(regmap_cryomodule, [cav_num], "dot_1_k_out")["base_addr"],
    'outer_1_k':
    get_reg_info(regmap_cryomodule, [cav_num],
                 "outer_prod_1_k_out")["base_addr"],
    'dot_2_k':
    get_reg_info(regmap_cryomodule, [cav_num], "dot_2_k_out")["base_addr"],
    'outer_2_k':
    get_reg_info(regmap_cryomodule, [cav_num],
                 "outer_prod_2_k_out")["base_addr"],
    'piezo_couple':
    get_reg_info(regmap_cryomodule, [cav_num], "piezo_couple")["base_addr"],
    #  'noise_couple' : get_reg_info(regmap_cryomodule,[''],"noise_couple")["base_addr"]
}  # base address of 1024 registers

# ==== end of hardware register dictionaries

# scale a floating point number in range [-1,1) to fit in b-bit register
error_cnt = 0


def fix(x, b, msg, opt=None):
    global error_cnt
    ss = 2**(b - 1)
    # cordic_g = 1.646760258
    if (opt is "cordic"):
        ss = int(ss / 1.646760258)
    xx = int(x * ss + 0.5)
    # print x,b,ss,xx
    if (xx > ss - 1):
        xx = ss - 1
        print("# error: %f too big (%s)" % (x, msg))
        error_cnt += 1
    if (xx < -ss):
        xx = -ss
        print("# error: %f too small (%s)" % (x, msg))
        error_cnt += 1
    return xx


# send a register value "out"
# looks address up in regmap[name]
# finds value via name in python global namespace
# value can be a scalar or a list
# prefix and name are used to give a helpful comment
def set_reg(offset, prefix, name, regmap):
    val = globals()[name]  # globals() or locals()?
    if (type(val) is list):
        for i, v in enumerate(val):
            print(offset + regmap[name] + i, v, "#",
                  prefix + name + "[" + str(i) + "]")
    else:
        print(offset + regmap[name], val, "#", prefix + name)


# ==== now start the application-specific computations

# Still may have bugs:
#   Mechanical mode coupling
# Needs a lot of work:
#   LLRF controller

omega0 = f0 * 2 * pi
mech_tstep = Tstep * n_mech_modes
interp_gain = n_mech_modes / 2**ceil(log(n_mech_modes) / log(2))  # interp0.v

print("# Globals")
amp_bw = fix(Tstep * PAbw * 32, 18, "amp_bw")

dds_phstep_h = int(dds_num * 2**20 / dds_den)
dds_mult = int(4096 / dds_den)
dds_phstep_l = (dds_num * 2**20) % dds_den * dds_mult
dds_modulo = 4096 - dds_mult * dds_den
dds_phstep = dds_phstep_h << 12 | dds_phstep_l
print("# dds", dds_mult, dds_phstep_h, dds_phstep_l, dds_modulo)

# four registers of pair_couple.v
# neglect losses between directional coupler and cavity
prompt = [
    fix(-sqrt(PAmax) / fwd_adc_max, 18, "out1", "cordic"),
    fix(-sqrt(PAmax) / rfl_adc_max, 18, "out2", "cordic"),
    fix(phase_1 / 180.0, 19, "out3"),
    fix(phase_2 / 180.0, 19, "out4")
]

# Mechanical modes
res_prop = []
piezo_couple = []
dot_0_k = []
outer_0_k = []
dot_1_k = []
outer_1_k = []
dot_2_k = []
outer_2_k = []
for i, m in enumerate([mmode1, mmode2]):
    print("# Cavity mechanical mode %d: %s" % (i, m.name))
    w1 = mech_tstep * 2 * pi * m.freq
    # a1 + b1 * i represents the pole in the normalized s-plane
    a1 = w1 * (-1 / (2.0 * m.Q))
    b1 = w1 * sqrt(1 - 1 / (4.0 * m.Q**2))
    z_pole = cexp(a1 + b1 * 1j)
    print("# z_pole = %7f + %7fi" % (z_pole.real, z_pole.imag))
    a1 = z_pole.real - 1.0
    b1 = z_pole.imag
    scale = int(-log(max(a1, b1)) / log(4))
    scale = max(min(scale, 9), 2)
    a2 = a1 * 4**scale
    b2 = b1 * 4**scale
    print("# debug", w1, a1, b1, scale, a2, b2)
    # c1 = -w1**2 / (k*b1)
    res_prop.append((fix(a2, 18, "a2") & (2**18 - 1)) + ((9 - scale) << 18))
    res_prop.append((fix(b2, 18, "b2") & (2**18 - 1)) + ((9 - scale) << 18))
    # the above is tested.  Onwards to the work-in-progress
    dc_gain = b2 / (a2**2 + b2**2)  # resonator.v
    net_coupling = 130.0  # Hz / V^2, negative is implicit
    Amn = sqrt(net_coupling / mode1.RoverQ) / omega0  # sqrt(J)/V^2
    Cmn = -sqrt(net_coupling * mode1.RoverQ) * omega0  # 1/s/sqrt(J)
    outer = m.lorentz_en * Amn / mmode1.mx * mode1.peakV**2 / dc_gain  # dimensionless
    inner = m.lorentz_en * Cmn * mmode1.mx * Tstep / 2**df_scale / interp_gain  # dimensionless
    # note that inner*outer = net_coupling * mode1.peakV**2 * Tstep
    print("# outer =", outer, "inner =", inner)
    # additional scaling below comes from the 32-bit mech_phase_fine
    # accumulator, but only 18-bit d_result
    outer_0_k.append(fix(outer / 128, 18, "outer"))
    outer_0_k.append(0)
    dot_0_k.append(0)
    dot_0_k.append(fix(inner / 128, 18, "inner"))
    # Use second resonance to test piezo subsystem
    # The scaling is still non-quantitative
    piezo_couple.append(m.piezo_hack)
    piezo_couple.append(0)
    dot_2_k.append(0)
    dot_2_k.append(m.piezo_hack)

for n in regmap_global:
    set_reg(0, "", n, regmap_global)

for i, m in enumerate([mode1, mode2]):
    print("# Cavity electrical mode %d: %s" % (i, m.name))
    Q_L = 1 / (1 / m.Q_0 + 1 / m.Q_1 + 1 / m.Q_2)
    # x is defined as sqrt(U)
    xmax = m.peakV / sqrt(m.RoverQ * omega0)
    # four registers of pair_couple.v
    out_couple = [
        fix(
            sqrt(omega0 / m.Q_1) * xmax / rfl_adc_max, 18, m.name + ".out1",
            "cordic"),
        fix(
            sqrt(omega0 / m.Q_2) * xmax / cav_adc_max, 18, m.name + ".out2",
            "cordic"),
        fix(m.phase_1 / 180.0, 19, m.name + "out3"),
        fix(m.phase_2 / 180.0, 19, m.name + "out4")
    ]
    # see Pro tip in eav4_elec.v for better limit on foffset
    # XXX document using 33 for what's really a 28-bit register
    coarse_freq = fix(Tstep * nyquist_sign * m.foffset, 33,
                      m.name + "coarse_freq")
    V_achievable = 2 * sqrt(PAmax * m.Q_1 * m.RoverQ)
    drive_coupling = fix(V_achievable / m.peakV, 18, m.name + "drive_coupling",
                         "cordic")
    # bandwidth in Hz = f_clk/2/2^shift/(2*pi) * bw_register/2^17 = omega_0/(2*pi*2*Q_L)
    # XXX document origin of *2.0 better, compensates for shift right in lp_pair.v
    bw = fix(Tstep * omega0 / (2 * Q_L) * (2**lp_shift) * 2.0, 18,
             m.name + ".bw")
    regmap_emode = {
        'coarse_freq':
        get_reg_info(regmap_cryomodule, [cav_num, i],
                     "coarse_freq")["base_addr"],
        'drive_coupling':
        get_reg_info(regmap_cryomodule, [cav_num, i],
                     "drive_coupling")["base_addr"],
        'bw':
        get_reg_info(regmap_cryomodule, [cav_num, i], "bw")["base_addr"],
        'out_couple':
        get_reg_info(regmap_cryomodule, [cav_num, i],
                     "out_couple_out_coupling")["base_addr"]
    }  # base address of 4 registers
    for n in regmap_emode:
        set_reg(0, m.name + ".", n, regmap_emode)

# Pseudo-random generator initialization, see tt800v.v and prng.v
prng_seed = b"pushmi-pullyu"


def push_seed(addr, hf):
    for jx in range(25):
        mm = hf.digest()
        s = 0
        for ix in range(4):
            s = s * 256 + mm[ix]
        print("%d %u" % (addr, s))
        hf.update(chr(jx).encode('utf-8'))


if (prng_seed is not None):
    from hashlib import sha1
    print("# PRNG subsystem seed is '%s'" % prng_seed)
    hf = sha1()
    hf.update(prng_seed)
    push_seed(
        get_reg_info(regmap_cryomodule, [cav_num], "prng_iva")["base_addr"],
        hf)
    push_seed(
        get_reg_info(regmap_cryomodule, [cav_num], "prng_ivb")["base_addr"],
        hf)
    print("%d 1  # turn on PRNG" % (get_reg_info(
        regmap_cryomodule, [cav_num], "prng_random_run")["base_addr"]))
    # push_seed(get_reg_info(regmap_cryomodule,[],"cav_mech_prng_iva")["base_addr"],hf)
    # push_seed(get_reg_info(regmap_cryomodule,[],"cav_mech_prng_ivb")["base_addr"],hf)
    # print("%d 1  # turn on PRNG"%(get_reg_info(regmap_cryomodule,[],"cav_mech_prng_random_run")["base_addr"]))


def set_ctl(addr, n, v):
    print("%s %d  # %s" % (addr, v, n))


def get_ctl_reg_and_set(name, value):
    addr = get_reg_info(regmap_cryomodule, [0], name)['base_addr']
    set_ctl(addr, name, value)

get_ctl_reg_and_set('bank_next', 1)
get_ctl_reg_and_set('bank_next', 0)

get_ctl_reg_and_set('controller_phase_step', dds_phstep)
get_ctl_reg_and_set('controller_modulo', dds_modulo)

wave_samp_per = 1
wave_shift = 3
# The LO amplitude in the FPGA is scaled by (32/33)^2, so that yscale
# fits nicely within the 32768 limit for small values of wave_samp_per
lo_cheat = (32 / 33.0)**2
yscale = lo_cheat * (33 * wave_samp_per)**2 * 4**(8 - wave_shift) / 32

get_ctl_reg_and_set('wave_samp_per', wave_samp_per)
get_ctl_reg_and_set('wave_shift', wave_shift)
get_ctl_reg_and_set('sel_thresh', 5000)
# set_ctl(addr, "ph_offset", -35800)
# A change to offset the DDS phase, and match the signals between
# cryomodule_tb and larger_tb
# get_ctl_reg_and_set('ph_offset', -150800)
get_ctl_reg_and_set('ph_offset', -35800)
get_ctl_reg_and_set('sel_en', 1)
get_ctl_reg_and_set('lp1a_kx', 20486)
get_ctl_reg_and_set('lp1a_ky', -20486)

# print "555 150  # wait for 150 cycles to pass"
get_ctl_reg_and_set('chan_keep', 4080)
addr = get_reg_info(regmap_cryomodule, [0], 'lim')['base_addr']

global delay_pc
delay_pc = get_reg_info(regmap_cryomodule, [0], 'XXX')['base_addr']


def delay_set(ticks, addr, data):
    global delay_pc
    delay_pc += 4
    print("%d %d # duration" % (delay_pc - 4, ticks))
    print("%d %d # dest addr (%s)" % (delay_pc - 3, addr, addr))
    print("%d %d # value_msb" % (delay_pc - 2, int(data) / 65536))
    print("%d %d # value_lsb" % (delay_pc - 1, int(data) % 65536))


if 0:  # FGEN
    print("3 300    # duration")
    print("4 5000   # amp_slope")
    print("7 22640  # amp_max")
    print("555 7600 # wait")
    print("10 36    # amp dest address (lim X hi)")
    print("12 38    # amp dest address (lim X lo)")
else:  # TGEN
    delay_set(0, addr, 22640)
    delay_set(6000, addr + 2, 22640)
    delay_set(0, addr, 0)
    delay_set(0, addr + 2, 0)

get_ctl_reg_and_set('bank_next', 1)

# TODO HACK:
# Since the sole purpose of this file is to feed cryomodule_tb
print("555 600    # Add delay of 600 cycles")
# print("14336 1    # Flip the circle buffer")
# print("14337 1    # Flip the circle buffer")
print("%d 1    # Flip the circle buffer" % (0x13800))
print("%d 1    # Flip the circle buffer" % (0x13801))

if (error_cnt > 0):
    print("# %d scaling errors found" % error_cnt)
    exit(1)
