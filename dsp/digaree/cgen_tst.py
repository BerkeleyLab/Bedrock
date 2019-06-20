#!/usr/bin/python

# Test pattern substituting for SRF cavity analog state computer
# Takes in cavity field, forward, and reverse vector measurements
# and emits a test pattern standing in for the cavity detune frequency.

# Output of this program should be both valid c99 and valid input
# for the scheduler/mapper.
# See the rest of the Digaree infrastructure for details.

from cgen_lib import cgen_init, given, mul, add, sub, cpx_mul
from cgen_lib import cpx_scale
from cgen_lib import cpx_mag, set_result, cpx_persist, cpx_add
cgen_init("cgen_srf.py")

# History of measured cavity voltages, used to compute dV/dt
# Initial value in simulation should be settable from initgen?
# Cut-and-paste for now, until we at least get the right answer.
cpx_persist("sv")

# These lines declare the input variables,
# first six streamed from the radio
given("k_r")  # forward
given("k_i")  # forward
given("r_r")  # reverse
given("r_i")  # reverse
given("v_r")  # cavity
given("v_i")  # cavity
# next eight host-settable
given("beta_r")
given("beta_i")
given("invT")
given("two")  # needed by 1/x macro
given("sclr")
given("sclf")
given("kick_r")
given("kick_i")

# Start-up plan:
#   beta = 1
#   kick = 0.1
#   (wait)
#   kick = 0
#   (wait)
#   beta = exp(j*theta)
# should then get a sine wave with frequency theta/dT
cpx_mul("x1", "sv", "beta", 1, 1)  # rotate by theta, beta = exp(j*theta)
cpx_add("x2", "x1", "kick", 1)
cpx_mag("m1", "x2", 0)
sub("m2", "two", "m1", 2)
cpx_scale("sv", "x2", "m2", 2)

set_result("ab", "sv_r", "sv_i")

# Copied from real srf version
# Power balance measure of cavity dissipation; uses magnitudes only
cpx_mag("magr", "r", 0)  # reverse
mul("powr", "sclr", "magr", 0)
cpx_mag("magf", "k", 0)  # forward
mul("powf", "sclf", "magf", 0)
sub("wgnet", "powf", "powr", 1)  # net power transferred by waveguide

# Made-up
cpx_mag("magv", "v", 0)
add("diss", "wgnet", "magv", 0)
set_result("cd", "diss", "invT")
