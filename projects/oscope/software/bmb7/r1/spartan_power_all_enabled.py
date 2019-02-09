#!/bin/env python

from socket import *
import string
import time
import sys
import bmb7_spartan

# Start the class
x = bmb7_spartan.interface(sys.argv[1])  #, sysi2c=0x4)
print "hello"

x.kintex_vccint_enable()
x.main_1p8v_enable()
x.main_3p3v_enable()

# GTX
x.spartan_1p2v_gtx_enable()
x.kintex_1p2v_gtx_enable()
x.kintex_1p0v_gtx_enable()
x.kintex_1p8v_gtx_enable()

# FMC
x.set_bottom_fmc_3p3v_resistor(0x0)
x.set_top_fmc_3p3v_resistor(0x0)
x.set_bottom_fmc_vadj_resistor(0x0)
x.set_top_fmc_vadj_resistor(0x0B)  # 2.5V instead of 3.3V

x.fmc_top_12v_enable()
x.fmc_bot_12v_enable()

x.fmc_top_vadj_enable()
x.fmc_bot_vadj_enable()
x.fmc_top_3p3v_enable()
x.fmc_bot_3p3v_enable()


