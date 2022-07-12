
proc ip_create {ip_name ip_path} {
  create_project $ip_name $ip_path/_vivado -force

  set proj_dir [get_property directory [current_project]]
  set proj_name [get_projects $ip_name]
}

proc ip_files {ip_name ip_files} {

  set proj_fileset [get_filesets sources_1]
  add_files -norecurse -scan_for_includes -fileset $proj_fileset $ip_files
  # import_files -norecurse -fileset $proj_fileset $ip_files
  set_property "top" "$ip_name" $proj_fileset
}

proc ip_constraints {ip_name ip_constr_files} {

  set proj_filegroup [ipx::get_file_group xilinx_verilogsynthesis [ipx::current_core]]
  ipx::add_file $ip_constr_files $proj_filegroup
  set_property type {{xdc}} [ipx::get_file $ip_constr_files $proj_filegroup]
  set_property library_name {} [ipx::get_file $ip_constr_files $proj_filegroup]
}

proc ip_properties {ip_name ip_version vendor} {

  ipx::package_project -import_files -root_dir [get_property directory [current_project]]/../

  if {$vendor eq "lbl"} {
    set_property vendor {lbl.gov} [ipx::current_core]
    set_property vendor_display_name {LBNL} [ipx::current_core]
    set_property company_url {www.lbl.gov} [ipx::current_core]
  } elseif {$vendor eq "xilinx"} {
    set_property vendor {xilinx.com} [ipx::current_core]
    set_property vendor_display_name {Xilinx} [ipx::current_core]
    set_property company_url {www.xilinx.com} [ipx::current_core]
  } else {
    set_property vendor {lbl.gov} [ipx::current_core]
    set_property vendor_display_name {LBNL} [ipx::current_core]
    set_property company_url {www.lbl.gov} [ipx::current_core]
  }
  set_property library {user} [ipx::current_core]
  set_property version $ip_version [ipx::current_core]
  set_property sim.ip.auto_export_scripts false [current_project]

  set_property supported_families \
    {{kintex7}    {Production} \
     {artix7}     {Production} \
     {virtex7}    {Production} \
     {zynq}       {Production} \
     {zynquplus}  {Production} \
    } [ipx::current_core]
}

proc set_ports_dependency {port_prefix dependency} {
	foreach port [ipx::get_ports [format "%s%s" $port_prefix "*"]] {
		set_property ENABLEMENT_DEPENDENCY $dependency $port
	}
}

proc set_bus_dependency {bus prefix dependency} {
	set_property ENABLEMENT_DEPENDENCY $dependency [ipx::get_bus_interface $bus [ipx::current_core]]
	set_ports_dependency $prefix $dependency
}

proc add_port_map {bus phys logic} {
	set map [ipx::add_port_map $phys $bus]
	set_property "PHYSICAL_NAME" $phys $map
	set_property "LOGICAL_NAME" $logic $map
}

proc add_bus {bus_name bus_type mode port_maps} {
	set bus [ipx::add_bus_interface $bus_name [ipx::current_core]]
        set abst_type $bus_type

	set_property "ABSTRACTION_TYPE_LIBRARY" "interface" $bus
	set_property "ABSTRACTION_TYPE_NAME" $abst_type $bus
	set_property "ABSTRACTION_TYPE_VENDOR" "xilinx.com" $bus
	set_property "ABSTRACTION_TYPE_VERSION" "1.0" $bus
	set_property "BUS_TYPE_LIBRARY" "interface" $bus
	set_property "BUS_TYPE_NAME" $bus_type $bus
	set_property "BUS_TYPE_VENDOR" "xilinx.com" $bus
	set_property "BUS_TYPE_VERSION" "1.0" $bus
	set_property "CLASS" "bus_interface" $bus
	set_property "INTERFACE_MODE" $mode $bus

	foreach port_map $port_maps {
		add_port_map $bus {*}$port_map
	}
}
