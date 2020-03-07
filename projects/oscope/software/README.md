## Program Marblemini
```
cd $BEDROCK/projects/oscope/marblemini
make clean && make oscope_top.bit
openocd -f ../../../board_support/marblemini/marble.cfg -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 oscope_top.bit; exit"
```
Check if it's up
```
ping 192.168.19.8
```

## Zest related initialization
### Clock frequency
Currently OSCOPE lb/system clock works in 125MHz domain.

With below ADC clock domain can be set to 100MHz

LMK dividers in prc.py for zest are set to divide the below 1400MHz down to 100MHz [This can be changed Inside prc.py .. good luck]
For waveforms, using Si***_loader from:
https://github.com/yetifrisstlama/Si5xx-5x7-EVV_autoloader
```
python setFreq.py -p /dev/ttyUSB2 156.25e6 1400e6
```

### PYTHONPATH setup

Setup the right python path for software dependencies sprayed around bedrock. And bmb7 programming tools are best to get from lcls2 as they keep them up-to-date, since they have no choice.

```
cd $BEDROCK/projects/oscope/software
export PYTHONPATH=../../../dsp/:../../../build-tools:../../..:../../common:../../../board_support/zest:/home/fubar/work/lbl/lcls2_llrf/software/bmb7
```

### Configure zest and run oscope
Setup idelays etc on zest with prc.py [this should be changed to zest.py]
```
python prc.py -a 192.168.19.8 -p 803 -r -f 125
python oscope.py -a 192.168.19.8 -p 803
```
