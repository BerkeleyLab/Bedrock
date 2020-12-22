import argparse

fpga_pin_to_fmc = {}
fmc_name_to_zest = {}
fmc_grid_to_name = {}
application_top_to_iostandard = {}


def mapin(fname, fmc_prefix):
    for ll in open(fname).read().splitlines():
        ll = ll.strip().split()
        if len(ll) == 3:
            fmc_name, fpga_pin, fmc_grid = ll
        elif len(ll) == 2:
            fmc_name, fpga_pin = ll
        fmc = fmc_prefix + fmc_name
        if "LA" in fmc:
            fpga_pin_to_fmc[fpga_pin] = fmc
        if len(ll) == 3:
            fmc_grid_to_name[fmc_grid] = fmc_name


def gen_map(prefix="../../.."):
    mapin(prefix + "/board_support/bmb7_kintex/fmc-lpc.lst", "FMC1_")
    mapin(prefix + "/board_support/bmb7_kintex/fmc-hpc.lst", "FMC2_")


def fmc_name_mangle(name):
    '''
    This function mangles the FMC names that respect the standard to
    names that don't for the sake of currently solving the problem.
    TODO: Fixing above requires modifying meta-xdc.py?
    '''
    return name.replace('LA0', 'LA').replace('LA', 'LA_').replace('_CC', '')


def cycle_xdc(fname):
    for ll in open(fname).read().splitlines():
        if len(ll) == 0 or ll[0] == "#":
            print(ll)
            pass
        elif "digitizer" in ll:
            a = ll.split()
            v_name = a[4]
            if v_name[-1] == "]":
                v_name = v_name[:-1]
            v_name = v_name.strip("{}")
            if a[1] == "IOSTANDARD":
                application_top_to_iostandard[v_name] = a[2]
            if a[1] == "PACKAGE_PIN":
                io_std = application_top_to_iostandard[v_name]
                fmc_name = fpga_pin_to_fmc[a[2]]
                # zest_name = fmc_name_to_zest[fmc_name]
                # print(" ".join([v_name, io_std, a[2], fmc_name, zest_name]))
                suffix = " DIFF" if "LVDS" in io_std else ""
                print(" ".join([fmc_name_mangle(fmc_name), v_name]) + suffix)
                if False:
                    a[2] = fpga_pin_to_fmc[a[2]]
                    fix = " ".join(a)
                    print(fix)
            else:
                # print(ll)
                pass


def zest_in(fname):
    for ll in open(fname).read().splitlines():
        a = ll.split()
        p = a[0][1]
        if a[1] in fmc_grid_to_name:
            fmc_sub = fmc_grid_to_name[a[1]]
            fmc_name = "FMC%s_%s" % (p, fmc_sub)
            fmc_name_to_zest[fmc_name] = a[2]
            # print(fmc_name, a[2])
        else:
            pass
            # print("ignoring zest %s" % ll)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Remap FMC PINs for generating constraints')
    parser.add_argument('-p', '--prefix', default='../../..', help='bedrock_dir path')
    args = parser.parse_args()
    gen_map(args.prefix)
    zest_in(args.prefix + "/board_support/zest/digitizer_digital_pin.txt")
    if False:
        for a in sorted(fpga_pin_to_fmc.keys()):
            print("%s: %s" % (a, fpga_pin_to_fmc[a]))
    cycle_xdc(args.prefix + "/projects/oscope/bmb7_cu/oscope_common.xdc")
