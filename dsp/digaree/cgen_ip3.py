#!/usr/bin/python

# Output of this program should be both valid c99 and valid input
# for the scheduler/mapper.

from cgen_lib import cgen_init, given, cpx_persist, set_result
from cgen_lib import mul, add, cpx_add, cpx_scale, cpx_triad
cgen_init("cgen_ip3.py")

cpx_persist("a3")

given("sL_r")
given("sL_i")
given("s1_r")
given("s1_i")
given("s2_r")
given("s2_i")
given("sH_r")
given("sH_i")
given("K1")
given("K2")
given("D")
given("two")

cpx_triad("x1", "sL", "s1", "s2")
cpx_triad("x2", "sH", "s2", "s1")
cpx_add("x3", "x1", "x2", 1)
cpx_scale("x4", "x3", "D", 1)
cpx_add("a3", "a3", "x4", 1)
mul("x5", "K1", "a3_i", 0)
add("h1", "a3_r", "x5", 1)
mul("h2", "K2", "a3_i", 1)
set_result("ab", "h1", "h2")
