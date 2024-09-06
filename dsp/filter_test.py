import numpy as np
import matplotlib.pyplot as plt
from subprocess import call
import sys


def vvp_run(tb, args, ofile, verbose=False):
    cmd = 'vvp -N %s ' % tb
    cmd += args
    if verbose:
        print(cmd)
    rc = call(cmd, shell=True)
    if rc != 0:
        print("vvp return_code %d" % rc)
        print("FAIL")
        exit(1)
    return np.loadtxt(ofile)


# dt in seconds, frequencies in Hz
fwashout_tb = {"tb": "fwashout_tb",
               "ofile": "fwashout.dat",
               "dt": 10e-9,
               "fstart": 1e4,
               "fstop": 1e7,
               "fcorner": 1e6,
               "slope": 20}  # dB/dec

lpass1_tb = {"tb": "lpass1_tb",
             "ofile": "lpass1.dat",
             "dt": 10e-9,
             "fstart": 1e4,
             "fstop": 1e7,
             "fcorner": 1e5,
             "slope": -20}

TB_LIST = {"fwashout_tb": fwashout_tb, "lpass1_tb": lpass1_tb}


def run_and_parse(tb_cfg, verbose=False):
    tb = tb_cfg["tb"]
    of = tb_cfg["ofile"]
    dt = tb_cfg["dt"]
    fstart = tb_cfg["fstart"]
    fstop = tb_cfg["fstop"]

    fsweep = np.logspace(np.log10(fstart), np.log10(fstop), num=20)
    psweep = dt*fsweep

    gain_arr = []
    ph_arr = []
    for p in psweep:
        # Set simulation time so it includes 3 periods
        stime = np.ceil(3/p)
        a = vvp_run(tb, "+phstep=%f +simtime=%d +trace" % (p, stime), of, verbose)
        npts = a.shape[0]
        trans = int(npts - npts/3)
        a_in = a[trans:, 0]  # Ignore transient
        a_out = a[trans:, 1]
        gain_est1 = max(a_out)/max(a_in)

        # Estimate phase shift based on dot-product
        dp = np.dot(a_in, a_out)
        norm = np.linalg.norm(a_in)*np.linalg.norm(a_out)
        phas_est1 = np.arccos(dp/norm)*180.0/np.pi

        # assume sine waves
        n_out = len(a_in)
        ref = np.exp(p*2*np.pi*1j*np.arange(n_out))
        cpx_in = np.mean(np.dot(a_in, ref.conj()))
        cpx_out = np.mean(np.dot(a_out, ref.conj()))
        cpx_gain = cpx_out / cpx_in
        gain_est2 = abs(cpx_gain)
        phas_est2 = np.angle(cpx_gain)*180.0/np.pi

        if verbose:
            print("%8.5f %8.5f  %8.3f %8.3f" % (gain_est1, gain_est2, phas_est1, phas_est2))
        gain_arr.append(gain_est2)
        ph_arr.append(phas_est2)

    return fsweep, gain_arr, ph_arr


def check_tf(freq, gain, phase, tb_cfg, plot=False):
    f = freq
    g = 20*np.log10(gain)
    p = phase
    lowpass = True if g[0] > -3.0 else False

    # 3 dB corner
    c = np.argmax(g < -3.0) if lowpass else np.argmax(g > -3.0)
    c_est = (freq[c] + freq[c-1])/2
    print("3dB corner estimate: %.1f Hz" % c_est)
    # Approximate slope before/after corner
    delta = 2
    if lowpass:
        gs = g[c+delta:]
        fs = f[c+delta:]
    else:
        gs = g[0:c-delta]
        fs = f[0:c-delta]
    slope = (gs[-1] - gs[0])/(np.log10(fs[-1]) - np.log10(fs[0]))
    print("Estimated slope before/after 3dB corner: %.3f dB/dec" % slope)

    if plot:
        plt.subplot(211)
        plt.semilogx(f, g, "-x")
        plt.semilogx(f, -3.0*np.ones(len(g)))
        plt.ylabel("Gain [dB]")
        plt.subplot(212)
        plt.semilogx(f, p, "-x")
        plt.ylabel("Phase [deg]")
        plt.xlabel("Frequency [Hz]")
        plt.show()

    # Pass/Fail based on TB settings
    fail = False
    fmeas = c_est
    fspec = tb_cfg["fcorner"]
    diff = (np.log10(fmeas) - np.log10(fspec))/np.log10(fspec)
    if abs(diff) > 0.1:
        print("FAIL: Measured 3dB corner (%.1f) too far from spec (%.1f)!" % (fmeas, fspec))
        fail = True
    sspec = tb_cfg["slope"]
    diff = (slope - sspec)/sspec
    if abs(diff) > 0.1:
        print("FAIL: Measured slope (%.3f) too far from spec (%.3f)!" % (slope, sspec))
        fail = True

    if fail:
        print("FAIL: Did not meet spec")
        return -1
    else:
        print("PASS")
        return 0


if len(sys.argv) < 2:
    print("Usage: %s <TB name> [plot]" % sys.argv[0])
    exit(-1)

tb_name = sys.argv[1]
plot = False
if len(sys.argv) > 2:
    plot = True if sys.argv[2] == "plot" else False

if tb_name not in TB_LIST.keys():
    print("TB not recognized: ", tb_name)
    exit(-1)

tb = TB_LIST[tb_name]

f, g, p = run_and_parse(tb, verbose=False)
rc = check_tf(f, g, p, tb, plot)
exit(rc)
