#timing
# ADS62P49 250MHz ADC 14bit, DDR LVDS
create_clock -period 4.0 -name fmc150_adc_clk [get_ports FMC150_CLK_AB_P]
create_clock -period 4.0 -name fmc150_dac_clk [get_ports FMC150_CLK_TO_FPGA_P]

#DAC3283 800MHz DAC 16bit, DDR LVDS running at 250MHz, oserdes
#create_clock -period 2.0 -name fmc150_dac_dclk [get_ports FMC150_DAC_DCLK_P]

# set_input_delay -clock [get_clocks fmc150_adc_clk] -min 0.55 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
# set_input_delay -clock [get_clocks fmc150_adc_clk] -max 3.45 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
# set_input_delay -clock [get_clocks fmc150_adc_clk] -clock_fall -min -add_delay 0.55 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
# set_input_delay -clock [get_clocks fmc150_adc_clk] -clock_fall -max -add_delay 3.45 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
#
# set_input_delay -clock [get_clocks fmc150_adc_clk] -min -add_delay -3.450 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
# set_input_delay -clock [get_clocks fmc150_adc_clk] -max -add_delay -0.550 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
# set_input_delay -clock [get_clocks fmc150_adc_clk] -clock_fall -min -add_delay -3.450 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
# set_input_delay -clock [get_clocks fmc150_adc_clk] -clock_fall -max -add_delay -0.550 [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]

#set_output_delay -clock [get_clocks fmc150_dac_clk] -min [get_ports -regexp {FMC150_CH[A,B]_[N,P]\[\d\]}]
