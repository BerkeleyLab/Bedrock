import numpy as np
import sys

from matplotlib import pyplot as plt


def read():
    A = np.loadtxt('rtsim.dat')
    cav = abs(A[:, 0] + 1j*A[:, 1])
    fwd = abs(A[:, 2] + 1j*A[:, 3])
    rfl = abs(A[:, 4] + 1j*A[:, 5])
    return cav, fwd, rfl


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
    err_bar = 10
    fail_pass(check_err(cav[-1], 8739, err_bar) and
              check_err(fwd[-1], 6714, err_bar) and
              check_err(rfl[-1], 6022, err_bar))


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='rtsim')
    parser.add_argument('-c', '--check', action='store_true', default=True,
                        help='Purely run the check')
    parser.add_argument('-s', '--show', action='store_true',
                        help='Show plots')
    args = parser.parse_args()
    data = read()
    if args.show:
        make_check(data)
        show(data)
    else:
        make_check(data)
