#! /bin/sh

set -e
USAGE="USAGE: sh idelay_sweep.sh -d /dev/ttyUSBx -i \$IP [\$NPACKETS]"
IP=
DEV=
NPACKETS=100
SCRIPT_DIR=$( dirname -- "$0"; )
UDPRTX=$SCRIPT_DIR/../../badger/tests/udprtx

if [ ! -e "$UDPRTX" ]; then
  echo "$UDPRTX cannot be found.  Build with:"
  echo "  $ cd bedrock/badger/tests"
  echo "  $ make udprtx"
  exit 1
fi

devnext=0
ipnext=0
for arg in "$@"; do
  if [ $devnext != 0 ]; then
    DEV=$arg
    devnext=0
  elif [ $ipnext != 0 ]; then
    IP=$arg
    ipnext=0
  elif [ "$arg" = "-d" ]; then
    devnext=1
  elif [ "$arg" = "-i" ]; then
    ipnext=1
  else
    NPACKETS=$arg
  fi
done

if [ -z "$DEV" ]; then
  echo "$USAGE"
  exit 1
fi

if [ -z "$IP" ]; then
  echo "$USAGE"
  exit 1
fi

#for i in `seq 0 31`; do
for i in $(seq 0 31); do
  echo IDELAY = "$i"
  #echo python3 -m scrap -t $DEV 0 $i
  # Set new IDELAY count
  python3 -m scrap --silent -t "$DEV" 0 "$i"
  # Readback IDELAY count from both ctl and data blocks
  python3 -m scrap --silent -t "$DEV" 1 -r 2
  #time ./badger/tests/udprtx $IP $NPACKETS 8 2> /dev/null
  # Run udprtx stress test
  "$UDPRTX $IP $NPACKETS" 8 2> /dev/null
done
