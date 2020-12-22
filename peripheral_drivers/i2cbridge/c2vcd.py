
import sys


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Props to W.J. van der Laan in http://code.activestate.com/recipes/219300/
    return list(map(lambda y: (x >> y) & 1, range(count-1, -1, -1)))


def vcd_header(ofile, dw, first):
    ofile.write("$date November 11, 2009. $end\n")
    ofile.write("$version c2vcd $end\n")
    ofile.write("$timescale 1ns $end\n")
    ofile.write("$scope module logic $end\n")
    bit_names = ["SCL", "SDA"]
    for ix in range(dw):
        # name = "bit%2.2d" % ix
        name = bit_names[ix]
        ofile.write("$var wire 1 %s %s $end\n" % (chr(65+ix), name))
    ofile.write("$upscope $end\n")
    ofile.write("$enddefinitions $end\n")
    ofile.write("$dumpvars\n")
    for ix in range(dw):
        ofile.write("b%d %s\n" % (first[ix], chr(65+ix)))
    ofile.write("$end\n")


def emit_step(ofile, v, old_v, dw, time, first):
    vbin = tobin(v, count=dw)
    if first:
        vcd_header(ofile, dw, vbin)
    else:
        old_vbin = tobin(old_v, count=dw)
        for ix in range(dw):
            if vbin[ix] != old_vbin[ix]:
                ofile.write("b%d %s\n" % (vbin[ix], chr(65+ix)))
    ofile.write("#%d\n" % time)


# Too much stuff hard-coded in vcd_header, like bit_names
def produce_vcd(ofile, memory, dw=2, mtime=64, t_step=20):
    divisor = 1 << dw
    first = True
    t = 0
    old_v = 0  # value not used
    for x in memory:
        dt = int(x/divisor)
        v = x % divisor
        if dt == 0:
            dt = mtime
        t = t + dt
        emit_step(ofile, v, old_v, dw, t*t_step, first)
        old_v = v
        first = False


if __name__ == "__main__":
    t = 0
    old_pc = -1
    # 50 MHz and ns time step means multiply integer time count by 20
    t_step = 20  # ns tick in simulation
    ofile = sys.stdout
    old_v = None
    with open(sys.argv[1], 'r') as f:
        for line in f.read().split('\n'):
            if not line:
                break
            a = line.split()
            if a[0] == "#":
                mtime = 1 << int(a[1])
                dw = int(a[2])
                old_vbin = ["" for ix in range(dw)]
                # print "setup",mtime,dw
                continue
            pc = int(a[0])
            if pc != old_pc + 1:
                print("out of order")
            old_pc = pc
            dt = int(a[1])
            if dt == 0:
                dt = mtime
            t = t + dt
            v = int(a[2], 16)
            emit_step(ofile, v, old_v, dw, t*t_step, pc == 0)
            old_v = v
