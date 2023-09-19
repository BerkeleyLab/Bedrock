import re

from copy import deepcopy
from os.path import dirname

from parser import Port, Parser


INSTANTIATION_SITE = r"^\s*(\w+)\s+(#\(.*\) *)?(\w+)\s*//\s*auto(\(\w+,\d+\))?\s+((\w+)(\[(\w+)\])?)?"
# Search for port with register width defined 'input (signed)? [%d:%d] name // <...>'
PORT_WIDTH_MULTI = r"^\s*,?(input|output)\s+(signed)?\s*\[(\d+):(\d+)\]\s*(\w+),?\s*"
PORT_WIDTH_MULTI += r"//\s*external\s*(single-cycle|strobe|we-strobe|plus-we)?"
# Search for port with register width 1 'input (signed)? name // <...>'
PORT_WIDTH_SINGLE = r"^\s*,?(input|output)\s+(signed)?\s*(\w+),?\s*//\s*external\s*(single-cycle|strobe|we-strobe)?"
TOP_LEVEL_REG = r"^\s*//\s*reg\s+(signed)?\s*\[(\d+):(\d+)\]\s*(\w+)\s*;\s*top-level\s*(single-cycle|strobe|we-strobe)?"
TOP_LEVEL_NEW = r"^\s*reg\s+(signed)?\s*\[(\d+):(\d+)\]\s*(\w+)\s*;\s*//\s*top-level\s*(single-cycle|strobe|we-strobe)?"
DESCRIPTION_ATTRIBUTE = r"^\s*\(\*\s*BIDS_description\s*=\s*\"(.+?)\"\s*\*\)\s*$"


class CommentParser(Parser):
    def __init__(self):
        super().__init__()

    def parse_vfile_comments(self, stack, fin, fd, dlist, clk_domain, cd_indexed, try_sv=True):
        """
        Given a filename, parse Verilog:
        (a) looking for module instantiations marked automatic,
        for which we need to generate port assignments.
        When such an instantiation is found, recurse.
        (b) looking for input/output ports labeled 'external'.
        Record them in the port_lists dictionary for this module.
        """
        searchpath = dirname(fin)
        file_found = self.search_verilog_files(dlist, fin, stack)

        if not file_found:
            return
        else:
            fin = file_found

        fd.write("// parse_vfile %s %s\n" % (stack, fin))
        if searchpath == "":
            searchpath = "."
        this_mod = fin.split("/")[-1].split(".")[0]
        verilog_file_lines = []
        port_clock = clk_domain
        # Looks like the reason we read the whole file is to avoid opening
        # several files at the same time
        with open(fin, "r") as f:
            verilog_file_lines = f.readlines()
        this_port_list = []
        attributes = {}
        for line in verilog_file_lines:
            # Search for attributes
            m = re.search(DESCRIPTION_ATTRIBUTE, line)
            if m:
                value = m.group(1)
                attributes["description"] = value
            line_no_attributes = re.sub(r"\(\*[^\*]*\*\)", "", line)
            # (a) instantiations
            m = re.search(INSTANTIATION_SITE, line)
            if m:
                mod = m.group(1)
                inst = m.group(3)
                gspec = m.group(4)
                clk_domain_l = clk_domain
                cd_indexed_l = cd_indexed
                if m.group(6) is not None:
                    clk_domain_l = m.group(6)
                    fd.write(
                        "// instance %s: clk_domain override %s\n" % (inst, clk_domain_l)
                    )
                    if m.group(8) is not None:
                        cd_indexed_l = True
                if gspec is not None:
                    mm = re.search(r"\((\w+),(\d+)\)", gspec)
                    gvar = mm.group(1)
                    gcnt = int(mm.group(2))
                else:
                    gvar = None
                    gcnt = None
                fd.write(
                    "// module=%s instance=%s gvar=%s gcnt=%s clk=%s\n"
                    % (mod, inst, gvar, str(gcnt), clk_domain_l)
                )
                if mod not in self.port_lists:
                    # recurse
                    self.parse_vfile_comments(
                        stack + ":" + fin,
                        searchpath + "/" + mod + ".v",
                        fd,
                        dlist,
                        clk_domain_l,
                        cd_indexed_l
                    )
                if not stack:
                    self.print_instance_ports(inst, mod, gvar, gcnt, fd)
                # add this instance's ports to our own port list
                for p in self.port_lists[mod] if mod in self.port_lists else []:
                    if gcnt is None:
                        p_p = deepcopy(p)  # p_prime
                        this_port_list.append(p_p.port_prefix_set(inst + ":"))
                    else:
                        for ig in range(gcnt):
                            p_p = deepcopy(p)  # p_prime
                            p_p = p_p.port_prefix_set("%s_%d:" % (inst, ig))
                            if cd_indexed_l and m.group(6) is not None:
                                p_p.cd_index = ig
                            this_port_list.append(p_p)
                        if this_mod not in self.self_map:
                            self.self_map[this_mod] = []
                        self.construct_map(inst, p, gcnt, this_mod)
            # (b) ports
            # Search for port with register width defined 'input (signed)? [%d:%d] name // <...>'
            m = re.search(PORT_WIDTH_MULTI, line_no_attributes)
            if m:
                info = [m.group(i) for i in range(7)]
                p = Port(
                    info[5],
                    (info[3], info[4]),
                    info[1],
                    info[2],
                    this_mod,
                    info[6],
                    port_clock,
                    cd_indexed,
                    **attributes
                )
                this_port_list.append(p)
                self.consider_port(p, fd)
                if info[6] == "plus-we":
                    p = Port(
                        info[5] + "_we",
                        (0, 0),
                        info[1],
                        None,
                        this_mod,
                        info[6] + "-VOID",
                        port_clock,
                        cd_indexed,
                        **attributes
                    )
                    this_port_list.append(p)
                    self.consider_port(p, fd)
                attributes = {}
            else:
                m = re.search(PORT_WIDTH_SINGLE, line)
                if m:
                    info = [m.group(i) for i in range(5)]
                    p = Port(
                        info[3],
                        (0, 0),
                        info[1],
                        info[2],
                        this_mod,
                        info[4],
                        port_clock,
                        cd_indexed,
                        **attributes
                    )
                    this_port_list.append(p)
                    self.consider_port(p, fd)
                    attributes = {}
            # new feature:  local override of clock domain
            # some modules have control inputs in multiple domains
            # used in lcls2_llrf digitizer_config.v digitizer_dsp.v
            m = re.search(r"^\s*//\s*newad-force\s+(\w+)\s+domain", line)
            if m:
                new_clock = m.group(1)
                # print("clock domain local override: %s in %s" % (new_clock, fin))
                port_clock = new_clock

            # (c) registers in the top-level file
            if not stack:
                m = re.search(TOP_LEVEL_REG, line)
                if m:
                    info = [m.group(i) for i in range(6)]
                    p = Port(
                        info[4],
                        (info[2], info[3]),
                        "top_level",
                        info[1],
                        this_mod,
                        info[5],
                        clk_domain,
                        cd_indexed,
                        True,
                        **attributes
                    )
                    this_port_list.append(p)
                    # Since these are top level registers, decoders can be generated here
                    self.make_decoder(None, this_mod, p, None)
                    attributes = {}
                m = re.search(TOP_LEVEL_NEW, line_no_attributes)
                if m:
                    info = [m.group(i) for i in range(6)]
                    # Look carefully at the "False" in slot 9 vs. "True" above.
                    # That clears the needs_declaration flag such that we don't
                    # duplicate the register declaration.
                    p = Port(
                        info[4],
                        (info[2], info[3]),
                        "top_level",
                        info[1],
                        this_mod,
                        info[5],
                        clk_domain,
                        cd_indexed,
                        False,
                        **attributes
                    )
                    this_port_list.append(p)
                    # Since these are top level registers, decoders can be generated here
                    self.make_decoder(None, this_mod, p, None)
                    attributes = {}
        # print '// debug',this_mod,this_port_list
        self.port_lists[this_mod] = this_port_list
