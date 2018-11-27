for dpw in `seq 20 28 | tac`; do
    rm -f cordicg_tb
    p2r=`make cordic0_test DPW=$dpw | awk '/peak/{a=$3}/rms/{print a, $3}'`
    r2p=`make cordic1_test DPW=$dpw | awk '/peak/{a=$3}/rms/{print a, $3}'`
    echo 18 20 "$dpw " $p2r $r2p
done
