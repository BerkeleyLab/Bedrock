set prefix [lindex $argv 0]
set block_ram_size [lindex $argv 1]
set vivado_files [lrange $argv 2 end]

set platform "kc705"
set project_part "xc7k325tffg900-2"

read_verilog $vivado_files
read_xdc top.xdc

synth_design -part $project_part -top top -verilog_define BLOCK_RAM_SIZE=$block_ram_size
opt_design
place_design -directive ExtraTimingOpt
phys_opt_design
route_design

report_utilization
report_timing

write_verilog -force ${prefix}.v
write_bitstream -force ${prefix}.bit
#write_mem_info -force ${prefix}.mmi
