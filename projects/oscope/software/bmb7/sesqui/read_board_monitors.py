#!/bin/env python

import qf2_pre_spartan as board
import argparse, time, datetime

parser = argparse.ArgumentParser(description='Display QF2-pre monitors', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
args = parser.parse_args()

# Start the class
x = board.interface(args.target)

while True:
    x.print_monitors()
    print('------------------------' + str(datetime.datetime.now()) + '------------------------')
    time.sleep(1)
