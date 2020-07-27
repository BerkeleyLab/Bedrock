import argparse
import re


def convert_marble_vita(s):
    '''
    FMC1_LA_0_P -> FMC1_LA00_CC_P
    '''
    d = s.split('_')

    if d[1] == 'LA':
        index = int(d[2])
        postfix = 'CC_' + d[3] if index in [0, 1, 17, 18] else d[3]
        result = '{}_{}{:02d}_{}'.format(d[0], d[1], index, postfix)
    elif d[1] == 'HA':
        index = int(d[2])
        postfix = 'CC_' + d[3] if index in [0, 1, 17] else d[3]
        result = '{}_{}{:02d}_{}'.format(d[0], d[1], index, postfix)
    elif d[1] == 'HB':
        index = int(d[2])
        postfix = 'CC_' + d[3] if index in [0, 6, 17] else d[3]
        result = '{}_{}{:02d}_{}'.format(d[0], d[1], index, postfix)
    else:
        result = s
    return result


def write_xdc(fo, carrier, mezzanine):
    '''
    ['set_property', '-dict', '{PACKAGE_PIN', 'Y22', 'IOSTANDARD',
     'DIFF_HSTL_II_25}', '[get_ports', 'FMC1_LA_15_N']
    '''
    fmt = 'set_property -dict "PACKAGE_PIN {:s} IOSTANDARD {:s}" [get_ports {:s}]\n'

    for d in carrier:
        if 'FMC' in d[7]:
            for s in mezzanine:
                vita, signal = s
                package_pin = d[3]
                vita_carrier = convert_marble_vita(d[7])
                if vita == vita_carrier:
                    if re.search(r'_[PN](\[\d+\]|$)', signal):
                        io = 'LVDS_25'
                    else:
                        io = 'LVCMOS25'
                    fo.write(fmt.format(package_pin, io, signal.upper()))


def main():
    p = argparse.ArgumentParser()
    p.add_argument(
        '-i', '--input', help="input fmc map", default='pinmap.txt')
    # G6 FMC1_LA00_CC_P ADC_DCO_N_0
    p.add_argument(
        '-o', '--output', help="output xdc", default='foo.xdc')
    p.add_argument(
        '-c', '--carrier', help="carrier xdc", default='../Marble.xdc')
    args = p.parse_args()

    with open(args.input) as f:
        lines = [line.rstrip() for line in f]
        mezzanine = [x.splitlines()[0].split() for x in lines if x]

    with open(args.output, 'w+') as fo:
        with open(args.carrier) as f:
            lines = [line.rstrip() for line in f]
            carrier_fmc = [x.strip('[]\n').split(' ') for x in lines if x]
            # print(carrier_fmc)
            write_xdc(fo, carrier_fmc, mezzanine)


if __name__ == "__main__":
    main()
