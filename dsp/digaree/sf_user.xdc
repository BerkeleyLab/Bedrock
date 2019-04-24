# Kintex

# Test-only: not for use with hardware
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

set_property CFGBVS VCCO [sf_user]
set_property CONFIG_VOLTAGE 3.3 [sf_user]

create_clock -period 2.600  -name clk -waveform {0.000 1.300}  [get_ports {clk}]
