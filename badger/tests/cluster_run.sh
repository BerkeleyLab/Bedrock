#!/bin/sh
# Needs to be run from bash, to get the job control feature used in kill command
# Tries to be robust, but be prepared to kill leftover jobs by hand.
PYTHON=python3
set -e
case $BASH in
  *bash) : ;;
  *) echo "Need bash job control"
     exit 1 ;;
esac

# prep work should be in Makefile: make Vcluster
test -x ./Vcluster
./Vcluster 2> /dev/null &
sleep 1

# Note that unlike speed_check.sh teststand_ac701.sh tftp_test.sh
# this script uses leep commands from outside the badger directory
(
$PYTHON -m leep.cli leep://localhost:3010 gitid
$PYTHON -m leep.cli leep://localhost:3011 gitid
$PYTHON -m leep.cli leep://localhost:3012 gitid
$PYTHON -m leep.cli leep://localhost:3012 reg scratch_out=7777 scratch_out
$PYTHON -m leep.cli leep://localhost:3011 reg scratch_in_r scratch_out=8888 scratch_out
$PYTHON -m leep.cli leep://localhost:3010 reg scratch_in_r scratch_out=9999 scratch_out
$PYTHON -m leep.cli leep://localhost:3012 reg scratch_in_r
) | tr '\t' ' ' > cluster_run.out
# $PYTHON -m leep.cli leep://localhost:3010 reg stop_sim=1
$PYTHON -m badger_lb_io --ip localhost --port 3010 stop_sim

sleep 1
jobs
kill %1 || echo "simulation already stopped, as requested"
sleep 0.3
echo "OK"
