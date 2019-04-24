proc project_create {platform_name project_name} {
    global platform
    global project_part

    set platform "none"
    set project_part "none"
    set project_board "none"

    if [regexp "ac701" $platform_name] {
        set platform "ac701"
        set project_part "xc7a200tfbg676-2"
        set project_board "xilinx.com:ac701:part0:1.1"
    }
    if [regexp "kc705" $platform_name] {
        set platform "kc705"
        set project_part "xc7k325tffg900-2"
        set project_board "xilinx.com:kc705:part0:1.1"
    }
    if [regexp "cmod_a7" $platform_name] {
        set platform "cmod_a7"
        set project_part "xc7a35tcpg236-1"
    }
    if [regexp "zed" $platform_name] {
        set platform "zed"
        set project_part "xc7z020clg484-1"
        set project_board "em.avnet.com:zed:part0:1.3"
    }
    if [regexp "zc706" $platform_name] {
        set platform "zc706"
        set project_part "xc7z045ffg900-2"
        set project_board "xilinx.com:zc706:part0:1.2"
    }
    if [regexp "bmb7_*" $platform_name] {
        set platform "bmb7"
        set project_part "xc7k160tffg676-2"
    }
    if [regexp "qf2pre_*" $platform_name] {
        set platform "bmb7"
        set project_part "xc7k160tffg676-2"
    }
    if [regexp "ml605" $platform_name] {
        set platform "ml605"
        set project_part "xc6vlx240tff1156-1"
        set project_board "ml605"
    }
    if [regexp "vc707" $platform_name] {
        set platform "vc707"
        set project_part "xc7vx485tffg1761-2"
        set project_board "xilinx.com:vc707:part0:1.2"
    }
    # planahead
    #
    if {$platform eq "ml605"} {
        create_project $project_name ./_xilinx/$project_name -part $project_part -force
        set_property board $project_board [current_project]
        return
    }
    create_project $project_name ./_xilinx/$project_name -part $project_part -force
    if {$project_board ne "none"} {
        set_property board_part $project_board [current_project]
    }
}

proc project_bd_design {library_dir project_name} {
    set_property ip_repo_paths $library_dir [current_fileset]
    update_ip_catalog -rebuild
    # CRITICAL WARNING: [BD 41-1348] Reset pin () is connected to asynchronous reset source ().
    set_msg_config -id {BD 41-1348} -new_severity info
    set_msg_config -severity {CRITICAL WARNING} -quiet -id {BD 41-1276} -new_severity error

    set project_system_dir "./_xilinx/$project_name/$project_name.srcs/sources_1/bd/system"

    create_bd_design "system"
    source system_bd.tcl
    save_bd_design
    validate_bd_design

    make_wrapper -files [get_files system.bd] -top
    import_files -force -norecurse -fileset sources_1 $project_system_dir/hdl/system_wrapper.v
}

proc project_add_files {project_files} {
    add_files -norecurse -fileset sources_1 $project_files
    set ip_tcl_src [get_files *.tcl]
    if {! [string match "" $ip_tcl_src]} {
        foreach ip_tcl $ip_tcl_src {
            source $ip_tcl
        }
    }
    remove_files -fileset sources_1 -quiet $ip_tcl_src
    set imp_xdc_src [get_files *_imp.xdc]
    if {! [string match "" $ip_tcl_src]} {
        foreach xdc $imp_xdc_src {
            set_property USED_IN_SYNTHESIS 0 [get_files $xdc]
        }
    }
    update_compile_order -fileset sources_1
}

# planAhead
proc project_add_ucf {project_ucf} {
    import_files -fileset constrs_1 -force -norecurse $project_ucf
}

proc project_add_file {project_files} {
    add_files -norecurse -fileset sources_1 $project_files
    set_property top system_wrapper [current_fileset]
}

proc project_run_planahead {project_name} {
    update_compile_order -fileset sources_1
    #update_compile_order -fileset sim_1

    # Launch Synthesis
    launch_runs synth_1
    wait_on_run synth_1

    # Launch Implementation
    # planAhead: NGDBuild, MAP, PAR, TRCE, XDL, Bitgen
    #launch_runs impl_1 -to_step write_bitstream
    launch_runs impl_1 -to_step Bitgen
    wait_on_run impl_1
    open_run impl_1
}

proc project_run {verilog_defines} {
    update_compile_order -fileset sources_1
    #update_compile_order -fileset sim_1
    #
    # for picorv32soc
    set baz [string map {"-D" ""} $verilog_defines]
    set args [regexp -all -inline {\S+} $baz]

    # Append to existing defines, if any
    set cur_list [get_property verilog_define [current_fileset]]
    set args [list {*}$args {*}$cur_list]

    set_property verilog_define $args [current_fileset]
    puts "DEFINES:"
    puts [get_property verilog_define [current_fileset]]

    launch_runs synth_1
    wait_on_run synth_1
    open_run synth_1

    #launch_runs impl_1 -to_step write_bitstream
    launch_runs impl_1 -to_step route_design
    wait_on_run impl_1
    open_run impl_1
}

proc project_rpt {project_name} {
    # Generate implementation timing & power report
    report_power -file ./_xilinx/$project_name/imp_power.rpt
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -input_pins -file ./_xilinx/$project_name/imp_timing.rpt
    # http://xillybus.com/tutorials/vivado-timing-constraints-error
    if {! [string match -nocase {*timing constraints are met*} [report_timing_summary -no_header -no_detailed_paths -return_string]]} {
        puts "Timing constraints weren't met. Please check your design."
        exit 2
    }
}

proc project_write_bitstream {platform} {
    if {$platform ne "vc707"} {
        set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [get_designs impl_1]
    }
    set_property BITSTREAM.CONFIG.CONFIGRATE 33 [get_designs impl_1]
    write_bitstream -force [current_project].bit
}
