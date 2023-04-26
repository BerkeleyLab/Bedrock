#! /bin/sh

# Call out any testbenches that don't conform to our conventions
# USAGE: sh tblint.sh [-r] [TEST_PATH]
#        -r: Recursive mode.  By default, only the top of TEST_PATH is searched.

# Conventions:
#   0.  All test benches must have file names that end with "_tb.v"
#   1.  All test benches must pass with $display("PASS"); $finish(); and fail with
#       $display("FAIL"); $stop();
#       The exit strings must begin with "PASS" or "FAIL" which can be followed by
#       explanatory text.

recursive=0
SEARCHDIR=.
for arg in "$@"; do
  if [ "$arg" = "-r" ]; then
    recursive=1
  else
    SEARCHDIR=$arg
  fi
done

#echo "SEARCHDIR =" $SEARCHDIR

# NOTE This will fail if any filenames contain spaces (I think)
if [ $recursive -eq 1 ]; then
  TBS=$( find "$SEARCHDIR" -name "*_tb.v" )
else
  TBS=$( find "$SEARCHDIR" -maxdepth 1 -name "*_tb.v" )
fi

if [ -z "$TBS" ]; then
  exit 0
fi

# Look for empty (whitespace-only) testbenches
# TODO There must be a better way to split TBS into an array by whitespace
TBARRAY=$(echo "$TBS" | xargs -n1 echo)
#TBARRAY=$(echo "$TBS" | tr ' ' )
TBS_NONEMPTY=""
TBS_EMPTY=""
for tb in $TBARRAY; do
  # Using "-m 1", we stop searching after the first non-whitespace is found
  if [ -z "$(grep -m 1 -E '[^[:space:]]' $tb)" ]; then
  #if [ ! "$(grep -q -E '[^[:space:]]' "$tb")" ]; then
    #echo "EMPTY TESTBENCH: $tb"
    TBS_EMPTY="$TBS_EMPTY$tb "
  else
    TBS_NONEMPTY="$TBS_NONEMPTY $tb"
  fi
done

NOMATCHES=$( grep -E -L "$display\(\"PASS[^\"]*\");" $TBS_NONEMPTY )
#MATCHES=$( grep -E -l "$display\(\"PASS\");" $TBS )

#echo $MATCHES

rval=0
if [ -n "$NOMATCHES" ]; then
  echo "ERROR: Testbenches not matching exit convention found."
  echo "$NOMATCHES" | tr ' ' '\n'
  rval=1
fi

if [ -n "$TBS_EMPTY" ]; then
  echo "ERROR: Found empty testbenches."
  echo "$TBS_EMPTY" | tr ' ' '\n'
  rval=1
fi

exit $rval
