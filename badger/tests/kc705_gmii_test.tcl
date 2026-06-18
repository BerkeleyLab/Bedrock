source "badger.tcl"
set build_id "kc705_gmii_test"
set chip_id "xc7k325t-ffg900-2"
set top_module "gmii_hw_test"
set verilog_defines [list "CHIP_FAMILY_7SERIES" ]
badger_build $build_id $chip_id $top_module $verilog_defines
