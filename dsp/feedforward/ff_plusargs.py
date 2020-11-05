from sys import argv
import json
with open(argv[1]) as f:
    setup = json.load(f)

dt = setup["dt"]
tau = setup["tau"]
sim_expand = setup["sim_expand"]
cavity = dt/tau*2**22
couple = setup["couple"] * cavity
# print(cavity, couple)

if False:  # historical
    couple = 67500
    cavity = 83030

a = {}
a["c0"] = couple
a["c1"] = -cavity
a["sim_expand"] = sim_expand
args = ["+%s=%d" % (k, a[k]) for k in sorted(a.keys())]
print(" ".join(args))
