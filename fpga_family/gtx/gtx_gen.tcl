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

   puts "Configuring ${module_name} for $protocol"
   switch -nocase $protocol {
      "ethernet" {
         create_gtx_ethernet $module_name

         # Generate auxiliary MMCM IP
         create_gtx_eth_mmcm "gtx_eth_mmcm"
      }
      "chitchat" {
         create_gtx_chitchat $module_name
      }
      "default" {
         puts "Protocol $protocol not recognized. Ignoring..."
      }
   }

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
