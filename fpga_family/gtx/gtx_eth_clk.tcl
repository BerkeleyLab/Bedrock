proc create_gtx_eth_mmcm {module_name} {
   create_ip -name clk_wiz -vendor xilinx.com -library ip -module_name $module_name

   set_property -dict {
      CONFIG.PRIM_IN_FREQ               {62.500}
      CONFIG.CLKOUT1_USED               {true}
      CONFIG.CLKOUT2_USED               {true}
      CONFIG.PRIMARY_PORT               {clk_in}
      CONFIG.CLK_OUT1_PORT              {gtx_clk}
      CONFIG.CLK_OUT2_PORT              {gmii_clk}
      CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {62.5}
      CONFIG.CLKOUT1_REQUESTED_PHASE    {90.0}
      CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.0}
      CONFIG.MMCM_DIVCLK_DIVIDE         {1}
      CONFIG.NUM_OUT_CLKS               {2}

   } [get_ips $module_name]
   generate_target {instantiation_template} [get_files $module_name.xci]
   generate_target all [get_files $module_name.xci]
   export_ip_user_files -of_objects [get_files $module_name.xci] -no_script -force -quiet
   create_ip_run [get_files -of_objects [get_fileset sources_1] $module_name.xci]
}

