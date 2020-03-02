if { $argc < 4 } {
    puts "Not enough arguments"
    puts "Usage: vivado -mode batch -nojou -nolog -source synth_system.tcl -tclargs <board> <project_xdc> <BLOCK_RAM_SIZE> <source_files>"
    exit
}
set board [lindex $argv 0]
set vivado_xdc [lindex $argv 1]
set block_ram_size [lindex $argv 2]
set vivado_files [lrange $argv 3 end]

proc synth_design_platform {platform_name} {
    set platform "none"
    set project_part "none"

    if [regexp "ac701" $platform_name] {
        set platform "ac701"
        set project_part "xc7a200tfbg676-2"
    }
    if [regexp "kc705" $platform_name] {
        set platform "kc705"
        set project_part "xc7k325tffg900-2"
    }
    if [regexp "cmod_a7" $platform_name] {
        set platform "cmod_a7"
        set project_part "xc7a35tcpg236-1"
    }
    if [regexp "zed" $platform_name] {
        set platFORM "zed"
        set project_part "xc7z020clg484-1"
    }
    if [regexp "zc706" $platform_name] {
        set platform "zc706"
        set project_part "xc7z045ffg900-2"
    }
    if [regexp "bmb7_*" $platform_name] {
        set platform "bmb7"
        set project_part "xc7k160tffg676-2"
    }
    if [regexp "ml605" $platform_name] {
        set platform "ml605"
        set project_part "xc6vlx240tff1156-1"
    }
    if [regexp "vc707" $platform_name] {
        set platform "vc707"
        set project_part "xc7vx485tffg1761-2"
    }
    synth_design -part $project_part -top top -verilog_define BLOCK_RAM_SIZE=block_ram_size
}

read_verilog $vivado_files

read_xdc $vivado_xdc

synth_design_platform $board
opt_design
place_design
phys_opt_design
route_design

report_utilization
report_timing

write_verilog -force synth_system.v
write_bitstream -force synth_system.bit
#write_mem_info -force synth_system.mmi

