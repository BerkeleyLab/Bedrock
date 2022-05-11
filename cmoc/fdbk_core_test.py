from subprocess import call
import numpy as np
import matplotlib.pylab as plt

from read_regmap import get_map, get_reg_info


def write_reg_file(registers, regmap_fdbk_core, filename):
    """
    Write register file with the following format for input to Verilog test-bench:
        'address1 data1'
        'address2 data2'
        ...
    Inputs:
        - registers: Array of Register objects,
        - regmap_fdbk_core: Register map,
        - filename: Name of the output file.
    """

    f = open(filename, 'w')
    for reg in registers:
        base_addr = reg['base_addr']
        for i, val in enumerate(reg['value']):
            line = '%d %d\n' % (base_addr + i, val)
            f.write(line)
    f.close()


def run_test_bench(setmp_val,
                   coeff_val,
                   lim_val,
                   test_type,
                   in_file,
                   out_file,
                   setmp_step_time=0,
                   setmp_step_val=0,
                   lim_step_time=0,
                   lim_step_val=0,
                   in_i=0,
                   in_q=0):
    """
    Generates an input file for fdbk_core_tb with the appropriate register settings,
    and runs test-bench using Icarus Verilog.
    """

    # Get register map from JSON
    regmap_fdbk_core = get_map("./_autogen/regmap_fdbk_core_tb.json")

    # Extract the registers of interest
    setmp = get_reg_info(regmap_fdbk_core, [], 'setmp')  # Set-points
    coeff = get_reg_info(regmap_fdbk_core, [], 'coeff')  # Feedback loop gains
    lim = get_reg_info(regmap_fdbk_core, [],
                       'lim')  # Controller upper and lower limits

    setmp['value'] = setmp_val  # set X, set Y
    coeff['value'] = coeff_val  # coeff X I, coeff Y I, coeff X P, coeff Y P
    lim['value'] = lim_val  # lim X hi, lim Y hi, lim X lo, lim Y lo

    # Write the configuration file (register writes) for the test-bench
    write_reg_file([setmp, coeff, lim], regmap_fdbk_core, in_file)

    # Start with empty command to handle exception
    command = ''

    if ((test_type == 2) or (test_type == 3) or (test_type == 4) or (test_type == 5)):
        # Write configuration file for set-point step
        setmp_file = 'setmp_step_file_in.dat'
        # index selects either amplitude or phase step on the set-point
        if (test_type == 2 or test_type == 4):  # Amplitude modulation
            index = 0
        elif (test_type == 3 or test_type == 5):  # Phase modulation
            index = 1

        # Apply step to set-point to amplitude or phase depending on the test
        setmp['value'][
            index] = setmp['value'][index] + setmp_step_val  # set X, set Y
        write_reg_file([setmp], regmap_fdbk_core, setmp_file)

        # Write configuration file for limits step
        lim_file = 'lim_step_file_in.dat'
        lim['value'] = lim_step_val
        write_reg_file([lim], regmap_fdbk_core, lim_file)

        # Command line to run Verilog simulation
        # Arguments depend on the type of test-bench being run (test_type)
        command = 'vvp -M /home/lib/ivl -n fdbk_core_tb +vcd +test=' + \
            str(test_type) + ' +in_file=' + in_file + ' +out_file=' + out_file + \
            ' +sp_step_time=' + str(setmp_step_time) + ' +sp_step_file=' + setmp_file +\
            ' +lim_step_time=' + str(lim_step_time) + ' +lim_step_file=' + lim_file

        if (test_type == 3) or (test_type == 5):
            command = command + ' +in_i=' + str(in_i) + ' +in_q=' + str(in_q)

    elif (test_type == 0 or test_type == 4):
        command = 'vvp -M /home/lib/ivl -n fdbk_core_tb +vcd +test=' + str(
            test_type) + ' +in_file=' + in_file + ' +out_file=' + out_file
    elif (test_type == 1):
        command = 'vvp -M /home/lib/ivl -n fdbk_core_tb +vcd +test=' + str(
            test_type
        ) + ' +in_file=' + in_file + ' +out_file=' + out_file + ' +in_i=' + str(
            in_i) + ' +in_q=' + str(in_q)

    # Run the Verilog test-bench
    print(('Running Verilog test-bench from Python...\n\n' + command + '\n'))

    if command == '':
        print('test_type not defined with a valid code')
        print(('test_type value supplied is ' + str(test_type)))
    else:
        call(command, shell=True)


def trace_plotter(title, trang, waves=[], yscale=1.0,
                  xlim=None, ylim=None, ylabel='Amplitude [FPGA counts]',
                  texts=[], x0=None, y1=None, y2=None, edge=None):
    """
    Stupid utility function; doesn't do much other than reduce
    the space taken up by the python each time a plot is wanted.
    """
    for tt in texts:
        plt.text(tt[0], tt[1]*yscale, tt[2], verticalalignment='top', fontsize=24)
    for ww in waves:
        plt.plot(trang*1e6, ww[0]*yscale, label=ww[1], linewidth=2)
    # Format plot
    plt.title(title, fontsize=30, y=1.01)
    plt.xlabel('Time [' + r'${\rm \mu}$' + 's]', fontsize=24)
    plt.ylabel(ylabel, fontsize=24)
    plt.legend(loc='upper right')
    if xlim is not None:
        plt.xlim(xlim)
    if ylim is not None:
        plt.ylim(ylim)
    # Optional decorations
    if x0 is not None:
        plt.axvline(x=x0*1e6, color='k', linestyle='--')
    if y1 is not None:
        plt.axhline(y=y1*yscale, color='r', linestyle='--')
    if y2 is not None:
        plt.axhline(y=y2*yscale, color='g', linestyle='--')
    if edge is not None:
        fdbk_out = waves[1][0]  # Hack!
        plt.plot(trang[edge]*1e6, fdbk_out[edge]*yscale, label='Slope', linewidth=3)
    plt.show()


def run_sp_test_bench(plot=False):
    """
    Set-point scaling test:
    The test-bench drives the input of the feedback controller with a given value
    and this function is supposed to adjust (process done manually) for the scaling
    needed on the set-point setting in order to obtain a 0 error signal.
    This exercise is done for both amplitude and phase.
    """

    print("\n---- Set-point scaling test-bench ----\n")

    print("---- Amplitude test ----\n")

    # Set set-point to pre-defined value on amplitude, 0 phase
    # and evaluate amplitude of error signal
    setmp_val = [32000 * 1.646760258 / 2, 0]
    # Feedback gains are irrelevant for this test
    coeff_val = [0, 0, 0, 0]
    # Set upper and lower limits to some high aperture
    lim_val = [100000, 100000, -100000, -100000]

    test_type = 0
    in_file = 'fdbk_core_sp_in.dat'
    out_file = 'fdbk_core_sp_out.dat'

    # Run Verilog test-bench
    run_test_bench(setmp_val, coeff_val, lim_val, test_type, in_file, out_file)

    # Load output file from Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)
    # Build time vector
    Tstep = 10e-9  # Step size is 10 ns
    # Need the factor of eight on the time step since data is recorded every 8 10ns cycle
    trang = np.arange(0.0, 8.0 * Tstep * data.shape[0], 8.0 * Tstep)

    # Grab controller's input, set-point and error signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    input_mp = data[:, 2] + 1j * data[:, 3]
    setpoint = data[:, 0] + 1j * data[:, 1]
    error = data[:, 4] + 1j * data[:, 5]

    print('\nResults after setting:\n')
    print(('\tInput (magnitude): %d' % (np.real(input_mp[-1]))))
    print(('\tSet-point: %d' % (np.real(setpoint[-1]))))
    print(('\tError: %d' % (np.real(error[-1]))))

    pass_amp_test = np.real(error[-1]) < 5
    if (pass_amp_test):
        result = 'PASS'
    else:
        result = 'FAIL'
    print((">>> " + result))

    if plot:
        waves = [(np.real(input_mp), 'Input Amplitude'), (np.real(setpoint), 'Set-point Amplitude')]
        waves += [(np.real(error), 'Error Amplitude')]
        trace_plotter(
            "Set-point amplitude scaling test-bench", trang, waves=waves,
            ylim=(-80000, 80000))

    print("---- Phase test ----\n")
    # Set set-point to pre-defined value on both amplitude and phase,
    # and evaluate phase of error signal

    amplitude_set = 5000  # FPGA Counts

    # Test is run for a series of phases included in this array
    phase_set = np.array([0.0, 45.0, 90.0, 135.0, 180.0, -180.0,
                          -135.0])  # Degrees
    phase_set_rad = phase_set * 2.0 * np.pi / 360  # Radians

    # Calculate the input in I and Q coordinates corresponding to the set
    # The input signal to the controller is in Cartesian coordinates thus the translation
    in_i = amplitude_set * np.cos(phase_set_rad)
    in_q = amplitude_set * np.sin(phase_set_rad)

    in_i = in_i.astype(int)
    in_q = in_q.astype(int)

    # Feedback gains are irrelevant for this test
    coeff_val = [0, 0, 0, 0]
    # Set upper and lower limits to some high aperture
    lim_val = [100000, 100000, -100000, -100000]
    test_type = 1

    # Starting value is True for the entire set, turns to False if any test fails
    pass_phase_test = True

    for i, phase in enumerate(phase_set):

        # Scale amplitude and phase of set-point with the appropriate scaling factors
        setmp_val = [
            amplitude_set * 1.646760258 / 2,
            phase_set_rad[i] * (2**17 - 1) * 2.0 / (2 * np.pi)
        ]

        # Run Verilog test-bench
        run_test_bench(
            setmp_val,
            coeff_val,
            lim_val,
            test_type,
            in_file,
            out_file,
            in_i=in_i[i],
            in_q=in_q[i])
        # Load output file from Verilog test-bench
        data = np.loadtxt(out_file, skiprows=1)
        # Build time vector
        Tstep = 10e-9  # Step size is 10 ns
        # Need the factor of eight on the time step since data is recored every 8 10ns cycle
        trang = np.arange(0.0, 8.0 * Tstep * data.shape[0], 8.0 * Tstep)

        # Grab controller's input, set-point and error signals from data
        # Note that these signals are really in polar coordinates,
        # arranged here in Cartesian for convenience,
        # but real is really amplitude and imaginary is phase.
        input_mp = data[:, 2] + 1j * data[:, 3]
        setpoint = data[:, 0] + 1j * data[:, 1]
        error = data[:, 4] + 1j * data[:, 5]

        print('\nResults after setting:\n')
        print(('\tInput (phase): %5f' % (np.imag(input_mp[-1]) * 360 / 2**18)))
        print(('\tSet-point: %5f' % (np.imag(setpoint[-1]) * 360 / 2**18)))
        print(('\tError: %5f' % (np.imag(error[-1]) * 360 / 2**18)))

        pass_this_phase_test = np.imag(error[-1]) < 5
        if (pass_this_phase_test):
            result = 'PASS'
        else:
            result = 'FAIL'
        print((">>> " + result))

        if plot:
            title_text = 'Set-point phase scaling test-bench (%d' % (
                int(phase)) + r'$\degree$' + ')'
            waves = [(np.imag(input_mp), 'Input'), (np.imag(setpoint), 'Set-point'), (np.imag(error), 'Error')]
            trace_plotter(
                title_text, trang, waves=waves,
                yscale=360*0.5**18, ylabel='Phase [Degrees]')

        pass_phase_test = pass_phase_test & pass_this_phase_test

    return pass_amp_test & pass_phase_test


def run_prop_test_bench(plot=False):
    """
    Proportional gain scaling test:
    This test-bench drives the input of the feedback controller with a given value
    that combined with the set-point setting produces a 0 output signal.
    Then a step is applied to the set-point value and the change in the output signal is characterized.
    The integral gain is set to 0 to isolate its effect from the proportional path.
    This exercise is done for both amplitude and phase.
    """

    print("\n---- Proportional gain scaling test-bench ----\n")
    print("---- Amplitude test ----\n")

    setmp_val = [320 * 1.646760258 / 2 + 1, 0]
    coeff_val = [0, 0, 900, 0]  # coeff X I, coeff Y I, coeff X P, coeff Y P
    lim_val = [0, 0, 0, 0]

    setmp_step_val = 4000
    lim_step_val = [78000, 78000, -78000, -78000]
    setmp_step_time = 150

    test_type = 2
    in_file = 'fdbk_core_prop_amp_in.dat'
    out_file = 'fdbk_core_prop_amp_out.dat'

    # Run Verilog test-bench
    run_test_bench(
        setmp_val,
        coeff_val,
        lim_val,
        test_type,
        in_file,
        out_file,
        setmp_step_time=setmp_step_time,
        setmp_step_val=setmp_step_val,
        lim_step_time=100,
        lim_step_val=lim_step_val)

    # Load data file generated by Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)

    # Build time vector
    # Step size is Verilog simulation is 10 ns, however the FPGA logic interleaves I/Q samples
    # and data here is handled as complex numbers at half that rate
    Tstep = 10e-9
    trang = np.arange(0.0, 2.0 * Tstep * data.shape[0], 2.0 * Tstep)

    # Grab controller's set-point and output signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    fdbk_in = data[:, 0] + 1j * data[:, 1]
    setpoint = data[:, 2] + 1j * data[:, 3]
    fdbk_out = data[:, 4] + 1j * data[:, 5]
    error = data[:, 6] + 1j * data[:, 7]

    # Scale by the appropriate scaling factor
    kp = coeff_val[2] * 1.646760258 / 2**6

    # Find latency in clock cycles
    out1 = np.real(fdbk_out[int(setmp_step_time / 2)])
    out2 = np.real(fdbk_out[int(setmp_step_time / 2) + int(100 / 2)])
    edge_ind = np.where((np.real(fdbk_out) < out1 - 2) &
                        (np.real(fdbk_out) > out2 + 2))[0]

    kp_measured = (fdbk_out[edge_ind[0] - 1] - fdbk_out[edge_ind[-1] + 1]
                   ) / -setmp_step_val
    ll = kp, np.real(kp_measured)
    kp_text = r'$\rm k_{\rm p}$' + ' set to: %.3f, measured: %.3f' % ll
    print('\nKp set to: %.3f, measured: %.3f' % ll)

    if plot:
        texts = [(1.6, -60000, kp_text)]
        waves = [(np.real(fdbk_in), 'fdbk_in'),
                 (np.real(setpoint), 'Set-point'),
                 (np.real(fdbk_out), 'Controller Output'),
                 (np.real(error), 'Error')]
        trace_plotter(
            "Proportional gain test-bench (Amplitude)", trang, waves=waves,
            xlim=(1.4, 2.5), ylim=(-140000, 30000),
            texts=texts,
            x0=setmp_step_time*Tstep, y1=out1, y2=out2)

    print("---- Phase test ----\n")

    amplitude_set = 5000  # FPGA Counts
    phase_set = 35  # Degrees
    phase_set_rad = phase_set * 2.0 * np.pi / 360  # Radians
    setmp_val = [
        amplitude_set * 1.646760258 / 2,
        phase_set_rad * (2**17 - 1) * 2.0 / (2 * np.pi)
    ]

    # Calculate the input in I and Q coordinates corresponding to the set
    in_i = int(amplitude_set * np.cos(phase_set_rad))
    in_q = int(amplitude_set * np.sin(phase_set_rad))

    coeff_val = [0, 0, 0, 900]  # coeff X I, coeff Y I, coeff X P, coeff Y P
    lim_val = [0, 0, 0, 0]

    setmp_step_val = 4000

    test_type = 3
    in_file = 'fdbk_core_prop_phase_in.dat'
    out_file = 'fdbk_core_prop_phase_out.dat'

    # Run Verilog test-bench
    run_test_bench(
        setmp_val,
        coeff_val,
        lim_val,
        test_type,
        in_file,
        out_file,
        setmp_step_time=setmp_step_time,
        setmp_step_val=setmp_step_val,
        lim_step_time=100,
        lim_step_val=lim_step_val,
        in_i=in_i,
        in_q=in_q)

    # Load data file generated by Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)

    # Grab controller's set-point and output signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    fdbk_in = data[:, 0] + 1j * data[:, 1]
    setpoint = data[:, 2] + 1j * data[:, 3]
    fdbk_out = data[:, 4] + 1j * data[:, 5]
    error = data[:, 6] + 1j * data[:, 7]

    # Scale by the appropriate scaling factor
    kp = coeff_val[3] * 1.646760258 / 2**6

    # Find latency in clock cycles
    out1 = np.imag(fdbk_out[int(setmp_step_time / 2)])
    out2 = np.imag(fdbk_out[int(setmp_step_time / 2) + int(100 / 2)])
    edge_ind = np.where((np.imag(fdbk_out) < out1 - 2) &
                        (np.imag(fdbk_out) > out2 + 2))[0]

    kp_measured = (fdbk_out[edge_ind[0] - 1] - fdbk_out[edge_ind[-1] + 1]
                   ) / -setmp_step_val
    ll = kp, np.imag(kp_measured)
    kp_text = r'$\rm k_{\rm p}$' + ' set to: %.3f, measured: %.3f' % ll
    print('\nKp: Set to %.3f, measured: %.3f' % ll)

    if plot:
        texts = [(1.6, -60000, kp_text)]
        waves = [(np.imag(setpoint), 'Set-point'), (np.imag(fdbk_out), 'Controller Output'), (np.imag(error), 'Error')]
        trace_plotter(
            "Proportional gain test-bench (Phase)", trang, waves=waves,
            yscale=360*0.5**18, ylabel='Phase [Degrees]',
            xlim=(1.4, 2.5),
            texts=texts,
            x0=setmp_step_time*Tstep, y1=out1, y2=out2)


def run_int_test_bench(plot=False):
    """
    Integral gain scaling test:
    The test-bench drives the input of the feedback controller with a given value
    that combined with the set-point setting produces a 0 output signal.
    Then a step is applied to the set-point value and the change in the output signal is characterized.
    The proportional gain is set to 0 to isolate its effect from the integral path.
    This exercise is done for both amplitude and phase.
    """

    print("\n---- Integral gain scaling test-bench ----\n")
    print("---- Amplitude test ----\n")

    setmp_val = [320 * 1.646760258 / 2 + 1, 0]
    coeff_val = [1400, 0, 0, 0]  # coeff X I, coeff Y I, coeff X P, coeff Y P
    lim_val = [0, 0, 0, 0]

    setmp_step_val = 8000
    limit = 30000
    lim_step_val = [
        limit / 1.646760258, limit / 1.646760258, -limit / 1.646760258,
        -limit / 1.646760258
    ]
    setmp_step_time = 150

    test_type = 2

    in_file = 'fdbk_core_int_in.dat'
    out_file = 'fdbk_core_int_out.dat'

    # Run Verilog test-bench
    run_test_bench(
        setmp_val,
        coeff_val,
        lim_val,
        test_type,
        in_file,
        out_file,
        setmp_step_time=setmp_step_time,
        setmp_step_val=setmp_step_val,
        lim_step_time=100,
        lim_step_val=lim_step_val)

    # Load data file generated by Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)

    # Build time vector
    # Step size in Verilog simulation is 10 ns, however the FPGA logic interleaves I/Q samples
    # and data array as read above gives complex numbers at half that rate
    Tstep = 10e-9  # Step size is 10 ns
    trang = np.arange(0.0, 2.0 * Tstep * data.shape[0], 2.0 * Tstep)

    # Grab controller's set-point and output signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    fdbk_in = data[:, 0] + 1j * data[:, 1]
    setpoint = data[:, 2] + 1j * data[:, 3]
    fdbk_out = data[:, 4] + 1j * data[:, 5]
    error = data[:, 6] + 1j * data[:, 7]

    # Scale by the appropriate scaling factor
    ki = coeff_val[0] * 1.646760258 / 2**15 / Tstep

    out1 = np.real(fdbk_out[int(setmp_step_time / 2)])
    # out2 = np.real(fdbk_out[int(setmp_step_time / 2) + int(100 / 2)])

    edge_ind = np.where((np.real(fdbk_out) < out1 - 1500) &
                        (np.real(fdbk_out) > -limit + 1500))[0]

    slope, b = np.polyfit(trang[edge_ind], np.real(fdbk_out[edge_ind]),
                          1)  # Slope in units of counts / s
    ki_measured = slope / setmp_step_val
    ll = ki, np.real(ki_measured), ki / ki_measured
    ki_text = r'$\rm k_{\rm i}$' + ': set to %.1f/s, measured %.1f/s, factor %.4f' % ll
    low_lim = fdbk_out[-1]
    limit_text = 'Lower limit set to %d , measured %.1f' % (-limit,
                                                            np.real(low_lim))

    print('\nKi: Set to %.1f, measured %.1f, factor %.4f' % ll)
    print(limit_text)

    if plot:
        texts = [(0.25, -10000, ki_text), (0.25, -15000, limit_text)]
        waves = [(np.real(setpoint), 'Set-point'), (np.real(fdbk_out), 'Controller Output')]
        trace_plotter(
            "Integral gain test-bench (Amplitude)", trang, waves=waves,
            xlim=(0.0, 3.5), ylim=(-40000, 20000), texts=texts,
            edge=edge_ind)

    print("---- Phase test ----\n")

    amplitude_set = 5000  # FPGA Counts
    phase_set = 5  # Degrees
    phase_set_rad = phase_set * 2.0 * np.pi / 360  # Radians
    setmp_val = [
        amplitude_set * 1.646760258 / 2,
        phase_set_rad * (2**17 - 1) * 2.0 / (2 * np.pi)
    ]

    # Calculate the input in I and Q coordinates corresponding to the set
    in_i = int(amplitude_set * np.cos(phase_set_rad))
    in_q = int(amplitude_set * np.sin(phase_set_rad))

    coeff_val = [0, 1400, 0, 0]  # coeff X I, coeff Y I, coeff X P, coeff Y P
    lim_val = [0, 0, 0, 0]

    setmp_step_val = 8000

    test_type = 3
    in_file = 'fdbk_core_int_phase_in.dat'
    out_file = 'fdbk_core_int_phase_out.dat'

    # Run Verilog test-bench
    run_test_bench(
        setmp_val,
        coeff_val,
        lim_val,
        test_type,
        in_file,
        out_file,
        setmp_step_time=setmp_step_time,
        setmp_step_val=setmp_step_val,
        lim_step_time=100,
        lim_step_val=lim_step_val,
        in_i=in_i,
        in_q=in_q)

    # Load data file generated by Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)

    # Grab controller's set-point and output signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    fdbk_in = data[:, 0] + 1j * data[:, 1]
    setpoint = data[:, 2] + 1j * data[:, 3]
    fdbk_out = data[:, 4] + 1j * data[:, 5]
    error = data[:, 6] + 1j * data[:, 7]

    # Scale by the appropriate scaling factor
    ki = coeff_val[1] * 1.646760258 / 2**15 / Tstep

    out1 = np.imag(fdbk_out[int(setmp_step_time / 2)])
    # out2 = np.imag(fdbk_out[int(setmp_step_time / 2) + int(100 / 2)])

    edge_ind = np.where((np.imag(fdbk_out) < out1 - 1500) &
                        (np.imag(fdbk_out) > -limit + 1500))[0]

    slope, b = np.polyfit(trang[edge_ind], np.imag(fdbk_out[edge_ind]),
                          1)  # Slope in units of counts / s
    ki_measured = slope / setmp_step_val
    ll = ki, ki_measured, ki / ki_measured
    ki_text = r'$\rm k_{\rm i}$' + ': set to %.1f/s, measured %.1f/s, factor %.4f' % ll
    low_lim = fdbk_out[-1]
    limit_text = 'Lower limit set to %d, measured %.1f' % (-limit,
                                                           np.imag(low_lim))

    print('\nKi: Set to %.1f, measured %.1f, factor %.4f' % ll)
    print(limit_text)

    if plot:
        texts = [(0.25, -10000, ki_text), (0.25, -15000, limit_text)]
        waves = [(np.imag(setpoint), 'Set-point'), (np.imag(fdbk_out), 'Controller Output')]
        trace_plotter(
            "Integral gain test-bench", trang, waves=waves,
            yscale=360*0.5**18, ylabel='Phase [Degrees]',
            ylim=(-70, 35), texts=texts,
            edge=edge_ind)


def run_latency_test_bench(plot=False):

    print("\n---- Latency test-bench ----\n")

    # Set set-point to pre-defined value on amplitude, 0 phase
    # and evaluate amplitude of error signal
    setmp_val = [32000 * 1.646760258 / 2 + 1, -1]
    # Feedback gains are irrelevant for this test
    coeff_val = [0, 0, 500, 500]
    # Set upper and lower limits to some high aperture
    lim_val = [0, 0, -0, -0]

    test_type = 4
    in_file = 'fdbk_core_latency_in.dat'
    out_file = 'fdbk_core_latency_out.dat'

    setmp_step_val = 0
    limit = 100000
    lim_step_val = [
        limit / 1.646760258, limit / 1.646760258, -limit / 1.646760258,
        -limit / 1.646760258
    ]
    setmp_step_time = 500
    lim_step_time = 100

    # Run Verilog test-bench
    run_test_bench(
        setmp_val,
        coeff_val,
        lim_val,
        test_type,
        in_file,
        out_file,
        setmp_step_time=setmp_step_time,
        setmp_step_val=setmp_step_val,
        lim_step_time=lim_step_time,
        lim_step_val=lim_step_val)

    # Load output file from Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)
    # Build time vector
    Tstep = 10e-9  # Step size is 10 ns
    # Need the factor of two on the time step since data is recored every other 10ns cycle
    trang = np.arange(0.0, 2.0 * Tstep * data.shape[0], 2.0 * Tstep)

    # Grab controller's input and output signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    fdbk_in = data[:, 0] + 1j * data[:, 1]
    fdbk_out = data[:, 2] + 1j * data[:, 3]
    # error = data[:, 4] + 1j * data[:, 5]

    # Find latency in clock cycles
    input_step_idx = np.where(np.real(fdbk_in) == 35000)[0]
    output_step_idx = np.where(np.real(fdbk_out) > 0)[0]

    # One sample in data corresponds to two clock cycles in the test bench, thus the factor of 2
    latency_clks = 2 * (output_step_idx[0] - input_step_idx[0])
    # Latency in ns at 100 MHz
    # latency_ns = latency_clks * Tstep * 1e9

    latency_text = 'Latency through fdbk_core is %d clock cycles' % latency_clks
    print("\n" + latency_text + "\n")

    if plot:
        texts = [(0.5, 20000, latency_text)]
        waves = [(np.real(fdbk_in), 'Controller Input'), (np.real(fdbk_out), 'Controller Output')]
        trace_plotter(
            "Latency test-bench", trang, waves=waves, texts=texts,
            ylim=(-10000, 50000))


def run_cavity_step_test(plot=False):
    """
    Proportional Cavity Step test:
    The test-bench drives the input of the feedback controller with a given value
    that combined with the set-point setting produces a 0 output signal.
    Then a step is applied to the cavity I&Q value and the change in the output signal is characterized.
    The integral gain is set to 0 to isolate its effect from the proportional path.
    This exercise is done for both amplitude and phase.
    """

    print("\n---- Cavity Step Test ----\n")
    print("---- Amplitude test ----\n")

    amplitude_set = 10000  # FPGA Counts
    phase_set = 0  # Degrees
    phase_set_rad = phase_set * np.pi / 180  # Radians
    setmp_val = [
        amplitude_set * 1.646760258 / 2,
        phase_set_rad * (2**17 - 1) * 2.0 / (2 * np.pi)
    ]
    coeff_val = [0, 0, 450, 0]  # coeff X I, coeff Y I, coeff X P, coeff Y P
    lim_val = [0, 0, 0, 0]

    # Calculate the input in I and Q coordinates corresponding to the set
    in_i = int(amplitude_set * np.cos(phase_set_rad))
    in_q = int(amplitude_set * np.sin(phase_set_rad))
    print(in_i)
    print(in_q)

    test_type = 5
    in_file = 'fdbk_core_cav_step_in.dat'
    out_file = 'fdbk_core_cav_step_out.dat'

    setmp_step_time = 150
    setmp_step_val = 0

    limit_amp = 60000
    limit_pha = 100000
    lim_step_val = [
        limit_amp / 1.646760258, limit_pha / 1.646760258, -limit_amp / 1.646760258,
        -limit_pha / 1.646760258
    ]
    lim_step_time = 100

    # Run Verilog test-bench
    run_test_bench(
        setmp_val,
        coeff_val,
        lim_val,
        test_type,
        in_file,
        out_file,
        setmp_step_time=setmp_step_time,
        setmp_step_val=setmp_step_val,
        lim_step_time=lim_step_time,
        lim_step_val=lim_step_val,
        in_i=in_i,
        in_q=in_q)

    # Load output file from Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)
    # Build time vector
    Tstep = 10e-9  # Step size is 10 ns
    # Need the factor of two on the time step since data is recored every other 10ns cycle
    trang = np.arange(0.0, 2.0 * Tstep * data.shape[0], 2.0 * Tstep)

    # Grab controller's input and output signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    fdbk_in = data[:, 0] + 1j * data[:, 1]
    setpoint = data[:, 2] + 1j * data[:, 3]
    fdbk_out = data[:, 4] + 1j * data[:, 5]
    error = data[:, 6] + 1j * data[:, 7]

    # Scale by the appropriate scaling factor
    kp = coeff_val[2] * 1.646760258 / 2**6 * ( 1.646760258 / 2) # n=-1 

    # Find latency in clock cycles
    out1 = np.real(fdbk_out[int(setmp_step_time / 2)])
    out2 = np.real(fdbk_out[int(setmp_step_time / 2) + int(100 / 2)])
    edge_ind = np.where((np.real(fdbk_out) > out1 - 2) &
                        (np.real(fdbk_out) < out2 + 2))[0]

    print(out1, out2, edge_ind)
    kp_measured = (fdbk_out[edge_ind[0] - 1] - fdbk_out[edge_ind[-1] + 1]
                   ) / -5000
    ll = kp, np.real(kp_measured)
    kp_text = r'$\rm k_{\rm p}$' + ' set to: %.3f, measured: %.3f' % ll
    print('\nKp set to: %.3f, measured: %.3f' % ll)

    if plot:
        waves = [(np.real(fdbk_in), 'Controller Input'),
                 (np.real(setpoint), 'Setpoint'),
                 (np.real(fdbk_out), 'Controller Output'),
                 (np.real(error), 'Error')]
        trace_plotter("Cavity step test-bench", trang, waves=waves,
                      x0=setmp_step_time*Tstep)

    print("---- Phase test ----\n")

    amplitude_set = 5000  # FPGA Counts
    phase_set = 35  # Degrees
    phase_set_rad = phase_set * np.pi / 180  # Radians
    setmp_val = [
        amplitude_set * 1.646760258 / 2,
        phase_set_rad * (2**17 - 1) * 2.0 / (2 * np.pi)
    ]
    coeff_val = [0, 0, 0, 900]  # coeff X I, coeff Y I, coeff X P, coeff Y P
    lim_val = [0, 0, 0, 0]

    # Calculate the input in I and Q coordinates corresponding to the set
    in_i = int(amplitude_set * np.cos(phase_set_rad))
    in_q = int(amplitude_set * np.sin(phase_set_rad))
    print(in_i)
    print(in_q)

    test_type = 5
    in_file = 'fdbk_core_cav_step_in.dat'
    out_file = 'fdbk_core_cav_step_out.dat'

    setmp_step_time = 150
    setmp_step_val = 0

    limit_amp = 60000
    limit_pha = 100000
    lim_step_val = [
        limit_amp / 1.646760258, limit_pha / 1.646760258, -limit_amp / 1.646760258,
        -limit_pha / 1.646760258
    ]
    lim_step_time = 100

    # Run Verilog test-bench
    run_test_bench(
        setmp_val,
        coeff_val,
        lim_val,
        test_type,
        in_file,
        out_file,
        setmp_step_time=setmp_step_time,
        setmp_step_val=setmp_step_val,
        lim_step_time=lim_step_time,
        lim_step_val=lim_step_val,
        in_i=in_i,
        in_q=in_q)

    # Load output file from Verilog test-bench
    data = np.loadtxt(out_file, skiprows=1)
    # Build time vector
    Tstep = 10e-9  # Step size is 10 ns
    # Need the factor of two on the time step since data is recored every other 10ns cycle
    trang = np.arange(0.0, 2.0 * Tstep * data.shape[0], 2.0 * Tstep)

    # Grab controller's input and output signals from data
    # Note that these signals are really in polar coordinates,
    # arranged here in Cartesian for convenience,
    # but real is really amplitude and imaginary is phase.
    fdbk_in = data[:, 0] + 1j * data[:, 1]
    setpoint = data[:, 2] + 1j * data[:, 3]
    fdbk_out = data[:, 4] + 1j * data[:, 5]
    error = data[:, 6] + 1j * data[:, 7]

    # Scale by the appropriate scaling factor
    kp = coeff_val[3] * 1.646760258 / 2**6 * ( 1.646760258 / 2) # n=-1 

    # Find latency in clock cycles
    out1 = np.imag(fdbk_out[int(setmp_step_time / 2)])
    out2 = np.imag(fdbk_out[int(setmp_step_time / 2) + int(100 / 2)])
    edge_ind = np.where((np.imag(fdbk_out) < out1 - 2) &
                        (np.imag(fdbk_out) > out2 + 2))[0]

    print(out1, out2, edge_ind)
    kp_measured = (fdbk_out[edge_ind[0] - 1] - fdbk_out[edge_ind[-1] + 1]
                   ) / -5000
    ll = kp, np.imag(kp_measured)
    kp_text = r'$\rm k_{\rm p}$' + ' set to: %.3f, measured: %.3f' % ll
    print('\nKp set to: %.3f, measured: %.3f' % ll)

    if plot:
        waves = [(np.real(fdbk_in), 'Controller Input'),
                 (np.real(setpoint), 'Setpoint'),
                 (np.real(fdbk_out), 'Controller Output'),
                 (np.real(error), 'Error')]
        trace_plotter("Cavity step test-bench", trang, waves=waves,
                      x0=setmp_step_time*Tstep)
        waves = [(np.imag(setpoint), 'Setpoint'),
                 (np.imag(fdbk_out), 'Controller Output'),
                 (np.imag(error), 'Error')]
        trace_plotter(
            "Cavity step test-bench", trang, waves=waves,
            yscale=360*0.5**18, ylabel='Phase [Degrees]',
            x0=setmp_step_time*Tstep)


if __name__ == "__main__":
    from sys import argv
    plot = len(argv) > 1 and argv[1] == "plot"
    if plot:
        plt.rcParams["figure.figsize"] = [10.5, 8.4]
        plt.rc('font', **{'size': 14})

    # Run cavity signal step test
    run_cavity_step_test(plot=plot)

    # Run Set-point scaling test
    run_sp_test_bench(plot=plot)

    # Run feedback proportional gain scaling test
    run_prop_test_bench(plot=plot)

    # Run feedback integral gain scaling test
    run_int_test_bench(plot=plot)

    # Run feedback integral gain scaling test
    run_latency_test_bench(plot=plot)
