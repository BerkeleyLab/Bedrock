Official repository for the hardware setup will be at: https://github.com/BerkeleyLab/zest

This directory will hold the FMC pin map. Zest is a dual FMC mezzanine board with 8 ADCs and 2 DACs.

### Using zest_setup.py

This unfortunately still depends on path to bmb7 software for some reason. Needs to be cleaned up.

```
export PYTHONPATH=../../dsp/:../../projects/common/leep:/path/to/lcls2_llrf/software/bmb7
# -r resets the board, -f sets the local bus clock frequency
python zest_setup.py -a <Marblemini/QF2/BMB7 ip> -r -f 125.
```
