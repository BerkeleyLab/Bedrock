import argparse
import re

# from zest/digitizer_digital_pin.txt:
#   P1    G6    ADC_DCO_N_0
# and ANSI/VITA 57.1-2008 FMC Pinout:
#   LA00_CC_P  G6
# generate:
# FMC1_LA00_CC_P ADC_DCO_N_0

# ADC_D1C_N_1   -> ZEST_ADC_D1_N[6]
adc_pat = re.compile(r'^ADC_(D[01])([A-D])_([PN])_([01])')
# ADC_DCO_N_1   -> ZEST_ADC_DCO_N[1]
adc_dco_pat = re.compile(r'^ADC_([DF]CO)_([PN])_([01])')
# DAC_DCO_N   -> ZEST_DAC_DCO_N
dac_dco_pat = re.compile(r'^DAC_(DC[IO])_([PN])')
# DAC_D_N_1     -> ZEST_DAC_D_N[1]
dac_pat = re.compile(r'^DAC_D_([PN])_(\d+)')
# PMOD_1_3      -> ZEST_PMOD1[2]
# PMOD_1_7      -> ZEST_PMOD1[4]
pmod_pat = re.compile(r'^PMOD_([12])_(\d+)')
# LMK_Clkout4_P -> ZEST_CLK_TO_FPGA_P
lmk_pat = re.compile(r'^LMK_CLKout([34])_([PN])')
# P2_*          -> ZEST_*
p2_pat = re.compile(r'^P2_*')
# HDMI_*          -> ZEST_HDMI*
hdmi_pat = re.compile(r'^HDMI_*')


def map_in(fname='vita_57.1_pinout.txt'):
    pin_to_name = {}
    for ll in open(fname).read().splitlines():
        ll = ll.strip().split()
        if len(ll) == 2:
            fmc_name, pin = ll
            pin_to_name[pin] = fmc_name
    return pin_to_name


def format_signal(s):
    m = adc_pat.match(s)
    if m:
        lane, chan, pol, chip = m.groups()
        idx = 4 * int(chip) + ord(chan) - ord('A')
        return 'ZEST_ADC_{}_{}[{:d}]'.format(lane, pol, idx)

    m = adc_dco_pat.match(s)
    if m:
        clk, pol, chip = m.groups()
        return 'ZEST_ADC_{}_{}[{}]'.format(clk, pol, chip)

    m = dac_dco_pat.match(s)
    if m:
        clk, pol = m.groups()
        return 'ZEST_DAC_{}_{}'.format(clk, pol)

    m = dac_pat.match(s)
    if m:
        pol, bit_idx = m.groups()
        return 'ZEST_DAC_D_{}[{}]'.format(pol, bit_idx)

    m = pmod_pat.match(s)
    if m:
        port, pin = m.groups()
        pin_d = int(pin)
        pin_d = (pin_d - 1) if pin_d < 5 else (pin_d - 3)
        return 'ZEST_PMOD{}[{:d}]'.format(port, pin_d)

    m = lmk_pat.match(s)
    if m:
        idx, pol = m.groups()
        return 'ZEST_CLK_TO_FPGA_{}[{:d}]'.format(pol, int(idx)-3)

    s = p2_pat.sub('ZEST_', s)
    s = hdmi_pat.sub('ZEST_HDMI_', s)

    if '/' in s:
        return s.split('/')[0]
    else:
        return s


def zest_in(fname):
    p1 = {}
    p2 = {}

    for ll in open(fname).read().splitlines():
        port, pin, s = ll.split()
        signal = format_signal(s)
        if port == 'P1':
            p1[pin] = signal
        elif port == 'P2':
            p2[pin] = signal
    return p1, p2


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Remap FMC PINs for generating constraints')
    parser.add_argument(
        '-p', '--prefix',
        default='./bedrock', help='bedrock_dir path')
    parser.add_argument(
        '--vita57',
        default='./bedrock/board_support/zest/vita_57.1_pinout.txt')
    parser.add_argument(
        '-o', '--output', help="output pinmap", default='zest_pinmap.txt')
    args = parser.parse_args()

    pin_to_name = map_in(args.vita57)
    p1, p2 = zest_in(args.prefix + '/board_support/zest/digitizer_digital_pin.txt')

    with open(args.output, 'w+') as fo:
        for pin in sorted(p1.keys()):
            if pin in pin_to_name:
                fo.write('{:20s} {:s}\n'.format(
                    'FMC1_' + pin_to_name[pin], p1[pin]))
            else:
                print('ignored: %s, %s' % (pin, p1[pin]))
        for pin in sorted(p2.keys()):
            if pin in pin_to_name:
                fo.write('{:20s} {:s}\n'.format(
                    'FMC2_' + pin_to_name[pin], p2[pin]))
            else:
                print('ignored: %s, %s' % (pin, p2[pin]))
