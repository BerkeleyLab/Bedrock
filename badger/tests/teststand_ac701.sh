#!/bin/sh
#
# Loads a bitfile onto an AC701 and runs a basic check that it "works".
# Tested useful for the CI test stand (mohs) at LBNL.
# Can also act as a template for other use cases.
set -e
xc3sprog -c jtaghs1_fast ac701_rgmii_vtest.bit
echo "So far so good"
sleep 5
echo "Hope links are up"
# IP address must match that configured in hw_test.v
# Hard to get default python from top_rules.mk, just use python3
python3 badger_lb_io.py --ip 192.168.19.8 show
