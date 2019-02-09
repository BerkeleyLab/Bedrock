if { $argc <5 } {
    puts "Not enough arguments"
    puts "Usage: vivado -mode batch -nojou -nolog -source project_proc.tcl vivado_project.tcl -tclargs <platform_name> <project_name> <project_xdc> <source_files>"
    exit
}
set my_platform_name [lindex $argv 0]
set my_proj_name [lindex $argv 1]
set my_verilog_defines [lindex $argv 2]
set my_proj_files [lrange $argv 3 end]

project_create $my_platform_name $my_proj_name
project_add_files $my_proj_files
project_run $my_verilog_defines
project_rpt $my_proj_name
project_write_bitstream $my_platform_name
