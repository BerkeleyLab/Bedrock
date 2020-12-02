###############################
# MGT_GEN.tcl
#    Configuration file for the QGT_WRAP.v component which can associate pre-defined
#    protocols to specific GT instances within a Quad
#
###############################

proc add_define {new_def} {

   set def_list {}
   lappend def_list $new_def

   # Apply defines
   puts "\[MGT_GEN\] Adding to define list: $def_list"

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

   # Add all HDL generated files to working fileset
   set ip_srcs [get_files -filter {FILE_TYPE == Verilog || FILE_TYPE == VHDL} -of_objects [get_fileset $module_name]]
   add_files -norecurse -fileset sources_1 $ip_srcs
}

proc add_aux_ip {ipname config_file module_name} {

   puts "\[MGT_GEN\] Configuring ${module_name} with configuration found in ${config_file}"

   # Read in configuration dict
   set config_dict [source $config_file]

   gen_ip $ipname $module_name $config_dict
}

proc add_gt_protocol {gt_type config_file quad_num gt_num en8b10b pll_type} {

   set module_name "q${quad_num}_gt${gt_num}"

   puts "\[MGT_GEN\] Configuring ${module_name} with configuration found in ${config_file}"

   # Read in configuration list
   set config_dict [source $config_file]

   # Force gt0_usesharedlogic to '0' to prevent generation of gt{x,p}_common
   set config_dict [dict replace $config_dict CONFIG.gt0_usesharedlogic 0]

   # Create GT IP
   gen_ip "gtwizard" $module_name $config_dict

   # Enable GT in QGT_WRAP.v by setting define
   add_define "Q${quad_num}_GT${gt_num}_ENABLE"

   # Set defines to include required ports in GT instance
   if {$en8b10b == 1}     { add_define "Q${quad_num}_GT${gt_num}_8B10B_EN" }

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
         add_define "Q${quad_num}_GT${gt_num}_$pll_type"
      }
      CPLL -
      QPLL {
         if {$gt_type != "GTX"} {puts "$pll_type not supported by $gt_type" exit}
         add_define "Q${quad_num}_GT${gt_num}_$pll_type"
      }
      default {
         puts "Unsupported PLL type $pll_type"
         exit
      }
   }
}

proc add_gtcommon {config_file quad_num pll0_refclk pll1_refclk} {

   set module_name "q${quad_num}_gtcommon"

   puts "\[MGT_GEN\] Configuring ${module_name} with configuration found in ${config_file}"
   puts "\[MGT_GEN\] WARNING: PLL0 and PLL1 must always be supplied with running clocks to achieve lock."

   # Read in configuration list
   set config_dict [source $config_file]

   # Force gt0_usesharedlogic to '1' to force generation of gt{x,p}_common
   set config_dict [dict replace $config_dict CONFIG.gt0_usesharedlogic 1]

   # Create GT{X,P} IP
   gen_ip "gtwizard" $module_name $config_dict

   # Enable GT{X,P}_COMMON in QGT_WRAP.v by setting define
   add_define "Q${quad_num}_GTCOMMON_ENABLE"

   set pll0_refclk [string toupper $pll0_refclk]
   switch $pll0_refclk {
      REFCLK0 -
      REFCLK1 {
         add_define "PLL0_${pll0_refclk}"
      }
      default {
         puts "Unsupported clock source $pll0_refclk"
         exit
      }
   }

   set pll1_refclk [string toupper $pll1_refclk]
   switch $pll1_refclk {
      REFCLK0 -
      REFCLK1 {
         add_define "PLL1_${pll1_refclk}"
      }
      default {
         puts "Unsupported clock source $pll1_refclk"
         exit
      }
   }
}
