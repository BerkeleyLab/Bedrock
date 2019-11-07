import numpy as np
import argparse

VLOG_DATA_STR = "%(idx)s: data = %(wi)s\'b%(data)s;\n"


def vlog_rom(fname, data, word_wi):
    with open(fname, "w") as FH:
        for i, d in enumerate(data):
            FH.write(VLOG_DATA_STR % ({"idx": i, "wi": word_wi, "data": d}))
        FH.write(VLOG_DATA_STR % ({"idx": "default", "wi": word_wi, "data": str(0)}))
    print("Wrote %s" % fname)


def lo_gen(amp=1.0, ph_step="14/33", n_bits=18):
    ph_step = ph_step.split('/')
    frac_per = int(ph_step[0])
    full_per = int(ph_step[1])

    sin_lut = []
    cos_lut = []
    for i in range(full_per):
        sin_x = amp*np.sin(2*np.pi*(float(frac_per)/float(full_per))*i)
        cos_x = amp*np.cos(2*np.pi*(float(frac_per)/float(full_per))*i)

        # To signed binary
        sin_x = np.binary_repr(int(sin_x), width=n_bits)
        cos_x = np.binary_repr(int(cos_x), width=n_bits)

        sin_lut.append(sin_x)
        cos_lut.append(cos_x)

    return sin_lut, cos_lut


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate a sin/cos look-up-table (LUT)')
    parser.add_argument('-a', '--amp', type=float, default=131071.1, #  2**17-1
                        help='LO amplitude')
    parser.add_argument('-p', '--ph_step', type=str, default="14/33",
                        help='Phase step as irreducible fraction')
    parser.add_argument('-b', '--bits', type=int, default=18,
                        help='LO word bit width')
    args = parser.parse_args()

    sin_lut, cos_lut = lo_gen(args.amp, args.ph_step, args.bits)

    vlog_rom("sin_lut.vh", sin_lut, args.bits)
    vlog_rom("cos_lut.vh", cos_lut, args.bits)
