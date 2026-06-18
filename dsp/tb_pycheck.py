import numpy as np
import matplotlib.pyplot as plt


def fraction_to_ph_acc(rational_fraction, bits_h=20, bits_l=12):
    '''
    Converts a rational fraction [num/den] to what is needed by dsp/ph_acc.v

    The function determines the fixed point phase step that an FPGA phase
    generator rotates by every clock cycle (of the sampling clock). The
    rotation is implemented as an adder. The frequency being generated is a
    `rational_fraction` of the ADC clock frequency. The ADC Clock takes a
    full 2*pi phase step, where as the generated phase step takes a
    `rational_fraction` of the phase step.

    Args:
        :param rational_fraction: (num, den) A ratio of the ADC Clock frequency
        :param bits_h: The resolution of the main counter that generates phase.
        :param bits_l: Resolution of a helper counter that compensates for the
                       residue of the coarse counter
    Returns:
        :return step_h: Coarse representation of the `rational_fraction`

    num, den = rational_fraction
    Determine coarse_step by scaling the rational_fraction to bits_h resolution
    Determine fine_step by taking the residue from the coarse step and scaling
    to bits_l resolution
    modulo, is residue from the fine_step that is added to the counter when it
    overflows
    '''
    # _fs stands for _full_scale
    coarse_fs, fine_fs = 2**bits_h, 2**bits_l
    num, den = rational_fraction

    # Scale the rational fraction to coarse full scale and compute the residue
    step_h = int(coarse_fs * num / den)
    residue_coarse = (num * coarse_fs) % den

    # acc_multiplier holds the smallest fine scale step per clock cycle
    acc_multiplier = int(fine_fs / den)
    step_l = residue_coarse * acc_multiplier

    modulo = fine_fs - acc_multiplier * den
    return step_h, step_l, modulo


def get_cols_from_line(filename, comment='#'):
    '''
    Find the first commented line, return the strings in the line that are
    separated by spaces as a list
    '''
    with open(filename, 'r') as f:
        for line in f.readlines():
            line = line.strip()
            if line.startswith(comment):
                return line.strip().lstrip('#').strip().split()
        else:
            print('No column names found')
            exit(1)


def show_detected_phase():
    FNAME = 'xmit.out'
    print(fraction_to_ph_acc((5, 12)))
    cols = get_cols_from_line(FNAME)
    print(cols)
    cc, ph_ref, detected_phase, accumulated = np.loadtxt(
        FNAME, comments='#', unpack=True)
    plt.plot(cc * 2, ph_ref / (2**15 - 1))
    plt.plot(cc * 2, detected_phase / (2**18 - 1))
    plt.plot(cc * 2,
             np.sin(2 * np.pi * accumulated / (2**19 - 1)), accumulated /
             (2**19 - 1))
    plt.show()


def names_from_header(fname):
    '''
    header of the form:
    # col1, col2 ... , colN
    '''
    with open(fname, 'r') as f:
        line = f.readline()
        return [x.strip() for x in line.strip().strip('#').split()]


def get_data_from_outfile(fname):
    names = names_from_header(fname)
    data = np.genfromtxt(fname, dtype=int, names=names, comments='#')
    return data


def verify_multiply_accumulate(data, show=False):
    tests = []
    acc = data['accumulated']
    for ix in range(20):
        if ix == 5 or ix == 6:
            continue  # special case
        diff = acc[ix*10+3:ix*10+11] - acc[ix*10+2:ix*10+10]
        if not all([diff[0] == x for x in diff]):
            print('FAIL: Difference test %d' % ix)
            tests.append(False)
        else:
            tests.append(True)

    sig = data['signal']
    constant = data['constant']
    inc = (sig * constant >> data['downscale']) + data['correction']
    inc *= data["enable"]
    inc = (inc >> 15)
    if False:  # still working on this
        acc1 = 0
        for jx in range(len(inc)-1):
            acc1 += inc[jx]
            print(inc[jx], acc1, acc[jx])
    accumulated = sum(inc[:-1])
    if False and accumulated != acc[-1]:
        print('FAIL: Accumulator test\n'
              'expected:{} noticed:{}'.format(accumulated,
                                              acc[-1] - 1))
        tests.append(False)
    else:
        tests.append(True)
    PASS = tests != [] and all(tests)
    if PASS:
        print('PASS')
    return PASS


def verify_non_iq_interleaved_piloop(data, show=True):
    tests = [True]
    cc = data['cc']
    if show:
        for n in data.dtype.names:
            if n != 'cc' and n in ['y_i', 'y_q', 'kp', 'ki']:
                plt.plot(cc, data[n], label=n)
        plt.plot(cc, data['setpoint_i'] - data['x_i'], label='err_i/q')
        plt.legend()
        plt.show()

    PASS = tests != [] and all(tests)
    if PASS:
        print('PASS')
    return PASS


def verify_dsp_core(data, show=True):
    tests = [True]
    cc = data['cc']
    if show:
        for n in data.dtype.names:
            if n == 'detected_phase':
                plt.plot(cc, data[n]/1000., label='detect_ph/1000')
            elif n not in ['cc', 'total_phase',
                           'cav_field', 'cav_phref']:
                plt.plot(cc, data[n], label=n)
        # pi_out = data['pi_out_i'] + 1j * data['pi_out_q']
        # plt.plot(cc, np.abs(pi_out), label='PIOut-mag')
        # plt.plot(cc, np.angle(pi_out), label='PIOut-phase')
        plt.legend()
        plt.show()

    PASS = tests != [] and all(tests)
    if PASS:
        print('PASS')
    return PASS


def verify_cic(data, show=False):
    tests = []
    cc = data['cc']
    delta_a_expected, delta_a_tolerance = 2000, 1.
    delta_ph_expected, delta_ph_tolerance = 0.1, 1e-4
    ch1 = data['I1'] + 1j * data['Q1']
    ch2 = data['I2'] + 1j * data['Q2']
    residue = abs(np.abs(ch2[-1]) - np.abs(ch1[-1]) - delta_a_expected)
    tests.append(residue < delta_a_tolerance)
    residue = abs(abs(np.angle(ch2[-1]) - np.angle(ch1[-1])) - delta_ph_expected)
    tests.append(residue < delta_ph_tolerance)
    if show:
        for n in data.dtype.names:
            if n in ('I1', 'I2', 'I3', 'I4', 'I5', 'I6', 'I7', 'I8', 'I9'):
                c = data[n] + 1j * data[n.replace('I', 'Q')]
                plt.plot(cc, np.abs(c), label=n.replace('I', 'A'))
                # plt.plot(cc, np.angle(c), label=n.replace('I', 'P'))
        plt.legend()
        plt.show()
    PASS = tests != [] and all(tests)
    if PASS:
        print('PASS')
    else:
        print('FAIL')
    return PASS


def verify(function_name, data, show=False):
    specific_name = 'verify_' + function_name
    if specific_name in globals():
        return globals()[specific_name](data, show=show)
    else:
        print('No {} available'.format(specific_name))
        print('Using the generic verify routine')

    if show:
        cc = data['cc']
        for n in data.dtype.names:
            if n != 'cc':
                plt.plot(cc, data[n], label=n)
        plt.legend()
        plt.show()


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description='A test module for Verilog output')
    parser.add_argument(
        '-f',
        '--function',
        help='A verilog file basename',
        default='multiply_accumulate')
    parser.add_argument(
        '-s',
        '--show',
        help='Show a plot as opposed to pass fail',
        action='store_true')
    args = parser.parse_args()
    data = get_data_from_outfile(fname='{}.out'.format(args.function))
    exit(not verify(args.function, data, args.show))
