#!/usr/bin/python

# stash results from sim1.trace here
sim_result = {}
errors = 0


# find out if a and b are "pretty close" to each other
def close(a, b):
    if a < 0:
        a = -a
        b = -b
    # _srf2 needs return a > b*0.999-0.0015 and a < b*1.001+.0015
    return a > b*0.999-0.00015 and a < b*1.001+.00015


# process a line from sim1.trace
def do_trace_line(line):
    a = line.split()
    if len(a) < 5 or a[4] != "int":
        return
    sim_result[a[5]] = "%8s  %s" % (a[2], a[3])


# process a line from init.dat
def do_init_line(line):
    a = line.split()
    if len(a) < 2 or a[1][0] != "(":
        return
    var = a[-1].replace('(', '').replace(')', '')
    simx = float(sim_result[var].split()[1].strip(' ()'))
    prdx = float(a[1].strip(' ()'))
    ok = close(simx, prdx)
    # print("%f %f %d" % (simx, prdx, ok))
    linkage = "    " if ok else " xx "
    if not ok:
        global errors
        errors += 1
    print(sim_result[var] + linkage + "%s  %9s  %-4s  %-s" % tuple(a[1:5]))


# read sim1.trace, save results in sim_result
xfile = open('sim1.trace')
fdata = xfile.read()
for line in fdata.split('\n'):
    do_trace_line(line)

# helpful header
print("  Results from run    ||   Prediction from setup phase")

# read init.dat, print output as we go
xfile = open('init.dat')
fdata = xfile.read()
for line in fdata.split('\n'):
    do_init_line(line)

# report errors to invoking program, which might be make(1)
if errors:
    print("FAIL")
    exit(1)
else:
    print("PASS")
