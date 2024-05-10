set outputDir ./_xilinx
file mkdir $outputDir
set build_id ac701_rgmii_test
create_project $build_id $outputDir -part "xc7a200t-fbg676-2" -force

set fp [open "ac701_rgmii_test.d" r]
set file_data [read $fp]
close $fp
regsub -all "\n" $file_data " " file_data
puts $file_data
add_files $file_data
set_property top "rgmii_hw_test" [current_fileset]
set_property verilog_define [list "CHIP_FAMILY_7SERIES" ] [current_fileset]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1

launch_runs impl_1 -to_step route_design
wait_on_run impl_1
puts "Implementation done!"

# Supposed to match version in project_proc.tcl and marble.tcl
# dest_dir is where the report files go
proc project_rpt {dest_dir} {
    # Generate implementation timing & power report
    report_power -file $dest_dir/imp_power.rpt
    report_datasheet -v -file $dest_dir/imp_datasheet.rpt
    report_cdc -v -details -file $dest_dir/cdc_report.rpt
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file $dest_dir/imp_timing.rpt
    # http://xillybus.com/tutorials/vivado-timing-constraints-error
    if {! [string match -nocase {*timing constraints are met*} [report_timing_summary -no_header -no_detailed_paths -return_string]]} {
        puts "Timing constraints weren't met. Please check your design."
        exit 2
    }
}

open_run impl_1
file mkdir $outputDir/$build_id.reports
project_rpt $outputDir/$build_id.reports

launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
puts "Bitfile written!"
