import numpy as np
import matplotlib.pyplot as plt
from subprocess import call


def vvp_run(tb, args, ofile, verbose=True):
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
               "fstart": 1e3,
               "fstop": 1e7}


def run_and_parse(tb_cfg):
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
        a = vvp_run(tb, "+phstep=%f +simtime=%d +trace" % (p, stime), of)
        npts = a.shape[0]
        trans = int(npts - npts/3)
        a_in = a[trans:, 0]  # Ignore transient
        a_out = a[trans:, 1]
        gain_arr.append(max(a_out)/max(a_in))

        # Estimate phase shift based on dot-product
        dp = np.dot(a_in, a_out)
        norm = np.linalg.norm(a_in)*np.linalg.norm(a_out)
        print(dp/norm, np.arccos(dp/norm))
        ph_arr.append(np.arccos(dp/norm)*180.0/np.pi)

    return fsweep, gain_arr, ph_arr


f, g, p = run_and_parse(fwashout_tb)

plot = True
if plot:
    plt.subplot(211)
    plt.semilogx(f, 20*np.log10(g), "-x")
    plt.semilogx(f, -3.0*np.ones(len(g)))
    plt.ylabel("Gain [dB]")
    plt.subplot(212)
    plt.semilogx(f, p, "-x")
    plt.ylabel("Phase [deg]")
    plt.xlabel("Frequency [Hz]")
    plt.show()
