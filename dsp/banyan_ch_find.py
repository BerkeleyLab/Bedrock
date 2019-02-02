# Keep in mind that I keep bit/channel numbering consistent, but
# it can look inconsistent: when they are arranged in a binary word,
# lsb is on the right, but when they are printed as a python list,
# lsb is on the left.

# This is written in python2.  My first attempts to make it python3
# crashed and burned.
from __future__ import print_function

# returns the correctly ordered list of channels,
# or a blank list if the mask is invalid.
def banyan_ch_find(mask):
	mw = 8
	state = list(map(lambda y: (y, mask >> y & 1), range(mw)))
	ch_count = sum(x[1] for x in state)
	# print("banyan_ch_find", mask, ch_count)
	if ch_count == 1 or ch_count == 2 or ch_count == 4 or ch_count == 8:
		return banyan_layer_permute(state)
	else:
		return []

# computations for a single layer; note the recursion
def banyan_layer_permute(state):
	ch_count = sum(x[1] for x in state)
	# print(ch_count, state)
	if ch_count > 1:
		# balance
		npt = len(state)
		lower = state[0:npt//2]
		upper = state[npt//2:npt]
		imbalance = 0
		for ix in range(npt//2):
			if imbalance:
				swap = not upper[ix][1] and lower[ix][1]
			else:
				swap = upper[ix][1] and not lower[ix][1]
			imbalance = imbalance ^ upper[ix][1] ^ lower[ix][1]
			if swap:
				tmp = upper[ix]
				upper[ix] = lower[ix]
				lower[ix] = tmp
		return banyan_layer_permute(lower) + banyan_layer_permute(upper)
	else:
		# no dealing here, just return
		result = [x[0] for x in state if x[1]]
	return result

def test1():
	for mask in range(256):
		o = banyan_ch_find(mask)
		if o:
			print("%2.2x"%(mask, o))

def test2(fd, verbose):
	# feed this the output of vvp -n banyan_tb +trace +squelch
	fail = 0
	mask_seen = {}
	for l in fd.readlines():
		l = l.rstrip()
		if l == "PASS": continue
		a = l.split(" ")
		mask = int(a[0], 16)
		if not (mask in mask_seen):
			vvp = [int(x) for x in a[12:4:-1] if x != "."]
			chk = banyan_ch_find(mask)
			fault = chk != vvp
			if fault | verbose:
				print("{} {} {}".format(a[0], a[3], vvp), end="")
				if fault:
					print("{} {} {}".format("!=", chk, "FAULT"))
					fail = 1
				else:
					print(".")
		mask_seen[mask] = 1
	# 107 = 1+70+28+8
	if fail or len(mask_seen) != 107:
		print("{} {}".format("FAIL", len(mask_seen)))
		sys.exit(fail)
	print("PASS")

if __name__ == "__main__":
	import sys
	if len(sys.argv) > 1 and sys.argv[1] == "genlist":
		test1()
	else:
		verbose = len(sys.argv) > 1 and sys.argv[1] == "verbose"
		test2(sys.stdin, verbose)
