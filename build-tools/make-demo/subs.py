# Stupidest little text processor that can handle file includes.
# With a little effort we could use m4 or cpp instead.
import sys


def f_include(f):
    print(open(f).read())


for ll in sys.stdin.readlines():
    ll = ll.rstrip()
    a = ll.split()
    if len(a) > 1 and a[0] == "#include":
        f_include(a[1])
    else:
        print(ll.rstrip())
