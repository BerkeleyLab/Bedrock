
proc syntax_check {verilog_files} {
  create_project -force _syntax_check _syntax_check
  create_fileset -simset checkMe
  add_files -fileset checkMe $verilog_files
  set result [check_syntax -fileset checkMe -return_string]
  if { [string match {} $result] } {
    puts "PASS"
    return -code 0
  } else {
    puts $result
    return -code 1
  }
}

set my_files [lrange $argv 0 end]

set my_files_string [join $my_files]
puts "Checking files: ( $my_files_string )"

if {[catch [syntax_check $my_files]]} {
  exit 1
} else {
  exit 0
}
