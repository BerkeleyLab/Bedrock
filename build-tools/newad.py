#!/usr/bin/python

# Barest working skeleton of an automatic Verilog module port connector
# Larry Doolittle, LBNL, 2014
# TODO:
# * Mirror read and write clk is currently hard-coded to lb_clk
# * Remove hierarchy from address_allocation
# * Currently we-strobe is being abused to generate registers of width > 1
# * Can we do a quick search in the string before a full re match in parse_vfile?

import argparse
import json
import re
from os.path import dirname, basename, isfile
from copy import deepcopy
try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO

MIN_MIRROR_AW = 5
MIN_MIRROR_ARRAY_SIZE = 1 << MIN_MIRROR_AW  # Minimum size of an array to be mirrored
port_lists = {}  # module_name: [list of ports]
self_ports = []
decodes = []
use_ram = {}  # module_name : variable
self_map = {}
gch = {}
g_flat_addr_map = {}
g_clk_domains = {}
file_not_found = 0


class Port:
    def __init__(self,
                 name,
                 downto,
                 direction,
                 sign,
                 module,
                 signal_type,
                 clk_domain='lb',
                 cd_indexed=False,
                 description=''):
        self.name = name
        self.downto = downto
        self.direction = direction
        self.sign = sign
        self.module = module
        self.signal_type = signal_type
        self.clk_domain = clk_domain
        self.cd_indexed = cd_indexed
        self.cd_index = None
        self.description = description

    def port_prefix_set(self, prefix):
        self.name = prefix + self.name
        return self

    def __repr__(self):
        s = self.direction
        s += ' signed' if self.sign else ' unsigned'
        s += ' [{}:{}]'.format(*self.downto)
        s += ' ' + self.name
        s += ' //module:{}; clk_domain:{}; index:{}'.format(
            self.module, self.clk_domain, self.cd_index)
        return s


def consider_port(p, fd):
    # 5-element list is (input/output) (signed/None) lsb msb name
    if p.direction == 'output':
        # TODO: Another idiosyncracy, moved to an attribute as per new spec
        bp = re.sub('_addr$', '', p.name)
        fd.write('// found output address in module %s, base=%s\n' % (p.module,
                                                                      bp))
        use_ram[p.module + ':' + bp] = '[%s:%s]' % p.downto


def range_width(r):
    '''
    A utility function: string [a:b] => integer a-b+1
    '''
    r2 = re.sub(r'\]', '', re.sub(r'\[', '', r))
    nums = r2.split(':')
    return int(nums[0]) - int(nums[1]) + 1


def use_ram_key(mod, name):
    var = name.split(':')[-1]
    return mod + ':' + var


def make_decoder_inner(inst, mod, p):
    '''
    Constructs a decoder for a port p.
    p: is an instance of Port
    # TODO: clarify what different signal_types are exactly
    '''
    # print '// make_decoder',inst,mod,a
    if p.direction != 'output':
        # print '// make_decoder instance=%s name=%s'%(inst,a[5])
        clk_prefix = p.clk_domain
        cd_index_str = ''
        if p.cd_indexed and p.cd_index is not None:
            cd_index_str = '[%d]' % p.cd_index
        key = use_ram_key(p.module, p.name)
        # print '// checking use_ram for key '+key
        if inst is None:
            sig_name = re.sub(':', '_', p.name)
        else:
            sig_name = '%s_%s' % (inst, re.sub(':', '_', p.name))
        decode_def = 'wire we_%s = %s_write%s&(`ADDR_HIT_%s);\\\n' %\
                     (sig_name, clk_prefix, cd_index_str, sig_name)
        msb = int(p.downto[0])
        lsb = int(p.downto[1])
        data_width = msb - lsb + 1
        sign = p.sign if p.sign else 'unsigned'
        if key in use_ram:
            addr_range = use_ram[key]
            data_range = '[%d:%d]' % (msb, lsb)
            addr_width = range_width(addr_range)
            # print '// ***** use_ram %s %s'%(key,use_ram[key]), addr_range,
            # addr_width, data_range, data_width
            wire_def = 'wire %s %s_addr;\\\nwire %s %s;\\\n' %\
                       (addr_range, sig_name, data_range, sig_name)
            dpram_a = '.clka(%s_clk), .addra(%s_addr%s%s), .dina(%s_data%s%s),'\
                      ' .wena(we_%s)' % \
                      (clk_prefix, clk_prefix, cd_index_str, addr_range,
                       clk_prefix, cd_index_str, data_range, sig_name)
            dpram_b = '.clkb(%s_clk), .addrb(%s_addr), .doutb(%s)' %\
                      (clk_prefix, sig_name, sig_name)
            dpram_def = 'dpram #(.aw(%d),.dw(%d)) dp_%s(\\\n\t%s,\\\n\t%s);\\\n' %\
                        (addr_width, data_width, sig_name, dpram_a, dpram_b)
            decodes.append(wire_def + decode_def + dpram_def)
            gch[sig_name] = (addr_width, mod, sign, data_width, clk_prefix,
                             cd_index_str, p.description)
        elif p.signal_type == 'single-cycle':
            reg_def = 'reg [%d:%d] %s=0; always @(posedge %s_clk) '\
                      '%s <= we_%s ? %s_data%s[%d:%d] : %d\'b0;\\\n' %\
                      (msb, lsb, sig_name, clk_prefix, sig_name, sig_name,
                       clk_prefix, cd_index_str, msb, lsb, data_width)
            decodes.append(decode_def + reg_def)
            gch[sig_name] = (0, mod, sign, data_width, clk_prefix,
                             cd_index_str, p.description)
        elif p.signal_type == 'strobe':
            read_strobe = 'wire %s = %s_read & (`ADDR_HIT_%s);\\\n' %\
                          (sig_name, clk_prefix, sig_name)
            decodes.append(read_strobe)
            gch[sig_name] = (0, mod, sign, data_width, clk_prefix,
                             cd_index_str, p.description)
        elif p.signal_type == 'we-strobe':
            reg_def = 'wire %s = we_%s;\\\n' % (sig_name, sig_name)
            decodes.append(decode_def + reg_def)
            gch[sig_name] = (0, mod, sign, data_width, clk_prefix,
                             cd_index_str, p.description)
        elif p.signal_type == 'plus-we-VOID':
            pass
        else:
            if p.signal_type == 'plus-we':
                we_def = 'wire %s_we = we_%s;\\\n' % (sig_name, sig_name)
            else:
                we_def = ''
            reg_def = 'reg [%d:%d] %s=0; always @(posedge %s_clk) '\
                      'if (we_%s) %s <= %s_data%s;\\\n' %\
                      (msb, lsb, sig_name, clk_prefix, sig_name, sig_name,
                       clk_prefix, cd_index_str)
            decodes.append(decode_def + we_def + reg_def)
            gch[sig_name] = (0, mod, sign, data_width, clk_prefix,
                             cd_index_str, p.description)


def make_decoder(inst, mod, a, gcnt):
    if gcnt is None:
        make_decoder_inner(inst, mod, a)
    else:
        for ig in range(gcnt):
            # HACK: side effect; Benign
            # This helps figure out the instantiation in the case of gvar
            if a.cd_indexed:
                a.cd_index = ig
            # print '// make_decoder iteration %d'%ig
            make_decoder_inner('%s_%d' % (inst, ig), mod, a)


def one_port(inst, name, gvar):
    # names are stored in port_lists with : as hierarchy separator
    s = re.sub(':', '_', name)
    # wid = int(msb) - int(lsb) + 1
    # suffix = '' if (gvar is None) else '[%s*%d+%s:%s*%d+%s]'%(gvar, wid, msb, gvar, wid, lsb);
    if gvar is None:
        return '.%s(%s_%s)' % (s, inst, s)
    else:
        return '.%s(%s_array_%s[%s])' % (s, inst, s, gvar)


def print_instance_ports(inst, mod, gvar, gcnt, fd):
    '''
    Print the port assignments for the instantiation of a module.
    At the same time, append to the self_ports and decodes strings,
    so the variables mapped to the ports can get adequately defined.
    '''
    instance_ports = port_lists[mod]
    if fd:
        # 'list comprehension' for the port list itself
        this_list = [one_port(inst, p.name, gvar) for p in instance_ports]
        if this_list:
            tail = ' ' + ',\\\n\t'.join(this_list)
        else:
            tail = ''
        fd.write('`define AUTOMATIC_' + inst + tail)
        fd.write('\n')
    #  now construct the self_ports and decoders (if any)
    for p in instance_ports:
        sig = '' if (p.sign is None) else p.sign  # signed flag
        if gvar is None:
            self_ports.append('%s %s [%s:%s] %s_%s' %
                              (p.direction, sig, p.downto[0], p.downto[1],
                               inst, re.sub(':', '_', p.name)))
        else:
            for ig in range(gcnt):
                self_ports.append('%s %s [%s:%s] %s_%d_%s' %
                                  (p.direction, sig, p.downto[0], p.downto[1],
                                   inst, ig, re.sub(':', '_', p.name)))
        make_decoder(inst, mod, p, gcnt)


def construct_map(inst, p, gcnt, mod):
    sig = '' if (p.sign is None) else p.sign
    msb = int(p.downto[0])
    lsb = int(p.downto[1])
    # wid = msb-lsb+1
    name = re.sub(':', '_', p.name)
    # print '// construct_map',sig,msb,lsb,inst,name,gcnt, mod
    self_map[mod].append('wire %s [%d:%d] %s_array_%s [0:%d];' %
                         (sig, msb, lsb, inst, name, gcnt - 1))
    for ig in range(gcnt):
        array_el = '%s_array_%s[%d]' % (inst, name, ig)
        expanded = '%s_%d_%s' % (inst, ig, name)
        if p.direction == 'input':
            self_map[mod].append('assign %s = %s;\\\n' % (array_el, expanded))
        elif p.direction == 'output':
            self_map[mod].append('assign %s = %s;\\\n' % (expanded, array_el))


from v2j import v2j
from read_attributes import read_attributes


# TODO: Refactor filepath

def parse_vfile_yosys(stack, fin, fd, dlist, clk_domain, cd_indexed):
    '''
    Given a filename, parse Verilog:
    (a) looking for module instantiations marked automatic,
    for which we need to generate port assignments.
    When such an instantiation is found, recurse.
    (b) looking for input/output ports labeled 'external'.
    Record them in the port_lists dictionary for this module.
    '''
    # TODO: Take care of top-level
    # TODO: Old newad doesn't really take care of the case where
    #       there are multiple modules in a single file, as there is no check
    #       for module declaration per se, also doesn't support other fancy
    #       declarations like "input [15:0] a, b,".
    fd.write('// parse_vfile_yosys %s %s\n' % (stack, fin))
    searchpath = dirname(fin)
    fname = basename(fin)
    if not isfile(fin):
        for d in dlist:
            x = d + '/' + fname
            if isfile(x):
                fin = x
                break
    if not isfile(fin):
        print("File not found:", fin)
        print("(from hierarchy %s)" % stack)
        global file_not_found
        file_not_found += 1
        return
    if searchpath == '':
        searchpath = '.'
    this_mod = fin.split('/')[-1].split('.')[0]

    parsed_mod = read_attributes(v2j(fin))
    this_port_list = []
    attributes = {}
    for inst, mod_info in parsed_mod['automatic_cells'].items():
        # print(inst, mod_info)
        mod_attrs = mod_info['attributes']
        mod = mod_info['type']
        clk_domain_l = mod_attrs['cd'] if 'cd' in mod_attrs else clk_domain  # Assume same cd unless specified
        cd_indexed_l = True if 'cd_index' in mod_attrs else cd_indexed
        gvar = mod_attrs['gvar'] if 'gvar' in mod_attrs else None
        gcnt = int(mod_attrs['gcnt'], 2) if 'gcnt' in mod_attrs else None

        if gvar is not None:
            # When the instantiation is inside a genvar, yosys_json already unrolls the loop and creates
            # a cell per iteration
            inst_name_info = inst.split('.')
            inst = inst_name_info[1]
            ig = int(inst_name_info[0].split('[')[1][0])  # TODO: This is a total hack to maintain old newad API

        # TODO: Look for CD attribute
        fd.write('// module=%s instance=%s gvar=%s gcnt=%s\n' %
                 (mod, inst, gvar, str(gcnt)))
        if mod not in port_lists:
            # recurse
            parse_vfile_yosys(stack + ':' + fin,
                              searchpath + '/' + mod + '.v',
                              fd, dlist, clk_domain_l, cd_indexed_l)
        if not stack:
            if gvar is None or ig == 0:
                print_instance_ports(inst, mod, gvar, gcnt, fd)

        # add this instance's external ports to our own port list
        for p in port_lists[mod] if mod in port_lists else []:
            if gcnt is None:
                p_p = deepcopy(p)  # p_prime
                this_port_list.append(p_p.port_prefix_set(inst + ':'))
            else:
                p_p = deepcopy(p)  # p_prime
                p_p = p_p.port_prefix_set('{}_{}:'.format(inst, ig))
                if cd_indexed_l:
                    p_p.cd_index = ig  # TODO: to be fixed
                this_port_list.append(p_p)
                if ig == 0:
                    if this_mod not in self_map:
                        self_map[this_mod] = []
                    construct_map(inst, p, gcnt, this_mod)

    for port, (net_info, port_info) in parsed_mod['external_nets'].items():
        signal_type = net_info['attributes']['signal_type'] if 'signal_type' in net_info['attributes'] else None
        signed = 'signed' if 'signed' in port_info else None
        p = Port(port,
                 # TODO: This is a hack needs to be fixed
                 (len(net_info['bits']) - 1, 0),
                 port_info['direction'],
                 signed,
                 this_mod,
                 signal_type,
                 clk_domain,
                 cd_indexed,
                 **attributes)
        this_port_list.append(p)
        consider_port(p, fd)
        if signal_type == 'plus-we':
            p = Port(port + '_we',
                     (0, 0),
                     port_info['direction'],
                     None,
                     this_mod,
                     'plus-we-VOID',
                     clk_domain,
                     cd_indexed,
                     **attributes)
            this_port_list.append(p)
            consider_port(p, fd)
        attributes = {}

    port_lists[this_mod] = this_port_list


INSTANTIATION_SITE = r'^\s*(\w+)\s+(#\(.*\) *)?(\w+)\s*//\s*auto(\(\w+,\d+\))?\s+((\w+)(\[(\w+)\])?)?'
# Search for port with register width defined 'input (signed)? [%d:%d] name // <...>'
PORT_WIDTH_MULTI = r'^\s*,?(input|output)\s+(signed)?\s*\[(\d+):(\d+)\]\s*(\w+),?\s*'
PORT_WIDTH_MULTI += r'//\s*external\s*(single-cycle|strobe|we-strobe|plus-we)?'
# Search for port with register width 1 'input (signed)? name // <...>'
PORT_WIDTH_SINGLE = r'^\s*,?(input|output)\s+(signed)?\s*(\w+),?\s*//\s*external\s*(single-cycle|strobe|we-strobe)?'
TOP_LEVEL_REG = r'^\s*//\s*reg\s+(signed)?\s*\[(\d+):(\d+)\]\s*(\w+)\s*;\s*top-level\s*(single-cycle|strobe|we-strobe)?'
DESCRIPTION_ATTRIBUTE = r'^\s*\(\*\s*BIDS_description\s*=\s*\"(.+?)\"\s*\*\)\s*$'


def parse_vfile_comments(stack, fin, fd, dlist, clk_domain, cd_indexed):
    '''
    Given a filename, parse Verilog:
    (a) looking for module instantiations marked automatic,
    for which we need to generate port assignments.
    When such an instantiation is found, recurse.
    (b) looking for input/output ports labeled 'external'.
    Record them in the port_lists dictionary for this module.
    '''
    fd.write('// parse_vfile_comments %s %s\n' % (stack, fin))
    searchpath = dirname(fin)
    fname = basename(fin)
    if not isfile(fin):
        for d in dlist:
            x = d + '/' + fname
            if isfile(x):
                fin = x
                break
    if not isfile(fin):
        print("File not found:", fin)
        print("(from hierarchy %s)" % stack)
        global file_not_found
        file_not_found += 1
        return
    if searchpath == '':
        searchpath = '.'
    this_mod = fin.split('/')[-1].split('.')[0]
    verilog_file_lines = []
    # Looks like the reason we read the whole file is to avoid opening
    # several files at the same time
    with open(fin, 'r') as f:
        verilog_file_lines = f.readlines()
    this_port_list = []
    attributes = {}
    for l in verilog_file_lines:
        # Search for attributes
        m = re.search(DESCRIPTION_ATTRIBUTE, l)
        if m:
            value = m.group(1)
            attributes['description'] = value
        # (a) instantiations
        m = re.search(INSTANTIATION_SITE, l)
        if m:
            mod = m.group(1)
            inst = m.group(3)
            gspec = m.group(4)
            clk_domain_l = clk_domain
            cd_indexed_l = cd_indexed
            if m.group(6) is not None:
                clk_domain_l = m.group(6)
                if m.group(8) is not None:
                    cd_indexed_l = True
            if gspec is not None:
                mm = re.search(r'\((\w+),(\d+)\)', gspec)
                gvar = mm.group(1)
                gcnt = int(mm.group(2))
            else:
                gvar = None
                gcnt = None
            fd.write('// module=%s instance=%s gvar=%s gcnt=%s\n' %
                     (mod, inst, gvar, str(gcnt)))
            if mod not in port_lists:
                # recurse
                parse_vfile_comments(stack + ':' + fin, searchpath + '/' + mod + '.v',
                                     fd, dlist, clk_domain_l, cd_indexed_l)
            if not stack:
                print_instance_ports(inst, mod, gvar, gcnt, fd)
            # add this instance's ports to our own port list
            for p in port_lists[mod] if mod in port_lists else []:
                if gcnt is None:
                    p_p = deepcopy(p)  # p_prime
                    this_port_list.append(p_p.port_prefix_set(inst + ':'))
                else:
                    print(p, inst)
                    for ig in range(gcnt):
                        p_p = deepcopy(p)  # p_prime
                        p_p = p_p.port_prefix_set('%s_%d:' % (inst, ig))
                        if cd_indexed_l and m.group(6) is not None:
                            p_p.cd_index = ig
                        this_port_list.append(p_p)
                    if this_mod not in self_map:
                        self_map[this_mod] = []
                    construct_map(inst, p, gcnt, this_mod)
        # (b) ports
        # Search for port with register width defined 'input (signed)? [%d:%d] name // <...>'
        m = re.search(PORT_WIDTH_MULTI, l)
        if m:
            info = [m.group(i) for i in range(7)]
            p = Port(info[5], (info[3], info[4]), info[1], info[2], this_mod,
                     info[6], clk_domain, cd_indexed, **attributes)
            this_port_list.append(p)
            consider_port(p, fd)
            if info[6] == 'plus-we':
                p = Port(info[5] + '_we', (0, 0), info[1], None, this_mod,
                         info[6] + '-VOID', clk_domain, cd_indexed,
                         **attributes)
                this_port_list.append(p)
                consider_port(p, fd)
            attributes = {}
        else:
            m = re.search(PORT_WIDTH_SINGLE, l)
            if m:
                info = [m.group(i) for i in range(5)]
                p = Port(info[3], (0, 0), info[1], info[2], this_mod, info[4],
                         clk_domain, cd_indexed, **attributes)
                this_port_list.append(p)
                consider_port(p, fd)
                attributes = {}

        # (c) registers in the top-level file
        if not stack:
            m = re.search(TOP_LEVEL_REG, l)
            if m:
                info = [m.group(i) for i in range(6)]
                p = Port(info[4], (info[2], info[3]), 'top_level', info[1],
                         this_mod, info[5], clk_domain, cd_indexed,
                         **attributes)
                this_port_list.append(p)
                # Since these are top level registers, decoders can be generated here
                make_decoder(None, this_mod, p, None)
                attributes = {}
    # print '// debug',this_mod,this_port_list
    port_lists[this_mod] = this_port_list


def generate_mirror(dw, mirror_n):
    '''
    Generates a dpram which mirrors the register values being written into the
    automatically generated addresses.
    dw, aw: data/address width of the ram
    mirror_base:
    mirror_n: A unique identifier for the mirror dpram
    '''
    # HACK: HARD coding clk_prefix to be 'lb'
    cp = 'lb'
    mirror_strobe = 'wire [%d:0] mirror_out_%d;'\
                    'wire mirror_write_%d = %s_write &(`ADDR_HIT_MIRROR);\\\n' %\
                    (dw-1, mirror_n, mirror_n, cp)
    dpram_a = '.clka(%s_clk), .addra(%s_addr[`MIRROR_WIDTH-1:0]), '\
              '.dina(%s_data[%d:0]), .wena(mirror_write_%d)' %\
              (cp, cp, cp, dw-1, mirror_n)
    dpram_b = '.clkb(%s_clk), .addrb(%s_addr[`MIRROR_WIDTH-1:0]), .doutb(mirror_out_%d)' %\
              (cp, cp, mirror_n)
    dpram_def = 'dpram #(.aw(`MIRROR_WIDTH),.dw(%d)) mirror_%d(\\\n\t%s,\\\n\t%s);\\\n' %\
                (dw, mirror_n, dpram_a, dpram_b)
    return mirror_strobe + dpram_def


def add_to_global_map(name, base_addr, sign, aw, dw, description):
    if name in g_flat_addr_map:
        x = g_flat_addr_map[name]
        assert x['base_addr'] == base_addr
    g_flat_addr_map[name] = {
        'base_addr': base_addr,
        'sign': sign,
        'access': 'rw' if aw <= MIN_MIRROR_AW else 'w',
        'addr_width': aw,
        'data_width': dw,
        'description': description
    }


def generate_addresses(fd,
                       names,
                       base,
                       low_res=False,
                       gen_mirror=False,
                       plot_map=False):
    '''
    Generate addresses with increasing bitwidth
    '''
    not_mirrored, mirrored = [], []
    mirror_base = -1
    register_names = sorted(names, key=lambda x: gch.get(x)[0], reverse=True)
    if gen_mirror:
        mirror_size = sum([
            1 << gch[k][0] for k in register_names
            if (1 << gch[k][0]) <= MIN_MIRROR_ARRAY_SIZE
        ])
    for k in register_names:
        bitwidth = gch[k][0]
        register_array_size = 1 << gch[k][0]
        if (gen_mirror and mirror_base == -1 and register_array_size <= MIN_MIRROR_ARRAY_SIZE and fd):
            mirror_base = base
            mirror_bit_len = mirror_size.bit_length()
            mirror_size_nearest_pow2 = 1 << mirror_bit_len
            if mirror_base & (mirror_size_nearest_pow2 - 1) != 0:
                print(
                    'Mirror base NOT aligned.\nMirror Base: {};\nMirror Size: {};'.
                    format(format(base, '#x'), format(mirror_size, '#x')))
                mirror_base = ((mirror_base + mirror_size_nearest_pow2) >>
                               mirror_bit_len) << mirror_bit_len
                base = mirror_base
                print('Aligning mirror base. New mirror base: {}'.format(
                    format(base, '#x')))
            mirror_clk_prefix = 'lb'  # TODO: This is a hack
            s = '`define MIRROR_WIDTH %d\n'\
                '`define ADDR_HIT_MIRROR (%s_addr[`LB_HI:`MIRROR_WIDTH]==%d)\n' %\
                (mirror_bit_len, mirror_clk_prefix, mirror_base >> mirror_bit_len)
            fd.write(s)
        sign = gch[k][2]
        datawidth = gch[k][3]
        description = gch[k][-1]
        k_aw = 1 << bitwidth  # address width of register name k
        if (k_aw - 1) & base == 0:
            next_addr = base
        else:
            # A way to come up with the next available address
            next_addr = ((base + k_aw) >> bitwidth) << bitwidth
        if bitwidth > 0 and not low_res:
            for reg_index in range(k_aw):
                r_name = k + '_' + str(reg_index)
                add_to_global_map(r_name, next_addr + reg_index, sign,
                                  bitwidth, datawidth, description)
        else:
            add_to_global_map(k, next_addr, sign, bitwidth, datawidth,
                              description)
        if fd:
            s = '`define ADDR_HIT_%s (%s_addr%s[`LB_HI:%d]==%d) '\
                '// %s bitwidth: %d, base_addr: %d\n'
            fd.write(s %
                     (k, gch[k][4], gch[k][5], bitwidth, next_addr >> bitwidth,
                      gch[k][1], bitwidth, next_addr))
        (not_mirrored
         if mirror_base == -1 else mirrored).append((next_addr, k_aw))
        base = next_addr + k_aw
    if plot_map and (mirrored or not_mirrored):
        from matplotlib import pyplot as plt
        import matplotlib.ticker as ticker
        if not_mirrored:
            plt.broken_barh(not_mirrored, (0, 1))
        if mirrored:
            plt.broken_barh(mirrored, (0, 1), facecolors=('red'))
        axes = plt.gca()
        axes.get_xaxis().set_major_formatter(ticker.FormatStrFormatter("%#x"))
        plt.show()
    return base


g_hierarchy = ['xxxx', 'station', 'cav4_elec', ['mode_', 3]]


def address_allocation(fd,
                       hierarchy,
                       names,
                       address,
                       low_res=False,
                       gen_mirror=False,
                       plot_map=False):
    '''
    NOTE: The whole hierarchy thing is currently being bypassed
    TODO: Possibly remove hierarchy from here, or even make it optional
    hierarchy: Index into g_hierarchy (current hierarchy level)
    names: All signal names that belong in the current hierarchy
    address:
    for current index in g_hierarchy denoted with variable 'hierarchy'
    1. partition 'names' that belong inside vs outside the hierarchy
    2. (a) generate addresses for names (in_mod) that fall in the hierarchy
    (recurse)
    (b) generate addresses for signals outside the hierarchy (out_mod)
    '''
    if hierarchy == len(g_hierarchy):
        return generate_addresses(fd, names, address, low_res, gen_mirror,
                                  plot_map)
    h = g_hierarchy[hierarchy]
    in_mod, out_mod = [], []
    if type(h) is list:
        prefix = h[0]
        for hn in range(h[1]):
            hh = prefix + str(hn)
            address = address_allocation(
                fd, hierarchy + 1, [n for n in names if hh in n], address,
                low_res, gen_mirror, plot_map)
        out_mod = [n for n in names if prefix not in n]
    else:
        for n in names:
            (in_mod if h in n else out_mod).append(n)
        address = address_allocation(fd, hierarchy + 1, in_mod, address,
                                     low_res, gen_mirror, plot_map)
    return generate_addresses(fd, out_mod, address, low_res, gen_mirror,
                              plot_map)


def print_decode_header(fi, modname, fo, dir_list, lb_width, gen_mirror, use_yosys):
    obuf = StringIO()
    if use_yosys:
        parse_vfile_yosys('', fi, obuf, dir_list, 'lb', False)
    else:
        parse_vfile_comments('', fi, obuf, dir_list, 'lb', False)
    obuf.write('// machine-generated by newad.py\n')
    obuf.write('`ifdef LB_DECODE_%s\n' % modname)
    obuf.write('`include \"addr_map_%s.vh\"\n' % modname)
    # TODO: Merging clock domains: This doesn't need to be there?
    # needed for at least some test benches, like in rtsim
    clk_prefix = "lb"
    obuf.write('`define AUTOMATIC_self input %s_clk, input [31:0] %s_data,'
               ' input %s_write, input [%d:0] %s_addr\n' %
               (clk_prefix, clk_prefix, clk_prefix, lb_width, clk_prefix))
    obuf.write('`define AUTOMATIC_decode\\\n' + ''.join(decodes))
    if gen_mirror:
        obuf.write(generate_mirror(32, 0))
    obuf.write('\n')
    obuf.write('`else\n')
    obuf.write('`define AUTOMATIC_self' + ' ' + ',\\\n'.join(self_ports))
    obuf.write('\n')
    obuf.write('`define AUTOMATIC_decode\n')
    obuf.write('`endif\n')
    # Below only applies for modules with genvar constructions
    if modname in self_map:
        obuf.write('`define AUTOMATIC_map ' + ' '.join(
            self_map[modname] if modname in self_map else []) + '\n')
    if fo:
        with open(fo, 'w') as fd:
            fd.write(obuf.getvalue())
    obuf.close()


def write_address_header(fi, fo, low_res, lb_width, gen_mirror, base_addr,
                         plot_map):
    addr_bufs = StringIO()
    addr_bufs.write('`define LB_HI %d\n' % lb_width)
    address_allocation(addr_bufs, 0, sorted(gch.keys()), base_addr, low_res,
                       gen_mirror, plot_map)
    with open(fo, 'w') as fd:
        fd.write(addr_bufs.getvalue())
    addr_bufs.close()


def write_regmap_file(fi, fo, low_res, base_addr, plot_map):
    address_allocation(
        0,
        0,
        sorted(gch.keys()),
        base_addr,
        low_res=low_res,
        plot_map=plot_map)
    addr_map = {x: g_flat_addr_map[x] for x in g_flat_addr_map}
    with open(fo, 'w') as fd:
        json.dump(
            addr_map, fd, sort_keys=True, indent=4, separators=(',', ': '))
        fd.write('\n')


def main(argv):
    def auto_int(x):
        return int(x, 0)

    parser = argparse.ArgumentParser(
        description='Automatic address generator: Parses verilog lines '
        'and generates addresses and decoders for registers declared '
        'external across module instantiations')
    parser.add_argument(
        '-i',
        '--input_file',
        default='',
        help='A top level file to start the parser')
    parser.add_argument(
        '-o', '--output', default='', help='Outputs generated header file')
    parser.add_argument(
        '-d',
        '--dir_list',
        default='.',
        type=str,
        help='A list of directories to look for verilog source files. <dir_0>[,<dir_1>]*'
    )
    parser.add_argument(
        '-a',
        '--addr_map_header',
        default='',
        help='Outputs generated address map header file')
    parser.add_argument(
        '-r',
        '--regmap',
        default='',
        help='Outputs generated address map in json format')
    parser.add_argument(
        '-y',
        '--yosys',
        action='store_true',
        help='Use yosys for backend, as opposed to poor mans parsing')
    parser.add_argument(
        '-l',
        '--low_res',
        action='store_true',
        help='When not selected generates a seperate address name for each')
    parser.add_argument(
        '-m',
        '--gen_mirror',
        action='store_true',
        help='Generates a mirror where all registers and register arrays with size < {}'
        'are available for readback'.format(MIN_MIRROR_ARRAY_SIZE))
    parser.add_argument(
        '-pl',
        '--plot_map',
        action='store_true',
        help='Plots the register map using a broken bar graph')
    parser.add_argument(
        '-w',
        '--lb_width',
        type=auto_int,
        default=10,
        help='Set the address width of the local bus from which the generated registers are decoded'
    )
    parser.add_argument(
        '-b',
        '--base_addr',
        type=auto_int,
        default=0,
        help='Set the base address of the register map to be generated from here')
    parser.add_argument(
        '-p',
        '--clk_prefix',
        default='lb',
        help='Prefix of the clock domain in which decoding is done [currently ignored], appends _clk'
    )
    args = parser.parse_args()

    input_fname = args.input_file
    modname = input_fname.split('/')[-1].split('.')[0]
    dir_list = list(map(lambda x: x.strip(), args.dir_list.split(',')))
    addr_header_fname = args.addr_map_header
    regmap_fname = args.regmap

    print_decode_header(input_fname, modname, args.output, dir_list,
                        args.lb_width, args.gen_mirror, args.yosys)

    if addr_header_fname:
        write_address_header(input_fname, addr_header_fname, args.low_res,
                             args.lb_width, args.gen_mirror, args.base_addr,
                             args.plot_map)
    if regmap_fname:
        write_regmap_file(input_fname, regmap_fname, args.low_res,
                          args.base_addr, args.plot_map)


if __name__ == '__main__':
    import sys
    main(sys.argv[1:])
    if file_not_found > 0:
        print(file_not_found, "files not found")
        exit(1)
