import json
import os
import numpy
import subprocess
from numpy import exp, polyval, log, pi, unwrap, angle
from matplotlib import pyplot
from scipy import signal
error_cnt = 0
prog_rc = 0


def send(f, v, n):
    e = json_dict[n]
    base = e["base_addr"]
    for j, x in enumerate(v):
        f.write("%d %x\n" % (base+j, x))


# Scale a floating point number in range [-1,1) to fit in b-bit register
# Stolen from paramhg.py
def fix(x, b, msg, opt=None):
    global error_cnt
    ss = 1 << (b-1)
    # cordic_g = 1.646760258
    if opt == "cordic":
        ss = int(ss / 1.646760258)
    xx = int(x*ss+0.5)
    # print x,b,ss,xx
    if xx > ss-1:
        xx = ss-1
        print("error: %f too big (%s)" % (x, msg))
        error_cnt += 1
    if xx < -ss:
        xx = -ss
        print("error: %f too small (%s)" % (x, msg))
        error_cnt += 1
    if xx < 0:
        xx += 1 << b
    return xx


def polys(a, g):
    ar = a.real
    ai = a.imag
    fa = [1, -2*ar, abs(a)**2]
    fb = g.real*numpy.array([1, -ar]) + g.imag*numpy.array([0, -ai])
    b = polyval(fa, 1) / max(1-ar, abs(ai))
    fb = b*fb
    return fa, fb, b


def hardware1(a, g):
    fa, fb, b = polys(a, g)
    mx = max(1-a.real, abs(a.imag), b)
    scale = int(-log(mx)/log(4))
    scale = max(min(scale, 9), 2)
    print("scale %d" % scale)
    ar2 = 4**scale * (a.real-1)
    ai2 = 4**scale * (a.imag)
    br2 = 4**scale * b
    # convert to 18-bit fixed point
    ar3 = (fix(ar2, 18, "ar") & (2**18-1)) + ((9-scale) << 18)
    ai3 = (fix(ai2, 18, "ai") & (2**18-1)) + ((9-scale) << 18)
    br3 = fix(br2, 18, "br")
    bi3 = 0
    gr3 = fix(g.real, 18, "gr")
    gi3 = fix(-g.imag, 18, "gi")  # note conjugate
    return br3, bi3, ar3, ai3, gr3, gi3


def verilog_pipe(a, g):
    # note the hard-coded vvp that will ignore changes made in the Makefile
    hardware_file("afilter_siso_in.dat", a, g)
    cmd = ['vvp', '-n', 'afilter_siso_tb']
    return subprocess.Popen(cmd, stdout=subprocess.PIPE).stdout
    # os.system('make afilter_siso.dat')
    # return open("afilter_siso.dat", "r")


def time_plot(a, g, lab):
    fa, fb, b = polys(a, g)
    print('b =%9.6f' % b)
    print(numpy.roots(fa))
    print(numpy.roots(fb))
    dcgain = polyval(fb, 1) / polyval(fa, 1)
    print('DC gain %.5f' % dcgain)

    # Desired effect, fully analyzed and documented
    y1 = signal.lfilter(fb, fa, 800*[1.0])

    # Verilog version
    y3 = []
    with verilog_pipe(a, g) as result_file:
        for line in result_file.read().decode("utf-8").split('\n'):
            if "output" in line:
                y3 += [int(line.split()[2])/30000.0]
                # 30000 is drive level for u in afilter_siso_tb.v

    # Explicit state-space run
    ar = a.real
    ai = a.imag
    am = numpy.matrix([[ar, ai], [-ai, ar]])
    gm = numpy.matrix([g.real, g.imag])

    x = numpy.matrix([[0], [0]])
    u = numpy.matrix([[1], [0]])
    y2 = []
    for ix in range(15):
        x = am*x + b*u
        y2 += [(gm*x).item(0)]

    # All three columns should match
    e1 = 0
    e2 = 0
    npt = 15
    print(' direct     filter()   Verilog')
    for ix in range(npt):
        print('%9.6f  %9.6f  %9.6f' % (y2[ix], y1[ix], y3[ix+1]))
        e1 += (y2[ix] - y1[ix])**2
        e2 += (y2[ix] - y3[ix+1])**2
    if e1 < 1e-30*npt and e2 < 1e-8*npt:
        print("filte2.py: PASS")
    else:
        global prog_rc
        prog_rc = 1

    pyplot.plot(y1, label=lab)
    pyplot.xlabel('time step')
    pyplot.legend(frameon=False)


def freq_plot(a, g, lab):
    fa, fb, b = polys(a, g)
    f = 10**numpy.arange(-4, -0.30, 0.01)
    z = exp(+1j*2*pi*f)
    fgain = polyval(fb, z) / polyval(fa, z)
    pyplot.semilogx(f, log(abs(fgain)), label=lab+' ln mag')
    pyplot.semilogx(f, unwrap(angle(fgain)), label=lab+' angle')
    pyplot.xlim(1e-4, 0.5)
    pyplot.ylim(-6.5, 1.5)
    pyplot.legend(loc='lower left', frameon=False)
    pyplot.xlabel('Normalized frequency')


def hardware_file(fname, a, g):
    rbr, rbi, rar, rai, rgr, rgi = hardware1(a, g*0.99999)
    out_k = [rbr, rbi]
    res_k = [rar, rai]
    dot_k = [rgr, rgi]
    with open("afilter_siso_in.dat", "w") as reg_file:
        send(reg_file, out_k, "afilter_siso_outer_prod_k_out")
        send(reg_file, res_k, "afilter_siso_resonator_prop_const")
        send(reg_file, dot_k, "afilter_siso_dot_k_out")
    if error_cnt:
        print("error_cnt %d" % error_cnt)


if True:
    os.system("make afilter_siso_tb")
    with open("_autogen/regmap_afilter_siso_tb.json", "r") as json_file:
        json_dict = json.load(json_file)
a = exp(-0.005 + 0.03j)
glist = [[1, 'real g (bandpass)'], [-1j, 'imag g (lowpass)']]
for g, lab in glist:
    print('')
    print(lab)
    time_plot(a, g, lab)
pyplot.savefig('filt_time.pdf')
pyplot.figure(2)
print('')
for g, lab in glist:
    freq_plot(a, g, lab)
pyplot.savefig('filt_freq.pdf')
# pyplot.show()
exit(prog_rc)
