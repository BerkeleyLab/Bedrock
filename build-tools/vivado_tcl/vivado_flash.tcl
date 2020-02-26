set design_bit [lindex $argv 0]
set design_mcs [lindex $argv 1]
set interface [lindex $argv 2]
# interface: spix4 or bpix16
write_cfgmem -format mcs -interface $interface -size 128 -loadbit "up 0x0 $design_bit" -file $design_mcs -force
exit
