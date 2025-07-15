MAKE=${1:-make}
for dpw in $(seq 20 28 | tac); do
    rm -f cordicg_tb
    p2r=$($MAKE cordic_ptor_check DPW="$dpw" | awk '/peak/{a=$3}/rms/{print a, $3}')
    r2p=$($MAKE cordic_rtop_check DPW="$dpw" | awk '/peak/{a=$3}/rms/{print a, $3}')
    echo 18 20 "$dpw  $p2r $r2p"
done
