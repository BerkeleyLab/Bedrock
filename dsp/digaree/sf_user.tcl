set outputDir ./vivado_project
file mkdir $outputDir
create_project sf_user $outputDir -part "xc7k160tffg676-2" -force

set fp [open "sf_user.d" r]
set file_data [read $fp]
close $fp
regsub -all "\n" $file_data " " file_data
puts $file_data
add_files $file_data
set_property  top "sf_user" [current_fileset]
launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
puts "Implementation done!"
