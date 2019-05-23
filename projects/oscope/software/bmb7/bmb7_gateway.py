#!/usr/bin/python
from llrf_bmb7 import c_llrf_bmb7
import argparse


def bmb7_gateway_run(nv_pairs,
                     ip='192.168.165.44',
                     port=50006,
                     regmappath="../regmap_resonance_control.json",
                     use_spartan=False,
                     filewritepath=None):

    bmb7_c = c_llrf_bmb7(
        ip,
        port,
        regmappath=regmappath,
        bitfilepath=None,
        reset=False,
        clk_freq=1320e6 / 14.0,
        use_spartan=use_spartan,
        filewritepath=filewritepath)

    print(bmb7_c.query_resp_list(nv_pairs))


def nv_pair(s):
    try:
        nv_pair = s.split(',')
        if len(nv_pair) == 2:
            n = nv_pair[0].strip()
            v = int(nv_pair[1], 0)
            return n, v
        elif len(nv_pair) == 1:
            n = nv_pair[0].strip()
            return n
        else:
            raise Exception
    except Exception:
        raise argparse.ArgumentTypeError('<string> <,int>?')


def usage():
    print("python bmb7_gateway.py -a 192.168.1.127 regname, 28")


if __name__ == "__main__":

    filewritepath = None
    use_spartan = False

    parser = argparse.ArgumentParser(description='Read/Write from FPGA memory')
    parser.add_argument(
        '--nvs',
        help='[<Name> <,Value>?]*',
        dest='nv_pairs',
        type=nv_pair,
        metavar='N[,V]?',
        nargs='+')
    parser.add_argument(
        '-a',
        '--ip',
        help='ip_address',
        dest='ip',
        type=str,
        default='192.168.165.44')
    parser.add_argument(
        '-p', '--port', help='port', dest='port', type=int, default=50006)
    parser.add_argument(
        '-f',
        '--file',
        help='register map',
        dest='regmappath',
        type=str,
        default="../regmap_resonance_control.json")
    parser.add_argument(
        "-w", "--filewritepath", help="Directory to write files to")
    parser.add_argument(
        "-u",
        "--usespartan",
        help="Flag sets use_spartan flag to True",
        action="store_true")
    args = parser.parse_args()

    if args.filewritepath:
        filewritepath = args.filewritepath
    if args.usespartan:
        use_spartan = True

    bmb7_gateway_run(
        nv_pairs=args.nv_pairs,
        ip=args.ip,
        port=args.port,
        regmappath=args.regmappath,
        use_spartan=use_spartan,
        filewritepath=filewritepath)
