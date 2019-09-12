###############################
# GTX_GEN.tcl
#    Configuration file for the QGTX_WRAP.v component which can associate pre-defined
#    protocols to specific GTX instances within a Quad
#
###############################

proc add_define {new_def} {

   set def_list {}
   lappend def_list $new_def

   # Apply defines
   puts "\[GTX_GEN\] Adding to define list: $def_list"

   set cur_list [get_property verilog_define [current_fileset]]
   set def_list [list {*}$def_list {*}$cur_list]
   set_property verilog_define $def_list [current_fileset]
}

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

proc add_gt_protocol {gt_type config_file quad_num gtx_num en8b10b pll_type} {

   set module_name "q${quad_num}_gtx${gtx_num}"

   puts "\[GTX_GEN\] Configuring ${module_name} with configuration found in ${config_file}"

   # Read in configuration list
   set config_dict [source $config_file]

   # Force gt0_usesharedlogic to '0' to prevent generation of gt{x,p}_common
   set config_dict [dict replace $config_dict CONFIG.gt0_usesharedlogic 0]

   # Create GTX IP
   gen_ip "gtwizard" $module_name $config_dict

   # Enable GTX in QGTXWRAP.v by setting define
   add_define "Q${quad_num}_GT${gtx_num}_ENABLE"

   # Set defines to include required ports in GTX instance
   if {$en8b10b == 1}     { add_define "Q${quad_num}_GT${gtx_num}_8B10B_EN" }

   set gt_type [string toupper $gt_type]
   switch $gt_type {
      GTX -
      GTP {
         add_define "GT_TYPE__${gt_type}"
      }
      default {
         puts "Unsupported gigabit transceiver type $gt_type"
         exit
      }
   }

   set pll_type [string toupper $pll_type]
   switch $pll_type {
      PLL0 -
      PLL1 {
         if {$gt_type != "GTP"} {puts "$pll_type not supported by $gt_type" exit}
         add_define "q${quad_num}_gt${gtx_num}_$gt_type"
      }
      CPLL -
      QPLL {
         if {$gt_type != "GTX"} {puts "$pll_type not supported by $gt_type" exit}
         add_define "Q${quad_num}_GT${gtx_num}_$gt_type"
      }
      default {
         puts "Unsupported PLL type $pll_type"
         exit
      }
   }
}

proc add_gtcommon {config_file quad_num} {

   set module_name "q${quad_num}_gtcommon"

   # Enable GT{X,P}_COMMON in QGTXWRAP.v by setting define
   add_define "Q${quad_num}_GTCOMMON_ENABLE"

   puts "\[GTX_GEN\] Configuring ${module_name} with configuration found in ${config_file}"

   # Read in configuration list
   set config_dict [source $config_file]

   # Force gt0_usesharedlogic to '1' to force generation of gt{x,p}_common
   set config_dict [dict replace $config_dict CONFIG.gt0_usesharedlogic 1]

   # Create GT{X,P} IP
   gen_ip "gtwizard" $module_name $config_dict
}
