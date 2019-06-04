# Constraints specific to BMB7 r1 board for prc build

# D4: RGB LED
set_property IOSTANDARD LVCMOS18 [get_ports bus_bmb7_D4[*]]
set_property PACKAGE_PIN M16 [get_ports bus_bmb7_D4[0]]
set_property PACKAGE_PIN L17 [get_ports bus_bmb7_D4[1]]
set_property PACKAGE_PIN M17 [get_ports bus_bmb7_D4[2]]

# D5: RGB LED
set_property IOSTANDARD LVCMOS18 [get_ports bus_bmb7_D5[*]]
set_property PACKAGE_PIN L20 [get_ports bus_bmb7_D5[0]]
set_property PACKAGE_PIN L18 [get_ports bus_bmb7_D5[1]]
set_property PACKAGE_PIN L19 [get_ports bus_bmb7_D5[2]]

# U7: link to Spartan
set_property IOSTANDARD LVCMOS33 [get_ports bus_bmb7_U7[*]]
set_property PACKAGE_PIN J8 [get_ports bus_bmb7_U7[0]]
set_property PACKAGE_PIN H9 [get_ports bus_bmb7_U7[1]]
set_property PACKAGE_PIN D8 [get_ports bus_bmb7_U7[2]]
set_property PACKAGE_PIN F8 [get_ports bus_bmb7_U7[3]]
set_property PACKAGE_PIN H8 [get_ports bus_bmb7_U7[4]]
set_property PACKAGE_PIN G10 [get_ports bus_bmb7_U7[5]]
set_property PACKAGE_PIN G9 [get_ports bus_bmb7_U7[6]]
set_property PACKAGE_PIN H11 [get_ports bus_bmb7_U7[7]]
set_property PACKAGE_PIN F9 [get_ports bus_bmb7_U7[8]]
set_property PACKAGE_PIN J11 [get_ports bus_bmb7_U7[9]]
set_property PACKAGE_PIN J10 [get_ports bus_bmb7_U7[10]]
set_property PACKAGE_PIN D9 [get_ports bus_bmb7_U7[11]]
set_property PACKAGE_PIN D13 [get_ports bus_bmb7_U7[12]]
set_property PACKAGE_PIN E13 [get_ports bus_bmb7_U7[13]]
set_property PACKAGE_PIN E12 [get_ports bus_bmb7_U7[14]]
set_property PACKAGE_PIN G11 [get_ports bus_bmb7_U7[15]]
set_property PACKAGE_PIN E10 [get_ports bus_bmb7_U7[16]]
set_property PACKAGE_PIN C12 [get_ports bus_bmb7_U7[17]]
set_property PACKAGE_PIN E11 [get_ports bus_bmb7_U7[18]]

# J28 and J4: external clock connector (SMP)
set_property PACKAGE_PIN H5 [get_ports {bus_bmb7_J28[0]}]
set_property PACKAGE_PIN H6 [get_ports {bus_bmb7_J4[0]}]

# Clock constraint maps to U7 pin
create_clock -period 20.000 -name S6_TO_K7_CLK_1 -waveform {0.000 10.000} [get_ports {bus_bmb7_U7[16]}]
