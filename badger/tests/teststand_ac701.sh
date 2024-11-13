#!/bin/sh
#
# Loads a bitfile onto an AC701 and runs a basic check that it "works".
# Tested useful for the CI test stand (mohs) at LBNL.
# Can also act as a template for other use cases.
set -e
xc3sprog -c jtaghs1_fast $SERIAL_NUM_OPT ac701_rgmii_vtest.bit
echo "So far so good"
sleep 8
echo "Hope links are up"
# IP address must match that configured in hw_test.v
RGMII_IP=192.168.19.8
ping -c 2 $RGMII_IP
# It's hard to get default python from top_rules.mk, so just use python3
python3 badger_lb_io.py --ip $RGMII_IP show
make udprtx
./udprtx $RGMII_IP 200000 9
