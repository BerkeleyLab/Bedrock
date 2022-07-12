# Usage: "vivado -mode batch -source create_ip.tcl -tclargs <source_files>"
if { $argc <4 } {
    puts "Not enough arguments"
    puts "Usage: vivado -mode batch -source create_ip.tcl -tclargs <ip_name> <ip_path> <ip_version> <source_files>"
    exit
}

set ip_name [lindex $argv 0]
set ip_path [lindex $argv 1]
set ip_version [lindex $argv 2]
set my_ip_files [lrange $argv 3 end]

ip_create $ip_name $ip_path
ip_files $ip_name $my_ip_files
update_compile_order -fileset sources_1

if {![info exists ip_vendor]} {
    set ip_vendor "lbl"
}

ip_properties $ip_name $ip_version $ip_vendor

ipx::save_core [ipx::current_core]
