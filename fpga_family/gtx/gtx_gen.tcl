###############################
# GTX_GEN.tcl
#    Configuration file for the QGTX_WRAP.v component which can associate pre-defined
#    protocols to specific GTX instances within a Quad
#
###############################

proc gen_ip {ipname module_name config_dict} {
   create_ip -name $ipname -vendor xilinx.com -library ip -module_name $module_name

   # Set config settings
   set_property -dict $config_dict [get_ips $module_name]

   generate_target {instantiation_template} [get_files $module_name.xci]
   generate_target all [get_files  $module_name.xci]
   export_ip_user_files -of_objects [get_files $module_name.xci] -no_script -force -quiet
   create_ip_run [get_files -of_objects [get_fileset sources_1] $module_name.xci]
}

proc add_aux_ip {ipname config_file module_name} {

   puts "\[GTX_GEN\] Configuring ${module_name} with configuration found in ${config_file}"

   # Read in configuration dict
   set config_dict [source $config_file]

   gen_ip $ipname $module_name $config_dict
}

proc add_gtx_protocol {config_file quad_num gtx_num en8b10b enGTREFCLK1} {

   set module_name "q${quad_num}_gtx${gtx_num}"

   # Enable GTX in QGTXWRAP.v by setting define
   set def_list {}
   lappend def_list "GT${gtx_num}_ENABLE"

   puts "\[GTX_GEN\] Configuring ${module_name} with configuration found in ${config_file}"

   # Read in configuration list
   set config_dict [source $config_file]

   # Create GTX IP
   gen_ip "gtwizard" $module_name $config_dict

   # Set defines to include required ports in GTX instance
   if {$en8b10b == 1}     { lappend def_list "GT${gtx_num}_8B10B_EN" }
   if {$enGTREFCLK1 == 1} { lappend def_list "GTREFCLK1_EN" }

   # Apply defines
   puts "\[GTX_GEN\] Adding to define list: $def_list"

   set cur_list [get_property verilog_define [current_fileset]]
   set def_list [list {*}$def_list {*}$cur_list]
   set_property verilog_define $def_list [current_fileset]
}
