source "badger.tcl"
set build_id "marblem_rgmii_test"
set chip_id "xc7a100t-fgg484-2"
set top_module "rgmii_hw_test"
set verilog_defines [list "CHIP_FAMILY_7SERIES" "MARBLE_TEST"]
badger_build $build_id $chip_id $top_module $verilog_defines
