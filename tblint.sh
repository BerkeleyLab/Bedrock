#! /bin/sh

# Call out any testbenches that don't conform to our conventions
# USAGE: sh tblint.sh [-r] [TEST_PATH]
#        -r: Recursive mode.  By default, only the top of TEST_PATH is searched.

# Convetions:
#   0.  All test benches must have file names that end with "_tb.v"
#   1.  All test benches must pass with $display("PASS"); $finish(); and fail with
#       $display("FAIL"); $stop();

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
  TBS=$( find "$SEARCHDIR" -name *_tb.v )
else
  TBS=$( find "$SEARCHDIR" -maxdepth 1 -name *_tb.v )
fi

if [ -z "$TBS" ]; then
  exit 0
fi

NOMATCHES=$( grep -E -L "$display\(\"PASS\");" $TBS )
#MATCHES=$( grep -E -l "$display\(\"PASS\");" $TBS )

#echo $MATCHES

if [ ! -z "$NOMATCHES" ]; then
  echo "ERROR: Testbenches not matching exit convention found."
  echo $NOMATCHES | tr ' ' '\n'
  exit 1
fi
