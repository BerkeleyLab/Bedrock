# Do a pair of write/read cycles on live hardware
if [ -z $1 ]; then
  echo "Please provide an IP address"
  exit 1
fi
IP=$1
set -e
export PYTHONPATH=../../../peripheral_drivers/i2cbridge:../../common:$PYTHONPATH
python3 -m oneshot leep://$IP:803 U39.3=0x80
test "$(python3 -m oneshot leep://$IP:803 U39.3)" = "U39_3: 0x80"
python3 -m oneshot leep://$IP:803 U39.3=0x88
test "$(python3 -m oneshot leep://$IP:803 U39.3)" = "U39_3: 0x88"
