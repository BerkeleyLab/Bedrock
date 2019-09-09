# Needs to be run from bash, to get the job control feature used in kill command
# Quite fragile; be prepared to kill leftover jobs by hand.
# Needs the usual help from su before starting:
#  printf "tuntap add mode tap user $USER link set tap0 up\n address add 192.168.7.1 dev tap0\n route add 192.168.7.0/24 dev tap0\n" | sudo ip -batch -
IP=192.168.7.4  # VERILATOR configuration of hw_test.v
set -e
make Vhw_test
./Vhw_test 2> /dev/null &
sleep 1
python3 badger_lb_io.py --ip $IP get_rxn &
sleep 1
A=`mktemp`
curl -s tftp://$IP/testing123 > $A
echo "8470d56547eea6236d7c81a644ce74670ca0bbda998e13c629ef6bb3f0d60b69  $A" | sha256sum -c
kill %2 %1
sleep 0.2
echo "Success!"
