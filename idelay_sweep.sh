#! /bin/sh

IP=192.168.19.31
DEV=/dev/ttyUSB2
NPACKETS=100

for i in `seq 0 31`; do
  echo IDELAY = $i
  python3 -m scrap -t $DEV 0 $i > /dev/null 2>&1
  #time ./badger/tests/udprtx $IP $NPACKETS 8 2> /dev/null
  ./badger/tests/udprtx $IP $NPACKETS 8 2> /dev/null
done
