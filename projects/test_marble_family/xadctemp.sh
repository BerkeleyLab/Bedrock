# Read the XADC internal temperature via LEEP and convert to degrees C

if [ -x $IP ]; then
  echo Usage: IP=192.168.19.31 ./xadctemp.sh
else
  python3 xadctemp.py -i $IP
fi

# Note! The '-i' above is a red-herring!  Its only purpose is to ensure that
# len(sys.argv) > 1 in case IP is not defined.  If len(sys.argv) == 1, the script
# assumes it will receive input from a pipe (via stdin) and hangs with no input.
# So without the '-i' the script would hang waiting for input.  At that point,
# you could input an IP address followed by a line break and it would attempt
# the read there.  So many ways to skin cats.
