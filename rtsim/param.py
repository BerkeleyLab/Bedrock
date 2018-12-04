from math import pi, sqrt, log
from numpy import exp as cexp
from numpy import ceil

# http://stackoverflow.com/questions/14132789/python-relative-imports-for-the-billionth-time
# Leaves me with only one choice ... :(
# Since I don't want to modify shell variables
import os
import sys
sys.path.append(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))) +
    "/build-tools")

try:
    regmap_file = sys.argv[1].strip()
except Exception as e:
    regmap_file = "regmap_gen_vmod1.json"

# Gang humbly requests that Q_1 be renamed Q_drive, and Q_2 as Q_probe.
# Should apply here, physics.tex, elsewhere?

# Note that Tstep is the ADC time step, also clocks the LLRF controller.
# Divide by two for the cavity simulator (rtsim) clock time step.
Tstep = 14 / 1320e6  # s
f0 = 1300e6  # Hz
nyquist_sign = -1  # -1 represents frequency inversion,
# as with high-side LO or even-numbered Nyquist zones.

# beam_current = 0.3e-3  # Amp
beam_current = 0

VPmax = 48.0  # V piezo drive max

# as we scale up, the following 10 parameters replicate per cavity:
PAmax = 6e3  # W RF amplifier max
PAbw = 1.5e6  # Hz bandwidth of power amplifier
cav_adc_max = 1.2  # sqrt(W)
rfl_adc_max = 180.0  # sqrt(W)
fwd_adc_max = 160.0  # sqrt(W)
phase_1 = 0  # forward monitor phase shift
phase_2 = 0  # reflected monitor prompt phase shift
a_cav_offset = 10
a_rfl_offset = 20
a_for_offset = 30


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
# not run-time.  Top-level setting in vmod1_tb.v needs to be mirrored here.
lp_shift = 9  # see lp_pair.v, a.k.a. mode_shift
n_mech_modes = 7  # number of mechanical modes handled
df_scale = 9  # see cav_freq.v

# ==== end of system configuration

# Read registers from regmap_gen_vmod1
sim_base = 0  # base address for vmod1
from read_regmap import get_map, get_reg_info
regmap = get_map(regmap_file)
# ==== end of hardware register dictionaries

# scale a floating point number in range [-1,1) to fit in b-bit register
error_cnt = 0


def fix(x, b, msg, opt=None):
    global error_cnt
    ss = 2**(b - 1)
    # cordic_g = 1.646760258
    if opt is "cordic":
        ss = int(ss / 1.646760258)
    xx = int(x * ss + 0.5)
    # print x,b,ss,xx
    if xx > ss - 1:
        xx = ss - 1
        print("# error: %f too big (%s)" % (x, msg))
        error_cnt += 1
    if xx < -ss:
        xx = -ss
        print("# error: %f too small (%s)" % (x, msg))
        error_cnt += 1
    return xx


def set_reg(name, regmap):
    val = globals()[name]
    base_addr = regmap[name]
    if type(val) is list:
        for i, v in enumerate(val):
            print('{} {} # {}'.format(base_addr + i, v, name + " [" + str(i) +
                                      "]"))
    else:
        print('{} {} # {}'.format(base_addr, val, name))


# send a register value "out"
# looks address up in regmap[name]
# finds value via name in python global namespace
# value can be a scalar or a list
# prefix and name are used to give a helpful comment
def set_reg_old(offset, prefix, name, hierarchy):
    if name in globals():
        val = globals()[name]  # globals() or locals()?
    else:
        pre = hierarchy[0] + "_"
        if name.startswith(pre):
            sname = name.partition(pre)[2]
        else:
            return
        if sname in globals():
            val = globals()[sname]
        elif len(hierarchy) == 2:
            pre = hierarchy[1] + "_"
            if sname.startswith(pre):
                sname = name.partition(pre)[2]
            else:
                return
            if sname in globals():
                val = globals()[sname]
            else:
                # print "# Key not found: %s"%(name)
                return
        else:
            # print "# Key not found: %s"%(name)
            return
    addr = regmap[name]['base_addr']
    if type(val) is list:
        for i, v in enumerate(val):
            print('{} {} # {}'.format(addr + i, v, prefix + name + "[" + str(i) + "]"))
    else:
        print('{} {} # {}'.format(addr, val, prefix + name))


regmap_global = {
    'beam_phase_step':
    get_reg_info(regmap, [], "beam_phase_step")["base_addr"],
    'beam_modulo': get_reg_info(regmap, [], "beam_modulo")["base_addr"],
    'drive_couple_out_coupling':
    get_reg_info(regmap, [], "drive_couple_out_coupling")[
        "base_addr"],  # base address of 4 registers
    'amp_lp_bw': get_reg_info(regmap, [], "amp_lp_bw")["base_addr"],
    'a_cav_offset': get_reg_info(regmap, [], "a_cav_offset")["base_addr"],
    'a_rfl_offset': get_reg_info(regmap, [], "a_rfl_offset")["base_addr"],
    'a_for_offset': get_reg_info(regmap, [], "a_for_offset")["base_addr"],
    'resonator_prop_const':
    get_reg_info(regmap, [], "resonator_prop_const")["base_addr"],
    'cav_elec_modulo':
    get_reg_info(regmap, [], "cav_elec_modulo")["base_addr"],
    'cav_elec_phase_step':
    get_reg_info(regmap, [], "cav_elec_phase_step")["base_addr"],
    'cav_elec_dot_0_k_out':
    get_reg_info(regmap, ['', 0], ["dot", "k_out"])["base_addr"],
    'cav_elec_outer_prod_0_k_out':
    get_reg_info(regmap, ['', 0], ["outer", "k_out"])["base_addr"],
    'cav_elec_dot_1_k_out':
    get_reg_info(regmap, ['', 1], ["dot", "k_out"])["base_addr"],
    'cav_elec_outer_prod_1_k_out':
    get_reg_info(regmap, ['', 1], ["outer", "k_out"])["base_addr"],
    'cav_elec_dot_2_k_out':
    get_reg_info(regmap, ['', 2], ["dot", "k_out"])["base_addr"],
    'cav_elec_outer_prod_2_k_out':
    get_reg_info(regmap, ['', 2], ["outer", "k_out"])["base_addr"],
    'piezo_couple_k_out':
    get_reg_info(regmap, [''], "piezo_couple")["base_addr"],
    # 'noise_couple' : get_reg_info(regmap,[''],"noise_couple")["base_addr"]
}  # base address of 1024 registers

# ==== now start the application-specific computations

# Known not covered yet:
#   Beam coupling

omega0 = f0 * 2 * pi
mech_tstep = Tstep * n_mech_modes
interp_gain = n_mech_modes / 2**ceil(log(n_mech_modes) /
                                     log(2))  # cic_interp.v

print("# Globals")
beam_phase_step = 13  # beam.v
beam_modulo = -1320  # beam.v
amp_lp_bw = fix(Tstep * PAbw * 32, 18, "amp_lp_bw")

cav_elec_phase_step_h = int(dds_num * 2**20 / dds_den)
dds_mult = int(4096 / dds_den)
cav_elec_phase_step_l = (dds_num * 2**20) % dds_den * dds_mult
cav_elec_modulo = 4096 - dds_mult * dds_den
cav_elec_phase_step = cav_elec_phase_step_h << 12 | cav_elec_phase_step_l
print("# dds {} {} {} {}".format(dds_mult, cav_elec_phase_step_h,
                                 cav_elec_phase_step_l, cav_elec_modulo))

# four registers of pair_couple.v
# neglect losses between directional coupler and cavity
drive_couple_out_coupling = [
    fix(-sqrt(PAmax) / fwd_adc_max, 18, "out1", "cordic"),
    fix(-sqrt(PAmax) / rfl_adc_max, 18, "out2", "cordic"),
    fix(phase_1 / 180.0, 18, "out3"), fix(phase_2 / 180.0, 18, "out4")
]

# Mechanical modes
resonator_prop_const = []
piezo_couple_k_out = []
cav_elec_dot_0_k_out = []
cav_elec_outer_prod_0_k_out = []
cav_elec_dot_1_k_out = []
cav_elec_outer_prod_1_k_out = []
cav_elec_dot_2_k_out = []
cav_elec_outer_prod_2_k_out = []
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
    print("# debug {} {} {} {} {} {}".format(w1, a1, b1, scale, a2, b2))
    # c1 = -w1**2 / (k*b1)
    resonator_prop_const.append((fix(a2, 18, "a2") & (2**18 - 1)) + ((9 - scale
                                                                      ) << 18))
    resonator_prop_const.append((fix(b2, 18, "b2") & (2**18 - 1)) + ((9 - scale
                                                                      ) << 18))
    # the above is tested.  Onwards to the work-in-progress
    dc_gain = b2 / (a2**2 + b2**2)  # resonator.v
    print("# resonator mode DC gain %.4f" % dc_gain)
    net_coupling = 3.03e-8  # Hz / V^2, negative is implicit
    Amn = sqrt(net_coupling / mode1.RoverQ) / omega0  # sqrt(J)/V^2
    Cmn = -sqrt(net_coupling * mode1.RoverQ) * omega0  # 1/s/sqrt(J)
    outer = m.lorentz_en * Amn / mmode1.mx * mode1.peakV**2 / dc_gain  # dimensionless
    inner = m.lorentz_en * Cmn * mmode1.mx * Tstep / 2**df_scale / interp_gain  # dimensionless
    # note that inner*outer = net_coupling * mode1.peakV**2 * Tstep
    print("# outer = {} inner = {}".format(outer, inner))
    # Many factors of two identifiable in processing chain.  See scaling.txt.
    cav_elec_outer_prod_0_k_out.append(fix(outer * 512, 18, "outer"))
    cav_elec_outer_prod_0_k_out.append(0)
    cav_elec_dot_0_k_out.append(0)
    cav_elec_dot_0_k_out.append(fix(inner * 512, 18, "inner"))
    # Use second resonance to test piezo subsystem
    # The scaling is still non-quantitative
    piezo_couple_k_out.append(m.piezo_hack)
    piezo_couple_k_out.append(0)
    cav_elec_dot_2_k_out.append(0)
    cav_elec_dot_2_k_out.append(m.piezo_hack)

for n in regmap_global.keys():
    set_reg(n, regmap_global)

for i, m in enumerate([mode1]):
    print("# Cavity electrical mode %d: %s" % (i, m.name))
    Q_L = 1 / (1 / m.Q_0 + 1 / m.Q_1 + 1 / m.Q_2)
    # x is defined as sqrt(U)
    xmax = m.peakV / sqrt(m.RoverQ * omega0)
    # four registers of pair_couple.v
    out_couple = [
        fix(
            sqrt(omega0 / m.Q_1) * xmax / rfl_adc_max, 18, m.name + ".out1",
            "cordic"), fix(
                sqrt(omega0 / m.Q_2) * xmax / cav_adc_max, 18,
                m.name + ".out2", "cordic"),
        fix(m.phase_1 / 180.0, 18, m.name + "out3"),
        fix(m.phase_2 / 180.0, 18, m.name + "out4")
    ]
    # see Pro tip in eav4_elec.v for better limit on foffset
    # XXX document using 33 for what's really a 28-bit register
    coarse_freq = fix(Tstep * nyquist_sign * m.foffset, 33,
                      m.name + ".coarse_freq")
    V_achievable = 2 * sqrt(PAmax * m.Q_1 * m.RoverQ)
    drive_coupling = fix(V_achievable / m.peakV, 18,
                         m.name + ".drive_coupling", "cordic")
    # bandwidth in Hz = f_clk/2/2^shift/(2*pi) * bw_register/2^17 = omega_0/(2*pi*2*Q_L)
    # XXX document origin of *2.0 better, compensates for shift right in lp_pair.v
    bw = fix(Tstep * omega0 / (2 * Q_L) *
             (2**lp_shift) * 2.0, 18, m.name + ".bw")

    beam_cpl = beam_current * m.RoverQ * Q_L / m.peakV  # starting point
    beam_cpl = -beam_cpl * beam_modulo / beam_phase_step**2
    # compensate for hard-coded binary scaling in cav_mode.v:
    #   beam_mag = beam_mag_wide[21:4];
    #   drive2 <= {beam_drv,6'b0};
    beam_coupling = fix(beam_cpl / 16, 18, m.name + ".beam_coupling", "cordic")
    regmap_emode = {
        'coarse_freq':
        get_reg_info(regmap, ['', i], "coarse_freq")["base_addr"],
        'drive_coupling':
        get_reg_info(regmap, ['', i], "drive_coupling")["base_addr"],
        'bw': get_reg_info(regmap, ['', i], "bw")["base_addr"],
        'out_couple':
        get_reg_info(regmap, ['', i], "out_coupling")["base_addr"],
        'beam_coupling':
        get_reg_info(regmap, ['', i], "beam_coupling")["base_addr"]
    }  # base address of 4 registers
    for n in regmap_emode:
        set_reg(n, regmap_emode)
    # keys = filter(lambda x: x.startswith("cav_elec_mode_"+str(i)), regmap.keys())
    # for n in keys:
    #   set_reg(m.name+".",n,["cav_elec", "mode_"+str(i)])
    # keys = filter(lambda x: x.startswith("cav_elec_freq_"+str(i)), regmap.keys())
    # for n in keys:
    #   set_reg(8*i,m.name+".",n,["cav_elec", "freq_"+str(i)])

    # Pseudo-random generator initialization, see tt800v.v and prng.v
prng_seed = "pushmi-pullyu"
prng_seed = None


def push_seed(addr, hf):
    for jx in range(25):
        mm = hf.digest()
        s = 0
        for ix in range(4):
            s = s * 256 + ord(mm[ix])
        print("%d %u" % (addr, s))
        hf.update(chr(jx))


if prng_seed is not None:
    from hashlib import sha1
    print("# PRNG subsystem seed is '%s'" % prng_seed)
    hf = sha1()
    hf.update(prng_seed)
    push_seed(53 + sim_base, hf)
    push_seed(54 + sim_base, hf)
    print("%d 1  # turn on PRNG" % (52 + sim_base))

if error_cnt > 0:
    print("# %d scaling errors found" % error_cnt)
    exit(1)
