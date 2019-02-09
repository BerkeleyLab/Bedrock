#!/bin/env python

import bmb7_spartan as board
import argparse
import time
import datetime

parser = argparse.ArgumentParser(
    description='Display BMB7 monitors',
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument(
    '-t',
    '--target',
    default='192.168.1.127',
    help='Current unicast IP address of board')
parser.add_argument('-n', '--number', default=0, help='Number of iterations')
args = parser.parse_args()

# Start the class
x = board.interface(args.target)

n_goal = int(args.number)
n = 0  # count of number of iterations performed
while True:
    x.print_monitors()
    print('------------------------' + str(datetime.datetime.now()) +
          '------------------------')
    n += 1
    if n_goal > 0 and n >= n_goal:
        break
    time.sleep(1)
