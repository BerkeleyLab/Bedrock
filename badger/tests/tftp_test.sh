# Needs to be run from bash, to get the job control feature used in kill command
# Tries to be robust, but be prepared to kill leftover jobs by hand.
# Needs the usual help from su before starting:
#  printf "tuntap add mode tap user $USER link set tap0 up\n address add 192.168.7.1 dev tap0\n route add 192.168.7.0/24 dev tap0\n" | sudo ip -batch -
set -e
case $BASH in
  *bash) : ;;
  *) echo "Need bash job control"
     exit 1 ;;
esac
if true; then
  IP=192.168.7.4  # Verilator configuration of hw_test.v
  make Vhw_test
  ./Vhw_test 2> /dev/null &
else
  IP=192.168.7.6  # pure Verilog configuration in hw_test_tb.v
  make hw_test_tb tap-vpi.vpi
  vvp -n hw_test_tb &
fi
sleep 1
python3 badger_lb_io.py --ip $IP get_rxn &
sleep 1
echo "background job setup complete?"
jobs
trap "echo aargh; kill %2 %1; sleep 0.2; echo FAULT" ERR
ping -c 2 $IP
A=`mktemp`
curl -s tftp://$IP/testing123 > $A
echo "8470d56547eea6236d7c81a644ce74670ca0bbda998e13c629ef6bb3f0d60b69  $A" | sha256sum -c
echo "tftp succeeded, killing tftp server"
kill %python || echo wtf1
echo "sleeping"
sleep 0.2
echo "attempting to stop simulation"
python3 badger_lb_io.py --ip $IP stop_sim
echo "ok"
sleep 1
jobs
kill %1 || echo "simulation already stopped, as requsted"
sleep 0.2
echo "Success!"
