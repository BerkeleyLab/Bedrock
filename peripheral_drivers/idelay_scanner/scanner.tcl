set outputDir ./vivado_project
file mkdir $outputDir
create_project scanner $outputDir -part "xc7k160tffg676-2" -force

# The following proc is stolen from build/vivado_tcl/project_proc.tcl
proc project_rpt {project_name} {
    # Generate implementation timing & power report
    report_power -file ./vivado_project/$project_name.imp_power.rpt
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file ./vivado_project/$project_name.imp_timing.rpt
    # http://xillybus.com/tutorials/vivado-timing-constraints-error
    if {! [string match -nocase {*timing constraints are met*} [report_timing_summary -no_header -no_detailed_paths -return_string]]} {
        puts "Timing constraints weren't met. Please check your design."
        exit 2
    }
}

set fp [open "scanner.d" r]
set file_data [read $fp]
close $fp
regsub -all "\n" $file_data " " file_data
puts $file_data
add_files $file_data
set_property top "scanner_shell" [current_fileset]

launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1 -to_step route_design
wait_on_run impl_1
open_run impl_1

project_rpt [current_project]

# The following two lines let Vivado create a bitfile even though
# pin assignment is unspecified.  Don't do this for designs targeted
# at real hardware!
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
write_bitstream -force [current_project]_vivado.bit

puts "Implementation done!"
