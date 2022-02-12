#!/usr/bin/python3

# Larry Doolittle, June 2015
# updates Sept 2015
# Lucas Russo, Feb 2022 (rest generation support and fixes to regex)
# convert to python3 Feb 2022

# Pull port information out of a Verilog program
# to build automatic documentation

# Demand that the input have one port per line, and the
# comment (if any) will be used for the documentation.
# e.g.,
#     input signed [17:0] x,  // Multiplicand, signed, time-interleaved real and imaginary

# HTML output needs hooks to put actual narrative in the file
# No signed/unsigned information for ports?

import re
import json
import os

# from: https://stackoverflow.com/questions/8234274/how-to-indent-the-contents-of-a-multi-line-string
try:
    import textwrap
    textwrap.indent
except AttributeError:  # undefined function (wasn't added until Python 3.3)
    def indent(text, amount, ch=" "):
        padding = amount * ch
        return "".join(padding+line for line in text.splitlines(True))
else:
    def indent(text, amount, ch=" "):
        return textwrap.indent(text, amount * ch)


class verilog_port():
    def __init__(self, io, signed, msb, lsb, ident, desc):
        self.io = io
        self.signed = signed
        self.msb = msb
        self.lsb = lsb
        self.ident = ident
        self.desc = desc if desc else ""

    def sign(self):
        if self.signed:
            return self.signed
        return "unsigned"

    def direction(self):
        r = self.io
        r = r[0].upper()+r[1:]
        return r

    def bits(self):
        if self.msb == 0 and self.lsb == 0:
            return ""
        return "[{}:{}]".format(self.msb, self.lsb)

    def xprint(self):
        print("Port {}".format(self.ident))
        print("   inout {}".format(self.io))
        print("   signed {}".format(self.signed))
        print("   range [{}:{}]".format(self.msb, self.lsb))
        print("   desc {}".format(self.desc))

    def table_row(self):
        return "<tr><td><tt>{}</tt></td><td>{}</td><td>{}</td></tr>" \
               .format(self.ident+self.bits(), self.direction(), self.desc)

    def table_row_html(self):
        self.table_row()

    def table_row_rst(self):
        return """* - {}
  - {}
  - {}""".format(self.ident+self.bits(), self.direction(), self.desc)


def parse_vline_port(ll):
    # Try to match the most complex regex first, as it might be able to
    # to match the simpler one by using the optional groups. Maybe use a non-greedy
    # pattern?
    m = re.search(r'^\s*(\(\*.*?\*\))?\s*\b(input|output|inout)\s+(wire|reg)?'
                  r'\s*(signed)?\s*\[([^:]+):([^]]+)\]\s*(\w+),?\s*(//\s*(.*))?', ll)
    if m:
        g = [m.group(i) for i in range(2, 10)]
        # print(g)
        return verilog_port(io=g[0], signed=g[2], msb=g[3], lsb=g[4], ident=g[5], desc=g[7])
    m = re.search(r'^\s*(\(\*.*?\*\))?\s*\b(input|output|inout)\s+(wire|reg)?'
                  r'\s*(signed)?\s*(\w+),?\s*(//\s*(.*))?', ll)
    if m:
        g = [m.group(i) for i in range(2, 8)]
        # print(g)
        return verilog_port(io=g[0], signed=g[2], msb=0, lsb=0, ident=g[3], desc=g[5])
    return None


class verilog_param():
    def __init__(self, ident, default, desc):
        self.ident = ident
        self.default = default
        self.desc = desc if desc else ""

    def xprint(self):
        print("Parameter {}".format(self.ident))
        print("   default {}".format(self.default))
        print("   desc {}".format(self.desc))

    def table_row(self):
        return "<tr><td><tt>{}</tt></td><td>{}</td><td>{}</td><td>{}</td><td>{}</td></tr>" \
               .format(self.ident, "?", "?", self.default, self.desc)

    def table_row_html(self):
        self.table_row()

    def table_row_rst(self):
        return """* - {}
  - {}
  - {}
  - {}
  - {}""".format(self.ident, "?", "?", self.default, self.desc)


def parse_vline_param(ll):
    m = re.search(r'^\s*\bparameter\s+(\w+)\s*=\s*(\w*)[,;]?\s*(//\s*(.*))?', ll)
    if m:
        g = [m.group(i) for i in range(1, 5)]
        # print(g)
        return verilog_param(ident=g[0], default=g[1], desc=g[3])
    return None


class mod_comment():
    def __init__(self, desc=None):
        self.desc = desc if desc else ""

    def description(self):
        return self.desc

    def xprint(self):
        print(self.desc)

    def desc_row_rst(self):
        return self.desc


def parse_whole_line_comment_or_blank(ll):
    m = re.search(r'^\s*\/[\/]+(.*)', ll)
    if m:
        g = [m.group(i) for i in range(1, 2)]
        # print(g)
        return mod_comment(desc=g[0])
    m = re.search(r'(^\s*$)', ll)
    if m:
        g = [m.group(i) for i in range(1, 2)]
        # print(g)
        return mod_comment(desc=g[0])
    return None


def parse_endmodule(ll):
    m = re.search(r'^\s*\bendmodule.*', ll)
    if m:
        return True
    return False


def make_html(fname, param_list, port_list):
    fbase, fext = os.path.splitext(os.path.basename(fname))
    hstring = open(fbase+'.html.in').read()
    hdata = json.loads('{' + re.sub('\n', ' ', hstring) + '}')
    # print("got it")
    print('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">')
    print('<html>')
    print('<head>')
    print(' <meta http-equiv="Content-Type" content="text/html;charset=utf-8">')
    print(' <meta name=viewport content="width=device-width, initial-scale=1">')
    print(' <title>' + hdata["title"] + '</title>')
    print('</head>')
    print('<body>')
    print('<h1>' + fname + ": " + hdata["title"] + "</h1>")
    print(hdata["intro_html"])
    if True:
        print("<h3>Pinout</h3><p>")
        print("<img src=\"{}_block.png\" alt=\"schematic symbol\">\n"
              .format(fbase))

    if param_list:
        print("<h3>Parameters</h3>")
        print("<table border=1 cellspacing=0>")
        print("<tr><th>Name</th><th>Min</th><th>Max</th><th>Default</th><th>Description</th></tr>")
        for p in param_list:
            print(p.table_row())
        print("</table>\n")
    if port_list:
        print("<h3>Ports</h3>")
        print("<table border=1 cellspacing=0>")
        print("<tr><th>Signal</th><th>Direction</th><th>Description</th></tr>")
        for p in port_list:
            print(p.table_row())
        print("</table>\n")
    if True:
        print("<h3>Implementation and use</h3><p>")
        print("The <a href=\"https://en.wikipedia.org/wiki/Software_portability\">portable</a>")
        print("<a href=\"https://en.wikipedia.org/wiki/Verilog\">Verilog</a>")
        print("implementation in <a href=\"{}\">{}</a>".format(fname, fname))
        print(hdata["implement_html"] + "\n")
    if True:
        print("<p>")
        print("A <a href=\"http://gtkwave.sourceforge.net/\">GTKWave</a>-generated")
        print("timing diagram showing {} is shown here:"
              .format(hdata["timing_html"]))
        print("<p><img src=\"{}_timing.png\" alt=\"timing diagram\">\n"
              .format(fbase))
    try:
        cfile = open(fbase+"_check", 'r')
        print("<h3>Regression test</h3>")
        print("<p>")
        print("Expected results of <tt>make {}_check</tt>:<pre>".format(fbase))
        print(cfile.read()+"</pre>\n")
    except FileNotFoundError:
        pass

    print("</body></html>")


def make_src_rst(fname):
    fbase, fext = os.path.splitext(os.path.basename(fname))
    print(".. _{}_source:".format(fbase))
    print("")
    print('{} Source File'.format(fbase))
    print('{}'.format("".join(['='*(len(fbase)+12)])))
    print("")

    print(".. code-block:: verilog")
    print("   :linenos:")
    print("")
    with open(fname, 'r') as ifile:
        print(indent(ifile.read(), 3))


def make_rst(fname, param_list, port_list, mod_comment_list, with_timing=None):
    fbase, fext = os.path.splitext(os.path.basename(fname))
    print(".. _{}:".format(fbase))
    print("")
    print('{}'.format(fbase))
    print('{}'.format("".join(['='*len(fbase)])))
    print("")

    if mod_comment_list:
        description_txt = "Description"
        print('{}'.format(description_txt))
        print('{}'.format("".join(["\'"*len(description_txt)])))
        print("")
        for c in mod_comment_list:
            # RST is sensitive with leading spaces, use line blocks
            print("| " + c.desc_row_rst())
        print("")

    if True:
        pinout_txt = "Pinout"
        print('{}'.format(pinout_txt))
        print('{}'.format("".join(["\'"*len(pinout_txt)])))
        print("")
        print(".. _fig:{}_block:".format(fbase))
        print(".. figure:: {}_block.png".format(fbase))
        print("    :alt: Schematic symbol")
        print("")

    if param_list:
        param_txt = "Parameters"
        print('{}'.format(param_txt))
        print('{}'.format("".join(["\'"*len(param_txt)])))
        print("")
        print(".. list-table:: {}_param_table".format(fbase))
        print("   :header-rows: 1")
        print("")
        print(indent("""* - Name
  - Min
  - Max
  - Default
  - Description""", 3))
        for p in param_list:
            print(indent(p.table_row_rst(), 3))
        print("")

    if port_list:
        port_txt = "Ports"
        print('{}'.format(port_txt))
        print('{}'.format("".join(["\'"*len(port_txt)])))
        print("")
        print(".. list-table:: {}_port_table".format(fbase))
        print("   :header-rows: 1")
        print("")
        print(indent("""* - Signal
  - Direction
  - Description""", 3))
        for p in port_list:
            print(indent(p.table_row_rst(), 3))
        print("")

    if True:
        imp_txt = "Implementation and use"
        print('{}'.format(imp_txt))
        print('{}'.format("".join(["\'"*len(imp_txt)])))
        print("")
        print("The `portable`_ `Verilog`_")
        print("implementation can be found in :ref:`{}_source`".format(fbase))
        print("")
        print(".. _`portable`: https://en.wikipedia.org/wiki/Software_portability")
        print(".. _`Verilog`: https://en.wikipedia.org/wiki/Verilog")
        print("")

    if with_timing:
        timing_txt = "Timing Diagram"
        print('{}'.format(timing_txt))
        print('{}'.format("".join(["\'"*len(timing_txt)])))
        print("")
        print("A `GTKWave`_-generated timing diagram is shown below:")
        print("")
        print(".. _`GTKWave`: http://gtkwave.sourceforge.net/")
        print("")
        print(".. _fig:{}_timing:".format(fbase))
        print(".. figure:: {}_timing.png".format(fbase))
        print("    :alt: Timing diagram")
        print("")


def count_inout(port_list):
    n_in, n_out = 0, 0
    for p in port_list:
        if p.io == "input":
            n_in = n_in+1
        elif p.io == "output":
            n_out = n_out+1
        else:
            print("warning", p.io)
    return n_in, n_out


def make_eps(port_list):
    n_in, n_out = count_inout(port_list)
    height = 24*max(n_in, n_out)
    width = 192  # conceptually depends on length of port names
    print("""%!PS-Adobe-3.0 EPSF-3.0
%%Title: symbol.eps
%%Creator: portfind.py
%%Pages: 1""")
    print("%%BoundingBox:", "68 68 {} {}".format(112+width, 100+height))   # 244 220
    print("""%%DocumentNeededResources: font Helvetica
%%EndComments
%%BeginProlog""")
    print("""
/rshow { dup stringwidth pop neg 0 rmoveto show } def
/lpin { setlinewidth moveto gsave  7 -5 rmoveto  show grestore -20 0 rlineto stroke } def
/rpin { setlinewidth moveto gsave -7 -5 rmoveto rshow grestore  20 0 rlineto stroke } def
/RT { % w h x y RT -
      % draw a rectangle size w h at x y
   moveto
   dup 0 exch rlineto
   exch 0 rlineto
   neg 0 exch rlineto
   closepath } def
/Helvetica findfont 15 scalefont setfont
""")
    pitch = 24
    y_offset = 72
    y_center = y_offset + height/2
    y_l = y_center+pitch*n_in/2
    y_r = y_center+pitch*n_out/2
    x_l = 90
    for p in port_list:
        if p.io == "input":
            x = x_l
            cmd = "lpin"
            y = y_l
            y_l = y_l - pitch
        elif p.io == "output":
            x = 90+width
            cmd = "rpin"
            y = y_r
            y_r = y_r - pitch
        if p.msb == 0 and p.lsb == 0:
            w = 1  # single wire
        else:
            w = 3  # bus
        print("({}) {} {} {} {}".format(p.ident, int(x), int(y), int(w), cmd))
    print("1 setlinewidth {} {} {} {} RT stroke".format(width, height+24, x_l, y_offset))
    print("""
showpage

%%Trailer
%%EOF""")


def svg_line(x0, y0, x1, y1, w):
    print("<line x1=\"{}\" y1=\"{}\" x2=\"{}\" y2=\"{}\" stroke=\"blue\" stroke-width=\"{}\" />"
          .format(x0, y0, x1, y1, w))


def svg_box(dx, dy, x0, y0):
    svg_line(x0, y0, x0+dx, y0, 2)
    svg_line(x0, y0+dy, x0+dx, y0+dy, 2)
    svg_line(x0, y0, x0, y0+dy, 2)
    svg_line(x0+dx, y0, x0+dx, y0+dy, 2)


def svg_port(ident, x, y, w, cmd):
    # print("({}) {} {} {} {}".format((ident, x, y, w, cmd)
    sgn = 1 if cmd == "lpin" else -1
    svg_line(x, y, x-20*sgn, y, w)
    align = "start" if cmd == "lpin" else "end"
    print("<text x=\"{}\" y=\"{}\" font-family=\"Verdana, sans-serif\" "
          "font-size=\"16\" text-anchor=\"{}\">{}</text>".format(x+7*sgn, y+5, align, ident))


def make_svg(port_list):
    n_in, n_out = count_inout(port_list)
    height = 24*max(n_in, n_out)
    width = 192  # conceptually depends on length of port names
    print('<?xml version="1.0" encoding="UTF-8" ?>')
    print('<svg xmlns="http://www.w3.org/2000/svg" version="1.1">')
    pitch = 24
    y_offset = 72
    y_center = y_offset + height/2
    y_l = y_center+pitch*n_in/2
    y_r = y_center+pitch*n_out/2
    x_l = 90
    for p in port_list:
        if p.io == "input":
            x = x_l
            cmd = "lpin"
            y = y_l
            y_l = y_l - pitch
        elif p.io == "output":
            x = 90+width
            cmd = "rpin"
            y = y_r
            y_r = y_r - pitch
        if p.msb == 0 and p.lsb == 0:
            w = 1  # single wire
        else:
            w = 3  # bus
        svg_port(p.ident, x, y, w, cmd)
    svg_box(width, height+24, x_l, y_offset)
    print('</svg>')


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Generate documentation from verilog files")
    parser.add_argument("--gen-eps", default=False, action="store_true",
                        help="Generate .eps block diagram from verilog file")
    parser.add_argument("--gen-svg", default=False, action="store_true",
                        help="Generate .svg block diagram from verilog file")
    parser.add_argument("--gen-html", default=False, action="store_true",
                        help="Generate .html documentation from verilog file")
    parser.add_argument("--gen-rst", default=False, action="store_true",
                        help="Generate .rst documentation from verilog file")
    parser.add_argument("--gen-src-rst", default=False, action="store_true",
                        help="Generate .rst source file from verilog file")
    parser.add_argument("--rst-with-timing", default=False, action="store_true",
                        help="Add timing diagram to .rst documentation (only affects .rst files)")
    parser.add_argument("file", default="", help="Verilog input file")
    cmd_args = parser.parse_args()

    do_eps = cmd_args.gen_eps
    do_svg = cmd_args.gen_svg
    do_html = cmd_args.gen_html
    do_rst = cmd_args.gen_rst
    do_src_rst = cmd_args.gen_src_rst
    rst_with_timing = cmd_args.rst_with_timing
    fname = cmd_args.file

    ifile = open(fname, 'r')
    fdata = ifile.read()
    port_list = []
    param_list = []
    mod_comment_list = []
    try_mod_desc = True
    for line in fdata.split('\n'):
        # Avoid parsing more than 1 module per file. This confuses
        # our current way of parsing with
        if parse_endmodule(line.strip()):
            break

        if try_mod_desc:
            c = parse_whole_line_comment_or_blank(line.strip())
            if c:
                mod_comment_list.append(c)
            else:
                try_mod_desc = False
                continue
        else:
            p = parse_vline_port(line.strip())
            if p:
                port_list.append(p)
            else:
                p = parse_vline_param(line.strip())
                if p:
                    param_list.append(p)
    if False:
        for p in param_list+port_list:
            p.xprint()
    if do_eps:
        make_eps(port_list)
    elif do_svg:
        make_svg(port_list)
    elif do_html:
        make_html(fname, param_list, port_list)
    elif do_src_rst:
        make_src_rst(fname)
    elif do_rst:
        make_rst(fname, param_list, port_list, mod_comment_list, rst_with_timing)


if __name__ == "__main__":
    main()
