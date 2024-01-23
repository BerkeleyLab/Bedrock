#! python3

# Compare live data of locking VCXO to precision 1pps signal to modeled behavior

import sys
import os
# import numpy
sys.path.append(os.path.join(os.getcwd(), "pps_lock"))
import lock_vcxo
import transient


def time_transient():
    data = transient.getTransient()
    f, g_df, g_dp, g_dp2, A = data


def time_record(args):
    log = lock_vcxo.monitor(
        addr=args.addr,
        port=int(args.port),
        init_val=int(args.val),
        npts=int(args.npts),
        dac_n=int(args.dac),
        use_fir=args.fir,
        cont=args.cont,
        timeout=int(args.timeout),
        verbose=args.verbose,
        log=True
    )
    # log = [(dac, dsp_on, dsp_arm, pha, pps_cnt, cfg, rct, pps_lcnt),]
    print(log)


if __name__ == "__main__":
    parser = lock_vcxo.ArgumentParser()
    args = parser.parse_args()
    print(f"args = {args}")
    print(f"dir(args) = {dir(args)}")
    print(f"type(args) = {type(args)}")
    time_record(args)
