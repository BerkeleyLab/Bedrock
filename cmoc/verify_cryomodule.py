import numpy as np
from numpy import angle as ang
import sys

from matplotlib import pyplot as plt


def read():
    A = np.loadtxt('cryomodule_p.dat')
    cav = A[:, 0] + 1j*A[:, 1]
    fwd = A[:, 2] + 1j*A[:, 3]
    rfl = A[:, 4] + 1j*A[:, 5]
    return cav, fwd, rfl


def show(data, f_cvt=abs):
    cav, fwd, rfl = data
    plt.plot(f_cvt(cav), label='cav')
    plt.plot(f_cvt(fwd), label='fwd')
    plt.plot(f_cvt(rfl), label='rfl')
    plt.legend()
    plt.show()


def fail_pass(condition):
    if not condition:
        print('FAIL')
        sys.exit(1)
    else:
        print('PASS')


def check_err(test_val, bound, err):
    check = abs(test_val - bound) < err
    print(test_val, bound, err, check)
    return check


def make_check(data):
    cav, fwd, rfl = data
    l = len(cav) // 2
    err_bar = 5
    fail_pass(check_err(abs(cav[l]), 1934, err_bar) and
              check_err(abs(fwd[l]), 1318, err_bar) and
              check_err(abs(rfl[l]), 847, err_bar))


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='cryomodule')
    parser.add_argument('-c', '--check', action='store_true', default=True,
                        help='Purely run the check')
    parser.add_argument('-s', '--show', action='store_true',
                        help='Show plots first and then run the check')
    parser.add_argument('-p', '--phase', action='store_true',
                        help='Choose phase instead of default magnitude plot')
    args = parser.parse_args()
    data = read()
    if args.show:
        show(data, f_cvt=ang if args.phase else abs)
        make_check(data)
    else:
        make_check(data)
