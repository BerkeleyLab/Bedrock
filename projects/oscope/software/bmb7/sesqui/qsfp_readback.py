#!/bin/env python

import qf2_pre_spartan as board
import argparse, time, datetime
from qsfp_info import *

parser = argparse.ArgumentParser(description='Display current SI57X settings', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
args = parser.parse_args()

# Start the class
x = board.interface(args.target)

#v = x.spartan_qsfp_get()
#v = x.kintex_qsfp_1_get()
v = x.kintex_qsfp_2_get()

for key, value in v.iteritems():
    print key, ':', value

print

