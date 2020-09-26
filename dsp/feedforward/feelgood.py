from matplotlib import pyplot
import numpy as np
from sys import argv
import json
from simple import quad_setup

d = np.loadtxt(argv[1]).transpose()
ddrive = d[0]
drive = d[1]
cav = d[2]
t = np.arange(len(cav))  # not real

with open(argv[2]) as f:
    setup = json.load(f)
    dt = setup["dt"] / setup["tau"]
    sim_expand = setup["sim_expand"]
    t_fill = setup["t_fill"]
    t_flat = setup["t_flat"]
    d_amp = setup["d_amp"]
    ramp_x = setup["ramp_x"]
    couple = setup["couple"]
    #
    kc0, equilib = quad_setup(t_fill)
    slp = 2*kc0/equilib*t_fill
    t_ramp = -1.0/slp
    c_amp = d_amp * couple

t_fill = t_fill / ramp_x
lead_edge = 4  # hard-coded in cic_bank_memgen.py
t1 = sim_expand * (lead_edge + (t_fill + 0.05 * t_flat) / dt)
t2 = sim_expand * (lead_edge + (t_fill + 0.95 * t_flat) / dt)
t3 = sim_expand * (lead_edge + (t_fill + 1.05 * t_flat + t_ramp) / dt)
t4 = t3 + 50
# print(t1, t2, t3, t4)

jk = np.nonzero((t > t1) * (t < t2))
pp = np.polyfit(t[jk], drive[jk], 1)
fail = abs(pp[0]) > 0.3
fail = fail or abs(pp[1]-d_amp) > 50
print("drive flat-top", pp)

pp = np.polyfit(t[jk], cav[jk], 1)
fail = fail or abs(pp[0]) > 0.9
fail = fail or abs(pp[1]-c_amp) > 150
print("cavity flat-top", pp)

jk = np.nonzero((t > t3) * (t < t4))
pp = np.polyfit(t[jk], drive[jk], 1)
print("drive post-pulse", pp)

pp = np.polyfit(t[jk], np.log(cav[jk]), 1)
print("log cav post-pulse", pp)

# Integrate drive delta and compare with drive
ddrive_int = np.cumsum(ddrive, dtype=int)

# Scale adjustment of integrated drive, as
# documented in cic_bankx.v and ff_driver.v
ddrive_int = ddrive_int/sim_expand

rms = np.sqrt(np.mean((drive-ddrive)**2))
print("int(delta_drive) to drive RMS:", rms)

pyplot.plot(t, drive, label='drive')
pyplot.plot(t, ddrive_int, label='int(ddrive)')
pyplot.plot(t, cav, label='cavity')
pyplot.legend(frameon=False)
pyplot.savefig("feelgood.png")
# pyplot.show()

if fail:
    exit(1)
else:
    print("PASS")
