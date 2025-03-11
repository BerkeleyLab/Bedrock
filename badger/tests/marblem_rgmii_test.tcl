source "badger.tcl"
set build_id "marblem_rgmii_test"
# set chip_id "xc7a100t-fgg484-2"
# hypothetical Marble-gold
# set chip_id "xcau15p-sbvb484-1-e"
# Avnet AUBoard 15P, but lie about speed grade
set   chip_id "xcau15p-ffvb676-1-e"
set top_module "rgmii_hw_test"
# set verilog_defines [list "CHIP_FAMILY_7SERIES" "MARBLE_TEST"]
set verilog_defines [list "CHIP_FAMILY_ULTRASCALE" "MARBLE_TEST"]
badger_build $build_id $chip_id $top_module $verilog_defines
