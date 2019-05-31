set prefix [lindex $argv 0]
set mem_size [lindex $argv 1]
set vivado_files [lrange $argv 2 end]

set platform     "cmod_a7"
set project_part "xc7a35tcpg236-1"

read_verilog $vivado_files
read_xdc top.xdc

# -verilog_define MEMORY_PACK_FAST
synth_design -part $project_part -top top -verilog_define MEM_SIZE=$mem_size -verilog_define MEMORY_PACK_FAST
opt_design
place_design -directive ExtraTimingOpt
phys_opt_design
route_design

report_utilization
report_timing

write_verilog -force ${prefix}.v
write_bitstream -force ${prefix}.bit
#write_mem_info -force ${prefix}.mmi
