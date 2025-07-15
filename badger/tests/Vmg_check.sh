# Needs to be run from bash, to get the job control feature used in kill command
# argv[1] is the badger_lb_io.py program (with full path, to support oot runs)
# Tries to be robust, but be prepared to kill leftover jobs by hand.
set -e
case $BASH in
  *bash) : ;;
  *) echo "Need bash job control"
     exit 1 ;;
esac
echo Checking for Vmem_gateway_wrap
test -x Vmem_gateway_wrap
echo Checking for badger_lb_io.py
test -r "$1"
echo Starting simulation as background job
./Vmem_gateway_wrap +udp_port=3000 &
sleep 1
A=""
if python3 "$1" --ip localhost --port 3000 hello; then
  A=OK
fi
kill %1  # important to do this even if the test fails
if [ "$A" = OK ]; then
  echo "Success!"
  exit
else
  exit 1
fi
