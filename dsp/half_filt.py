import argparse
import numpy
from numpy import sqrt, mean


def make_check():
    y = numpy.loadtxt("half_filt.dat")
    npt = len(y)
    print('read %d points, expected 245' % npt)
    ix = numpy.arange(npt)
    s = numpy.sin((ix+3.0)*.0081*2*16)
    lf1 = numpy.polyfit(s, y, 1)
    oamp = abs(lf1[0])
    print('actual amplitude %8.1f, expected about 200000' % oamp)
    erry = y-lf1[0]*s
    err = numpy.std(erry, ddof=1)
    print('DC offset     %.4f bits, expected about 0' % mean(erry))

    nom_err = sqrt(1.0**2+1/12)*0.66787
    tst_err = sqrt(nom_err**2 + 0.3**2)
    print('std deviation %.4f bits, expected about %.4f' % (err, nom_err))
    print('excess noise  %.4f bits' % sqrt(err**2-nom_err**2))
    if (npt > 230 and
        oamp > 199800 and
        oamp < 200000 and
        abs(mean(erry)) < 0.01 and
            err < tst_err):
        print("PASS")
    else:
        print("FAIL")
        exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Test half_filt')
    parser.add_argument('-c', '--check', action='store_true', default=True,
                        help='Purely run the check')
    args = parser.parse_args()
    make_check()
