"""Analyze Clock-Domain-Crossings (CDC)
"""
# Pretty crude WIP.  Has some "issues".

# Tested Yosys commands to create a compatible json file are
# kept nearby in cdc_snitch_proc.ys.

# See "CDC detection with yosys" #3956
# https://github.com/YosysHQ/yosys/discussions/3956

import json


# This is a lot of globals.
# Maybe a python expert would like to convert this into a class.
xref = {}
driver = {}
driverless = {}
clocks = {}
netnames = {}
magic_list = {}
module_input = {}
active_nets = {}
ok1_count = 0
cdc_count = 0
okx_count = 0
bad_count = 0
MAGIC_CDC = "magic_cdc"  # placeholder for attribute name


def summarize(dom_list):
    aa = {}
    for b in dom_list:
        if b in aa:
            aa[b] += 1
        else:
            aa[b] = 1
    summary = ["%d x %s" % (aa[b], get_clk_name(b)) for b in sorted(aa.keys())]
    return ", ".join(summary)


def check_bit(dout_num, dout_name, clk, magic, inputs, ofile, verbose=True):
    global ok1_count, cdc_count, okx_count, bad_count, active_nets
    dom_in = []
    active_nets = {}
    dout_num = str(dout_num)
    for p in inputs:
        dom_in += list_domains(p)
    for d in dom_in:
        clocks[d] = True
    if all([d == clk for d in dom_in]):
        stat = "OK1"  # all inputs in same domain as the DFF
        ok1_count += 1
        if magic and len(dom_in) > 1:
            print('warning: misplaced CDC attribute on', dout_name)
    elif len(dom_in) == 1:
        if magic:
            # planned, single input, no combinational logic
            stat = "CDC"
            cdc_count += 1
        else:
            # unplanned, single input, no combinational logic, maybe OK
            stat = "OKX"
            okx_count += 1
    else:
        # doesn't matter if they claim CDC or not, it's still bad
        stat = "BAD"  # no way
        bad_count += 1
    mm = "magic" if magic else ""
    clk_name = get_clk_name(clk)
    pl = [stat, mm, dout_num, dout_name, 'clk', clk_name, 'inputs (', summarize(dom_in), ')']
    ofile.write(" ".join(pl) + "\n")
    if verbose and stat == "BAD":
        for ix in sorted(active_nets.keys()):
            px = []
            if ix in driver:
                direct = driver[ix]
                conns = direct['connections']
                type_name = direct['type']
                if "DFF" in type_name:
                    dom = conns['C'][0]
                    dom_name = get_clk_name(dom)
                    px = ["clk", dom_name, "name", netnames[ix]]
            elif ix in module_input:
                # second priority to avoid getting confused by inout
                px = ["modinput", netnames[ix]]
            else:
                px = ["unknown"]
            if px:
                pl = ["  tree", dout_num, "from", str(ix)] + px
                ofile.write(" ".join(pl) + "\n")


def find_dff(mod, ofile):
    for cell in mod['cells'].keys():
        # print(cell)
        # print(mod['cells'][cell])
        c = mod['cells'][cell]
        type_name = c['type']
        # print(cell, type_name)
        if "DFF" in type_name:
            conns = c['connections']
            #
            # C = clock defining output domain
            # Should really check that the port_direction for C is "input",
            # and its list of connections is exactly 1 long.
            if len(conns["C"]) != 1:
                print("warning: multiple clocks", cell)
            clk = conns["C"][0]
            clocks[clk] = True
            #
            # Q = dout used for naming
            # Should really check that the port_direction for Q is "output",
            if len(conns["Q"]) != 1:
                print("warning: multiple clocks", cell)
            dout = conns["Q"][0]  # ditto about multiple Q
            magic = dout in magic_list
            #
            # Treat D, CE, and CLR pins independently.
            # Tacit assumption that the underlying FPGA cells have these features
            # built-in, in a way that can't/won't be messed up by the place&route.
            for conn in conns:
                if c['port_directions'][conn] == 'input' and conn != "C":
                    # print('tracking port', conn, conns[conn])
                    inputs = conns[conn]
                    use_magic = magic and conn == "D"
                    check_bit(dout, netnames[dout]+":"+conn, clk, use_magic, inputs, ofile)
        elif "memwr_v2" in type_name:
            memid = "unknown"
            if "MEMID" in c["parameters"]:
                memid = c["parameters"]["MEMID"][1:]
            # print("debug1", type_name, cell, memid)
            conns = c['connections']
            # for pp in conns.keys():
            #     print("debug2", pp, c["port_directions"][pp], len(conns[pp]))
            clk = conns["CLK"][0]
            # treat each data slice independently
            addrs = conns["ADDR"]
            for ix, din in enumerate(conns["DATA"]):
                inputs = [din] + addrs + [conns["EN"][ix]]
                dout_name = memid + "[%d]" % ix
                # print("debug3", dout_name, inputs)
                # XXX on dout
                check_bit(0, dout_name, clk, False, inputs, ofile)


# recursively calls itself
def list_domains(ix):
    if ix == "1" or ix == "0" or ix == "x" or ix == "z":
        return []  # without complaint, since this is a known case
    if ix in active_nets:  # already got here
        return []
    active_nets[ix] = True
    if ix in module_input:
        # print("module_input", ix)
        # treat each module input as if it were its own clock domain
        return [ix]
    if ix not in driver:
        # print("driverless", ix, netnames[ix])
        driverless[ix] = True
        return []
    direct = driver[ix]
    conns = direct['connections']
    type_name = direct['type']
    # print('list_domains start', ix, type_name)
    if "DFF" in type_name:
        dom = [conns['C'][0]]
    else:
        # couple of list comprehensions
        pd = direct['port_directions']
        l1 = [conn for conn in conns if (pd[conn] == 'input')]
        # print(l1)
        l2 = [conns[conn] for conn in l1]
        c1 = sum(l2, [])
        # print(c1)
        dom = sum([list_domains(cc) for cc in c1], [])
    # print('list_domains done', ix, type_name, dom)
    return dom


def get_clk_name(nbit):
    return netnames.get(nbit, str(nbit))


def index_netnames(mod):
    for nn in mod['netnames'].keys():
        attr = mod['netnames'][nn]['attributes']
        bits = mod['netnames'][nn]['bits']
        if len(bits) == 1:
            netnames[bits[0]] = nn
        else:
            for ix, b in enumerate(bits):
                netnames[b] = nn + ("[%d]" % ix)
        if MAGIC_CDC in attr:
            for b in bits:
                magic_list[b] = True


def index_drivers(mod):
    for cell in mod['cells'].keys():
        c = mod['cells'][cell]
        # type_name = c['type']
        for conn in c['connections'].keys():
            if c['port_directions'][conn] == "output":
                for ix in c['connections'][conn]:
                    # print('connection found', ix, c['type'])
                    if ix in driver:
                        print("colliding drivers for", ix,
                              c['type'], c['attributes'], 'and',
                              driver[ix]['type'], driver[ix]['attributes'])
                    else:
                        driver[ix] = c
    for port in mod['ports'].keys():
        p = mod['ports'][port]
        # print("debug", port, p['direction'])
        if p['direction'] == 'input' or p['direction'] == 'inout':
            for ix in p['bits']:
                module_input[ix] = True


def sift_design(yosys_json, ofile):
    creator = yosys_json['creator']
    print("json from", creator)
    # maybe we should bark if yosys version is less than 0.23
    modules = yosys_json['modules']
    module_set = sorted(list(modules.keys()))
    print("modules:", " ".join(module_set))
    if len(module_set) != 1:
        print('too many modules; try yosys command "flatten -wb <top_module>"')
        return 1
    module1 = modules[module_set[0]]
    index_netnames(module1)
    index_drivers(module1)
    find_dff(module1, ofile)
    return 0


def sift_file(f, ofile, strict=False):
    rc = sift_design(json.load(f), ofile)
    if rc != 0:
        return rc
    if False:
        for b in sorted(driver.keys()):
            print(b, driver[b]['type'])
    if True:
        for b in sorted(driverless.keys()):
            print('driverless', b, netnames[b])
    if False:
        domain_list = sorted(clocks.keys())
        print('clock domains', domain_list)
        for d in domain_list:
            print('net', d, 'name', netnames[d])
    pp = (ok1_count, cdc_count, okx_count, bad_count)
    print("OK1: %d  CDC: %d  OKX: %d  BAD: %d" % pp)
    if bad_count != 0:
        rc = 1
    if strict and okx_count != 0:
        rc = 1
    return rc


if __name__ == "__main__":
    import argparse
    from sys import stdout
    hint = "Looks through a yosys-output json file and categorizes CDCs.\n"
    hint += "Longer documentation in cdc_snitch.md."
    parser = argparse.ArgumentParser(description=__doc__, epilog=hint,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("-o", "--output", dest='ofile', default=None,
                        help="Output file")
    parser.add_argument("--strict", default=False, action="store_true",
                        help="Strict checking: all CDC must be marked")
    parser.add_argument("file", help="json input file, as generated by yosys")
    args = parser.parse_args()
    rc = 1
    if args.ofile is not None:
        ofile = open(args.ofile, "w")
    else:
        ofile = stdout
    with open(args.file, "r") as f:
        rc = sift_file(f, ofile, strict=args.strict)
    exit(rc)
