import re

from copy import deepcopy
from os.path import dirname, basename, splitext, isfile

from v2j import v2j
from read_attributes import read_attributes


class Port:
    def __init__(
        self,
        name,
        downto,
        direction,
        sign,
        module,
        signal_type,
        clk_domain="lb",
        cd_indexed=False,
        needs_declaration=True,
        description="",
    ):
        self.name = name
        self.downto = downto
        self.direction = direction
        self.sign = sign
        self.module = module
        self.signal_type = signal_type
        self.clk_domain = clk_domain
        self.cd_indexed = cd_indexed
        self.cd_index = None
        self.needs_declaration = needs_declaration
        self.description = description

    def port_prefix_set(self, prefix):
        self.name = prefix + self.name
        return self

    def __repr__(self):
        s = self.direction
        s += " signed" if self.sign else " unsigned"
        s += " [{}:{}]".format(*self.downto)
        s += " " + self.name
        s += " // module:{}; clk_domain:{}; index:{}".format(
            self.module, self.clk_domain, self.cd_index
        )
        return s


def one_port(inst, name, gvar):
    # names are stored in port_lists with : as hierarchy separator
    s = re.sub(":", "_", name)
    # wid = int(msb) - int(lsb) + 1
    # suffix = '' if (gvar is None) else '[%s*%d+%s:%s*%d+%s]'%(gvar, wid, msb, gvar, wid, lsb);
    if gvar is None:
        return ".%s(%s_%s)" % (s, inst, s)
    else:
        return ".%s(%s_array_%s[%s])" % (s, inst, s, gvar)


def range_width(r):
    """
    A utility function: string [a:b] => integer a-b+1
    """
    r2 = re.sub(r"\]", "", re.sub(r"\[", "", r))
    nums = r2.split(":")
    return int(nums[0]) - int(nums[1]) + 1


def use_ram_key(mod, name):
    var = name.split(":")[-1]
    return mod + ":" + var


class Parser:

    def __init__(self):
        self.port_lists = {}  # module_name: [list of ports]
        self.self_ports = []
        self.decodes = []
        self.use_ram = {}  # module_name : variable
        self.self_map = {}
        self.gch = {}
        self.g_flat_addr_map = {}
        self.file_not_found = 0

    def search_verilog_files(self, dlist, fin, stack):
        '''
        Find a .v, and .sv files in that order
        '''
        if isfile(fin):
            return fin
        fname = basename(fin)
        fname_sv = splitext(fname)[0] + '.sv'
        for d in dlist:
            vfile = d + '/' + fname
            if isfile(vfile):
                return vfile
            else:
                vfile = d + '/' + fname_sv
                if isfile(vfile):
                    return vfile
        print("File not found:", fin)
        print("(from hierarchy %s)" % stack)
        self.file_not_found += 1
        return False

    def consider_port(self, p, fd):
        # 5-element list is (input/output) (signed/None) lsb msb name
        if p.direction == "output":
            # TODO: Another idiosyncrasy, moved to an attribute as per new spec
            bp = re.sub("_addr$", "", p.name)
            fd.write("// found output address in module %s, base=%s\n" % (p.module, bp))
            self.use_ram[p.module + ":" + bp] = "[%s:%s]" % p.downto

    def make_decoder_inner(self, inst, mod, p):
        """
        Constructs a decoder for a port p.
        p: is an instance of Port
        # TODO: clarify what different signal_types are exactly
        """
        # print '// make_decoder',inst,mod,a
        if p.direction != "output":
            # print '// make_decoder instance=%s name=%s'%(inst,a[5])
            clk_prefix = p.clk_domain
            cd_index_str = ""
            if p.cd_indexed and p.cd_index is not None:
                cd_index_str = "[%d]" % p.cd_index
            key = use_ram_key(p.module, p.name)
            # print '// checking use_ram for key '+key
            if inst is None:
                sig_name = re.sub(":", "_", p.name)
            else:
                sig_name = "%s_%s" % (inst, re.sub(":", "_", p.name))
            decode_def = "wire we_%s = %s_write%s&(`ADDR_HIT_%s);\\\n" % (
                sig_name,
                clk_prefix,
                cd_index_str,
                sig_name,
            )
            msb = int(p.downto[0])
            lsb = int(p.downto[1])
            data_width = msb - lsb + 1
            sign = p.sign if p.sign else "unsigned"
            if key in self.use_ram:
                addr_range = self.use_ram[key]
                data_range = "[%d:%d]" % (msb, lsb)
                addr_width = range_width(addr_range)
                # print '// ***** use_ram %s %s'%(key,use_ram[key]), addr_range,
                # addr_width, data_range, data_width
                wire_def = "wire %s %s_addr;\\\nwire %s %s;\\\n" % (
                    addr_range,
                    sig_name,
                    data_range,
                    sig_name,
                )
                dpram_a = (
                    ".clka(%s_clk), .addra(%s_addr%s%s), .dina(%s_data%s%s),"
                    " .wena(we_%s)"
                    % (
                        clk_prefix,
                        clk_prefix,
                        cd_index_str,
                        addr_range,
                        clk_prefix,
                        cd_index_str,
                        data_range,
                        sig_name,
                    )
                )
                dpram_b = ".clkb(%s_clk), .addrb(%s_addr), .doutb(%s)" % (
                    clk_prefix,
                    sig_name,
                    sig_name,
                )
                dpram_def = "dpram #(.aw(%d),.dw(%d)) dp_%s(\\\n\t%s,\\\n\t%s);\\\n" % (
                    addr_width,
                    data_width,
                    sig_name,
                    dpram_a,
                    dpram_b,
                )
                self.decodes.append(wire_def + decode_def + dpram_def)
                self.gch[sig_name] = (
                    addr_width,
                    mod,
                    sign,
                    data_width,
                    clk_prefix,
                    cd_index_str,
                    p.description,
                )
            elif p.signal_type == "single-cycle":
                if p.needs_declaration:
                    reg_decl = 'reg [{}:{}] {}=0;'.format(msb, lsb, sig_name)
                else:
                    reg_decl = ''
                reg_def = '%s always @(posedge %s_clk) '\
                          '%s <= we_%s ? %s_data%s[%d:%d] : %d\'b0;\\\n' %\
                          (reg_decl, clk_prefix, sig_name, sig_name,
                           clk_prefix, cd_index_str, msb, lsb, data_width)
                self.decodes.append(decode_def + reg_def)
                self.gch[sig_name] = (
                    0,
                    mod,
                    sign,
                    data_width,
                    clk_prefix,
                    cd_index_str,
                    p.description,
                )
            elif p.signal_type == "strobe":
                read_strobe = "wire %s = %s_read & (`ADDR_HIT_%s);\\\n" % (
                    sig_name,
                    clk_prefix,
                    sig_name,
                )
                self.decodes.append(read_strobe)
                self.gch[sig_name] = (
                    0,
                    mod,
                    sign,
                    data_width,
                    clk_prefix,
                    cd_index_str,
                    p.description,
                )
            elif p.signal_type == "we-strobe":
                reg_def = "wire %s = we_%s;\\\n" % (sig_name, sig_name)
                self.decodes.append(decode_def + reg_def)
                self.gch[sig_name] = (
                    0,
                    mod,
                    sign,
                    data_width,
                    clk_prefix,
                    cd_index_str,
                    p.description,
                )
            elif p.signal_type == "plus-we-VOID":
                pass
            else:
                if p.signal_type == "plus-we":
                    we_def = "wire %s_we = we_%s;\\\n" % (sig_name, sig_name)
                else:
                    we_def = ""
                if p.needs_declaration:
                    reg_decl = 'reg [{}:{}] {}=0;'.format(msb, lsb, sig_name)
                else:
                    reg_decl = ''
                reg_def = '%s always @(posedge %s_clk) '\
                          'if (we_%s) %s <= %s_data%s;\\\n' %\
                          (reg_decl, clk_prefix, sig_name, sig_name,
                           clk_prefix, cd_index_str)
                self.decodes.append(decode_def + we_def + reg_def)
                self.gch[sig_name] = (
                    0,
                    mod,
                    sign,
                    data_width,
                    clk_prefix,
                    cd_index_str,
                    p.description,
                )

    def make_decoder(self, inst, mod, a, gcnt):
        if gcnt is None:
            self.make_decoder_inner(inst, mod, a)
        else:
            for ig in range(gcnt):
                # HACK: side effect; Benign
                # This helps figure out the instantiation in the case of gvar
                if a.cd_indexed:
                    a.cd_index = ig
                # print '// make_decoder iteration %d'%ig
                self.make_decoder_inner("%s_%d" % (inst, ig), mod, a)

    def print_instance_ports(self, inst, mod, gvar, gcnt, fd):
        """
        Print the port assignments for the instantiation of a module.
        At the same time, append to the self_ports and decodes strings,
        so the variables mapped to the ports can get adequately defined.
        """
        instance_ports = self.port_lists[mod]
        if fd:
            # 'list comprehension' for the port list itself
            this_list = [one_port(inst, p.name, gvar) for p in instance_ports]
            if this_list:
                tail = " " + ",\\\n\t".join(this_list)
            else:
                tail = ""
            fd.write("`define AUTOMATIC_" + inst + tail)
            fd.write("\n")
        #  now construct the self_ports and decoders (if any)
        for p in instance_ports:
            sig = "" if (p.sign is None) else p.sign  # signed flag
            if gvar is None:
                self.self_ports.append(
                    "%s %s [%s:%s] %s_%s"
                    % (
                        p.direction,
                        sig,
                        p.downto[0],
                        p.downto[1],
                        inst,
                        re.sub(":", "_", p.name),
                    )
                )
            else:
                for ig in range(gcnt):
                    self.self_ports.append(
                        "%s %s [%s:%s] %s_%d_%s"
                        % (
                            p.direction,
                            sig,
                            p.downto[0],
                            p.downto[1],
                            inst,
                            ig,
                            re.sub(":", "_", p.name),
                        )
                    )
            self.make_decoder(inst, mod, p, gcnt)

    def construct_map(self, inst, p, gcnt, mod):
        sig = "" if (p.sign is None) else p.sign
        msb = int(p.downto[0])
        lsb = int(p.downto[1])
        # wid = msb-lsb+1
        name = re.sub(":", "_", p.name)
        # print '// construct_map',sig,msb,lsb,inst,name,gcnt, mod
        self.self_map[mod].append(
            "wire %s [%d:%d] %s_array_%s [0:%d];" % (sig, msb, lsb, inst, name, gcnt - 1)
        )
        for ig in range(gcnt):
            array_el = "%s_array_%s[%d]" % (inst, name, ig)
            expanded = "%s_%d_%s" % (inst, ig, name)
            if p.direction == "input":
                self.self_map[mod].append("assign %s = %s;\\\n" % (array_el, expanded))
            elif p.direction == "output":
                self.self_map[mod].append("assign %s = %s;\\\n" % (expanded, array_el))

    def parse_vfile_yosys(self, stack, fin, fd, dlist, clk_domain, cd_indexed):
        '''
        Given a filename, parse Verilog:
        (a) looking for module instantiations marked automatic,
        for which we need to generate port assignments.
        When such an instantiation is found, recurse.
        (b) looking for input/output ports labeled 'external'.
        Record them in the port_lists dictionary for this module.
        '''
        # TODO: Old newad doesn't really take care of the case where
        #       there are multiple modules in a single file, as there is no check
        #       for module declaration per se, also doesn't support other fancy
        #       declarations like "input [15:0] a, b,".
        searchpath = dirname(fin)
        file_found = self.search_verilog_files(dlist, fin, stack)

        if not file_found:
            return
        else:
            fin = file_found

        fd.write('// parse_vfile_yosys %s %s\n' % (stack, fin))
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
            cd_indexed_l = True if 'cd_indexed' in mod_attrs else cd_indexed
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
            if mod not in self.port_lists:
                # recurse
                self.parse_vfile_yosys(stack + ':' + fin,
                                       searchpath + '/' + mod + '.v',
                                       fd, dlist, clk_domain_l, cd_indexed_l)
            if not stack:
                if gvar is None or ig == 0:
                    self.print_instance_ports(inst, mod, gvar, gcnt, fd)

            # add this instance's external ports to our own port list
            for p in self.port_lists[mod] if mod in self.port_lists else []:
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
                        if this_mod not in self.self_map:
                            self.self_map[this_mod] = []
                        self.construct_map(inst, p, gcnt, this_mod)

        for port, (net_info, port_info) in parsed_mod['external_nets'].items():
            signal_type = net_info['attributes']['signal_type'] if 'signal_type' in net_info['attributes'] else None
            signed = 'signed' if 'signed' in net_info else None
            direction = port_info['direction'] if 'direction' in port_info else None
            p = Port(port,
                     # TODO: This is a hack needs to be fixed
                     (len(net_info['bits']) - 1, 0),
                     direction,
                     signed,
                     this_mod,
                     signal_type,
                     clk_domain,
                     cd_indexed,
                     port_info != {},
                     **attributes)
            this_port_list.append(p)
            if not stack and port_info == {}:
                self.make_decoder(None, this_mod, p, None)
            else:
                self.consider_port(p, fd)
            if signal_type == 'plus-we':
                p = Port(port + '_we',
                         (0, 0),
                         direction,
                         None,
                         this_mod,
                         'plus-we-VOID',
                         clk_domain,
                         cd_indexed,
                         port_info != {},
                         **attributes)
                this_port_list.append(p)
                if not stack:
                    self.make_decoder(None, this_mod, p, None)
                else:
                    self.consider_port(p, fd)
            attributes = {}

        self.port_lists[this_mod] = this_port_list
