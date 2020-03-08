from sys import argv
from numpy import pi, sin, cos, sqrt, arctan2
scale = 1.64676
sum_cos = 0
sum_sin = 0
n = 0
emax = 0
emin = 0
e2sum = 0
maxamp = 0
check_offset = False
if argv[1] == "bias":
    check_offset = True
    argv = argv[1:]
for ll in open(argv[1]).readlines():
    a = ll.split()
    if "xxx width" in ll:
        width = int(a[2])
        isc = 2**width
    if "x" in ll:
        continue
    ia = [int(x) for x in a]
    if n < (61*100+2) or not check_offset:
        if n >= 2:
            sum_cos += ia[3]
            sum_sin += ia[4]
        n += 1
    if check_offset:
        continue
    op = ia[6]
    if op == 0:
        aa = ia[0]*pi/isc
        xv = (ia[1]*cos(aa)-ia[2]*sin(aa))*scale
        yv = (ia[1]*sin(aa)+ia[2]*cos(aa))*scale
        e = ia[3]-xv
    elif op == 1:
        a2 = arctan2(ia[2], ia[1]) * isc/pi
        if a2 < 0:
            a2 = a2+2*isc
        e = ia[5] - a2
    elif op == 3:
        # assume ia[2] == 0
        gx = ia[1]*scale*cos(a2*3.1415926/isc)
        gy = ia[1]*scale*sin(a2*3.1415926/isc)
        # print gx,$4,gy,$5
        e = ia[3] - gx
    emax = max(e, emax)
    emin = min(e, emin)
    e2sum = e2sum + e*e
    if op == 0:
        e = ia[4]-yv
        emax = max(e, emax)
        emin = min(e, emin)
        e2sum += e*e
        n += 1
    elif op == 3:
        e = ia[4]-gy
        emax = max(e, emax)
        emin = min(e, emin)
        e2sum += e*e
        n += 1
    r = sqrt(ia[3]**2+ia[4]**2)
    maxamp = max(maxamp, r)

if check_offset:
    print("test covers %d points" % n)
    print("averages %.3f %.3f" % (float(sum_cos)/n, float(sum_sin)/n))
    mv = float(sum_cos*sum_cos + sum_sin*sum_sin)/(n*n)
    fail = mv > 0.001
else:
    print("test covers %d points, maximum amplitude is %d counts" % (n, maxamp))
    emax = max(emax, -emin)
    rms = sqrt(e2sum/n)
    fs = isc/2
    print("peak error %6.2f bits, %6.4f %%" % (emax, emax*100/fs))
    print("rms  error %6.2f bits, %6.4f %%" % (rms, rms*100/fs))
    fail = emax*100/fs > .035 or rms*100/fs > 0.005

if fail:
    print("FAIL")
    exit(1)
else:
    print("PASS")
