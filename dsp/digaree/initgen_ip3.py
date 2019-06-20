#!/usr/bin/python
from sys import stderr

# These numbers are pasted from the first line of
# ~/llrf/theory/distort/sample.txt
s = "( 0.52761,-0.39069) \
     (-0.11932,-0.18239) \
     ( 0.00026,-0.00025) \
     (-0.00086,-0.00053) \
     (-0.01125, 0.00270) \
     (-0.01016, 0.00338) \
     ( 0.00008,-0.00002)"
ss = s.replace("(", "").split(")")
ss.pop()
conveyor = []
for cs in ss:
    cf = [float(q.strip()) for q in cs.split(",")]
    x = complex(cf[0], cf[1])
    conveyor.append(x)
s1 = conveyor[0]
s2 = conveyor[1]
sH = conveyor[2]
sL = conveyor[3]

# early debugging
if 0:
    a = s1*s1*2
    b = a*s2.conjugate()*2
    c = (abs(b)**2)*2
    d = (1/c)/4
    e = (1./b.conjugate())/8
    f = (sL/b)/8
    print("sL = %+8.5f%+8.5fj" % (sL.real, sL.imag))
    print("s1 = %+8.5f%+8.5fj" % (s1.real, s1.imag))
    print("s2 = %+8.5f%+8.5fj" % (s2.real, s2.imag))
    print("sH = %+8.5f%+8.5fj" % (sH.real, sH.imag))
    print("a  = %+8.5f%+8.5fj" % (a.real, a.imag))
    print("b  = %+8.5f%+8.5fj" % (b.real, b.imag))
    print("c  = %+8.5f" % c)
    print("d  = %+8.5f" % d)
    print("e  = %+8.5f%+8.5fj" % (e.real, e.imag))
    print("f  = %+8.5f%+8.5fj" % (f.real, f.imag))

# conveyor belt numbers destined for fscanf in user_tb.v and sim1.c

fs = 131072.0


def xprint(type, ix, x):
    xi = int(x*fs+0.5)
    if xi >= fs or xi < -fs:
        stderr.write("Overflow in setup: %.4f\n" % x)
        exit(1)
    print("%s %d %d" % (type, ix, xi))


# first the conveyor belt
for x in [sL, s1, s2, sH]:
    xprint("s", 0, x.real)
    xprint("s", 0, x.imag)

# then the configuration values written by the host
from numpy import pi, sin, cos
th = 36.0/47.0*2*pi

xprint("h", 0, -cos(th)/sin(th))  # K1
xprint("h", 1, 0.5/sin(th))  # K2
xprint("h", 2, 0.5)  # D
xprint("h", 3, 0.5)  # "two"
