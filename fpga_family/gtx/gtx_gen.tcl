###############################
# GTX_GEN.tcl
#    Configuration file for the QGTX_WRAP.v component which can associate pre-defined
#    protocols to specific GTX instances within a Quad and generate the required
#    placement constraints.
###############################

set GTX_SCRIPTS_DIR [ file dirname [ file normalize [ info script ] ] ]
set PROTOCOLS      {"gtx_ethernet.tcl" "gtx_chitchat.tcl" "gtx_eth_clk.tcl"}

foreach ptc $PROTOCOLS {
   source $GTX_CONFIG_DIR/$ptc
}

proc add_gtx_protocol {quad_num gtx_num protocol} {

   set module_name "q${quad_num}_gtx${gtx_num}"

   # Enable GTX in QGTXWRAP.v by setting define
   set def_list {}
   lappend def_list "GT${gtx_num}_ENABLE"

   puts "\[GTX_GEN\] Configuring ${module_name} for $protocol"
   switch -nocase $protocol {
      "ethernet" {
         create_gtx_ethernet $module_name

         # Generate auxiliary MMCM IP
         create_gtx_eth_mmcm "gtx_eth_mmcm"
      }
      "chitchat" {
         create_gtx_chitchat $module_name

         # Set 8b10b define to include required ports in GTX instance
         lappend def_list "GT${gtx_num}_8B10B_EN"
      }
      "bsa_mps" {
         # TODO

         # Enable usage of GTREFCLK1
         lappend def_list "GTREFCLK1_EN"
      }
      "default" {
         puts "\[GTX_GEN\] Protocol $protocol not recognized. Ignoring..."
      }
   }

   # Apply defines
   puts "\[GTX_GEN\] Adding to define list: $def_list"

   set cur_list [get_property verilog_define [current_fileset]]
   set def_list [list {*}$def_list {*}$cur_list]
   set_property verilog_define $def_list [current_fileset]

   # No need to explicitly set GTX location as it can be inferred from PIN constraints
   #set PRIMITIVE_NAME     "GTXE2_CHANNEL"
   #set phys_location  	  "${PRIMITIVE_NAME}_X${quad_num}Y${gtx_num}"
   #set primitive_instance "gtxe2_i"

   #puts "Generating LOC constraint for $phys_location and instance $primitive_instance"

   ## Add constraint to GTX xdc file and read it in (cannot use set_property before design is elaborated)
   #set fp [open "${module_name}.xdc" w]
   #puts $fp "set_property LOC ${phys_location} \[get_cells -hier -filter {name=~*i_${module_name}*${primitive_instance}}\]"
   #close $fp
   #read_xdc -ref qgtx_wrap ${module_name}.xdc
}
