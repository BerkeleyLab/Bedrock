import numpy as np
from numpy import angle as ang
import sys

from matplotlib import pyplot as plt


def read(mag=True):
    A = np.loadtxt('cryomodule_p.dat')
    cav = A[:, 0] + 1j*A[:, 1]
    fwd = A[:, 2] + 1j*A[:, 3]
    rfl = A[:, 4] + 1j*A[:, 5]
    if mag:
        return abs(cav), abs(fwd), abs(rfl)
    else:
        return ang(cav), ang(fwd), ang(rfl)


def show(data):
    cav, fwd, rfl = data
    plt.plot(cav, label='cav')
    plt.plot(fwd, label='fwd')
    plt.plot(rfl, label='rfl')
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
    err_bar = 1
    print(cav[l], fwd[l], rfl[l])
    fail_pass(check_err(cav[l], 11, err_bar) and
              check_err(fwd[l], 20, err_bar) and
              check_err(rfl[l], 17, err_bar))


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='cryomodule')
    parser.add_argument('-c', '--check', action='store_true', default=True,
                        help='Purely run the check')
    parser.add_argument('-s', '--show', action='store_true',
                        help='Show plots first and then run the check')
    args = parser.parse_args()
    data = read(mag=True)
    if args.show:
        show(data)
        make_check(data)
    else:
        make_check(data)
