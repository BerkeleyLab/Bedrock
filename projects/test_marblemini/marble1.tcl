set outputDir ./_xilinx
file mkdir $outputDir
create_project marble1 $outputDir -part "xc7a100t-fgg484-2" -force

set fp [open "marble1.d" r]
set file_data [read $fp]
close $fp
regsub -all "\n" $file_data " " file_data
puts $file_data
add_files $file_data
set_property top "marble1" [current_fileset]
set_property verilog_define [list "CHIP_FAMILY_7SERIES" "USE_I2CBRIDGE"] [current_fileset]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1
report_datasheet -v -file datasheet.txt

# See UG908 Appendix A
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH  2  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE   33  [current_design]

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
puts "Implementation done!"
