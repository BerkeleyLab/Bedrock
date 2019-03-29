import argparse
import re


def write_xdc(fo, vc707, fmc120, ix):
    for d in vc707:
        for s in fmc120:
            av57 = s[0]
            signal = s[2]
            inst = '_' + str(ix-1)
            if 'FMC' + str(ix) + '_HPC_' + av57 == d[4] and signal != 'NC':
                p_d = re.compile(r'\[\d\]')
                if p_d.search(signal):
                    index = p_d.search(signal).group()[1]
                    ss = signal.split('[')[0] + inst + '[' + index + ']'
                else:
                    ss = signal + inst
                if ss:
                    fo.write('set_property PACKAGE_PIN {:s} [get_ports {:s}]\n'.format(d[2], ss))


def main():
    p = argparse.ArgumentParser()
    p.add_argument(
        '-i', '--input', help="input fmc map file", default='pinmap.txt')
    p.add_argument(
        '-o', '--output', help="output xdc file", default='foo.xdc')
    p.add_argument(
        '-c', '--carrier', help="carrier xdc file", default='../vc707/fmc-dp.xdc')
    p.add_argument(
        '--fmc1', help="on site fmc1", action="store_true", default=False)
    p.add_argument(
        '--fmc2', help="on site fmc2", action="store_true", default=False)
    args = p.parse_args()

    with open(args.input) as f:
        lines = [line.rstrip() for line in f]
        fmc120 = [x.splitlines()[0].split() for x in lines if x]

    with open(args.output, 'w+') as fo:
        with open(args.carrier) as f:
            lines = [line.rstrip() for line in f]
            vc707_fmc = [x.strip('[]\n').split(' ') for x in lines if x]
            if args.fmc1:
                write_xdc(fo, vc707_fmc, fmc120, 1)
            if args.fmc2:
                write_xdc(fo, vc707_fmc, fmc120, 2)


if __name__ == "__main__":
    main()
