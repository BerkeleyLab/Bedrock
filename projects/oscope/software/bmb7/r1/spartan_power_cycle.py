#!/bin/env python

from socket import *
import string
import time
import sys
import bmb7_spartan

# Start the class
x = bmb7_spartan.interface(sys.argv[1])  #, sysi2c=0x4)
print "hello"

# FMC

x.fmc_top_12v_disable()
x.fmc_bot_12v_disable()
x.fmc_top_vadj_disable()
x.fmc_bot_vadj_disable()
x.fmc_top_3p3v_disable()
x.fmc_bot_3p3v_disable()

time.sleep(1.5)
x.fmc_top_12v_enable()
x.fmc_bot_12v_enable()
x.fmc_top_vadj_enable()
x.fmc_bot_vadj_enable()
x.fmc_top_3p3v_enable()
x.fmc_bot_3p3v_enable()


