set outputDir ./_xilinx
file mkdir $outputDir
create_project kc705_gmii_test $outputDir -part "xc7k325t-ffg900-2" -force

set fp [open "kc705_gmii_test.d" r]
set file_data [read $fp]
close $fp
regsub -all "\n" $file_data " " file_data
puts $file_data
add_files $file_data
set_property top "gmii_hw_test" [current_fileset]
set_property verilog_define [list "CHIP_FAMILY_7SERIES" ] [current_fileset]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1
report_datasheet -v -file datasheet.txt

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
puts "Implementation done!"
