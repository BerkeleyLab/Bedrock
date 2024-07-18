# set PYTHONPATH to get access to lbus_access
PYTHON=python3
PORT=3010
$PYTHON -m lbus_access -a localhost -p $PORT mem 0x04:1 0x60:16
$PYTHON -m lbus_access -a localhost -p $PORT reg 0x100=1
$PYTHON -m lbus_access -a localhost -p $PORT mem 0x04:1 0x60:16
$PYTHON -m lbus_access -a localhost -p $PORT reg 0x200=1
