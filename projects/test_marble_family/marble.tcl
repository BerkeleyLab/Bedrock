set outputDir ./_xilinx
file mkdir $outputDir


# Read in dependencies file
set flist [lindex $argv 0]
puts "Obtaining dependencies from $flist"

# Read in build identifier
set build_id [lindex $argv 1]
puts "Building for $build_id"

if { $build_id == "marble1" } {
   set part "xc7a100t-fgg484-2"
} else {
   set part "xc7k160t-ffg676-2"
}
puts "Synthesizing for part $part"

create_project $build_id $outputDir -part $part -force

set fp [open $flist r]
set file_data [read $fp]
close $fp
regsub -all "\n" $file_data " " file_data
puts $file_data
add_files $file_data
set_property top "marble_top" [current_fileset]
set_property verilog_define [list "CHIP_FAMILY_7SERIES"] [current_fileset]

# Get git commit ID
set gitid [exec git rev-parse --short=8 --verify HEAD]
set gitid_v 32'h$gitid
set new_defs [list "GIT_32BIT_ID=$gitid_v" "REVC_1W"]

launch_runs synth_1
wait_on_run synth_1
open_run synth_1
report_datasheet -v -file datasheet.txt

# See UG908 Appendix A
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH  2  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE   33  [current_design]

launch_runs impl_1 -to_step route_design
wait_on_run impl_1
puts "Implementation done!"
open_run impl_1
write_bitstream -force $build_id.$gitid.bit
