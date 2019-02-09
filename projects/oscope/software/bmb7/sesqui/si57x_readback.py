#!/bin/env python

import qf2_pre_spartan as board
import argparse, time, datetime

parser = argparse.ArgumentParser(description='Display current SI57X settings', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
args = parser.parse_args()

# Start the class
x = board.interface(args.target)

# [0] == rfreq, [1] == n1, [2] == hsdiv
a = x.si57X_a_get()
b = x.si57X_b_get()

a_fxtal = (156.25 * (a['N1']+1) * (a['HSDIV']+4)) / (float(a['RFREQ']) / 2**28)
a_fdco = 156.25 * (a['N1']+1) * (a['HSDIV']+4)

b_fxtal = (156.25 * (b['N1']+1) * (b['HSDIV']+4)) / (float(b['RFREQ']) / 2**28)
b_fdco = 156.25 * (b['N1']+1) * (b['HSDIV']+4)

print 'SI57X_A:'
print 'RFREQ:', hex(a['RFREQ'])
print 'N1:', a['N1']+1
print 'HSDIV:', a['HSDIV']+4
print 'FXTAL:', a_fxtal
print 'FCDO:', a_fdco
print
print 'SI57X_B:'
print 'RFREQ:', hex(b['RFREQ'])
print 'N1:', b['N1']+1
print 'HSDIV:', b['HSDIV']+4
print 'FXTAL:', b_fxtal
print 'FCDO:', b_fdco

# 1300 / 7 = 185.714286
# 185.714286 * 7 * 4 = 5200.000008

print

# N1 => EVEN NUMBERS ONLY, TAKE NUMBER AND SUBTRACT ONE (e.g. 8=>7)
# HSDIV => 8 & 10 not allowed. TAKE NUMBER AND SUBTRACT FOUR (e.g. 4=>0)
a['HSDIV'] = 3
a['N1'] = 3

new_fdco = (1300.0 / 7.0) * (a['N1']+1) * (a['HSDIV']+4)
print 'New FDCO:', new_fdco

a['RFREQ'] = int(new_fdco * float(2**28) / a_fxtal)
print 'New RFREQ:', hex(a['RFREQ'])
print 'New output frequency:', a_fxtal * float(a['RFREQ']) / (2**28 * (a['N1']+1) * (a['HSDIV']+4))

# Change frequency to ~185.714285714 MHz
x.si57X_a_set(a)
