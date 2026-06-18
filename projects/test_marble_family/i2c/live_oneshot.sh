# Do a pair of write/read cycles on live hardware
if [ -z "$1" ]; then
  echo "Please provide an IP address"
  exit 1
fi
IP="$1"
LEEP="leep://$IP:803"
PYTHON=python3
set -e
export PYTHONPATH="../../../peripheral_drivers/i2cbridge:../../common:$PYTHONPATH"
$PYTHON -m oneshot "$LEEP" U39.3=0x80
test "$($PYTHON -m oneshot "$LEEP" U39.3)" = "U39_3: 0x80"
$PYTHON -m oneshot "$LEEP" U39.3=0x88
test "$($PYTHON -m oneshot "$LEEP" U39.3)" = "U39_3: 0x88"
echo "PASS"
