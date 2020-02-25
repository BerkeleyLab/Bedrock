# Needs to be run from bash, to get the job control feature used in kill command
# Tries to be robust, but be prepared to kill leftover jobs by hand.
set -e
case $BASH in
  *bash) : ;;
  *) echo "Need bash job control"
     exit 1 ;;
esac
echo Checking for Vmem_gateway_wrap
test -x Vmem_gateway_wrap
./Vmem_gateway_wrap +udp_port=3000 &
sleep 1
A=""
if python3 badger_lb_io.py --ip localhost --port 3000 hello; then
  A=OK
fi
kill %1  # important to do this even if the test fails
if [ "$A" = OK ]; then
  echo "Success!"
  exit
else
  exit 1
fi
