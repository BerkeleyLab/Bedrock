## Context
Marble-Mini is an Open Hardware FMC carrier board based on Xilinx Artix:
  see [github](https://github.com/BerkeleyLab/Marble-Mini)

Zest is an Open Hardware FMC mezzanine board with eight 125 MS/s ADC channels and two 250 MS/s DAC channels:
  see [github](https://github.com/BerkeleyLab/Zest)

## Firmware related info
prc_common.xdc
  comes from gitlab.lbl.gov:llrf-projects/lcls2_llrf
  firmware/prc/prc_common.xdc

digitizer_digital_pin.txt  comes from gitlab.lbl.gov/hardware-designs/llrf5_board_design
  board/digitizer/digitizer_digital_pin.txt
  (Zest)
  this is source; digitizer_02_fmc.sch was machine-generated from it

fmc-hpc.lst
fmc-lpc.lst
  come from gitlab.lbl.gov:hdl-libraries/board-support
  bmb7_kintex/fmc-hpc.lst
  bmb7_kintex/fmc-lpc.lst

BMB-7 naming convention:
  fmc-lpc is FMC1 is P1
  fmc-hpc is FMC2 is P2

Due to different P2 bank voltages for BMB-7 and Marble,
  need to map LVCMOS18 to LVCMOS25
  and LVDS to LVDS_25
(the P1 bank voltage is 2.5V in both cases)

example column output:
  prc_name              bmb7_iostandard  bmb7_pin  fmc_name     zest_pin
  bus_digitizer_U3[16]  LVDS_25          H23       FMC1_LA22_P  ADC_D0A_N_1


## Build FW and program Marble-Mini
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

LMK dividers in zest_setup.py for zest are set to divide the below 1400MHz down to 100MHz [This can be changed Inside zest_setup.py .. good luck]
For waveforms, using Si***_loader from:
https://github.com/yetifrisstlama/Si5xx-5x7-EVV_autoloader
```
python setFreq.py -p /dev/ttyUSB2 156.25e6 1400e6
```

### PYTHONPATH setup

Setup the right python path for software dependencies sprayed around bedrock. And bmb7 programming tools are best to get from lcls2 as they keep them up-to-date, since they have no choice.

```
cd $BEDROCK/projects/oscope/software
export PYTHONPATH=../../../dsp/:../../common:../../../board_support/zest:/home/w/work/lbl/lcls2_llrf/software/bmb7
```

### Configure zest and run oscope
Setup idelays etc on zest with zest_setup.py
```
python ../../../board_support/zest/zest_setup.py -a 192.168.19.8:803 -r -f 125
python ../software/main.py -a 192.168.19.8:803
```
