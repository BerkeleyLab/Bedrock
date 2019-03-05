create_ip -name gtwizard -vendor xilinx.com -library ip -module_name gtwizard

set_property -dict {
    CONFIG.identical_val_tx_line_rate       {1.25}
    CONFIG.gt1_val                          {false}
    CONFIG.gt0_val                          {true}
    CONFIG.gt0_val_drp_clock                {100}
    CONFIG.gt0_val_rx_refclk                {REFCLK1_Q0}
    CONFIG.gt0_val_tx_refclk                {REFCLK1_Q0}
    CONFIG.gt1_val_rx_refclk                {REFCLK0_Q0}
    CONFIG.gt1_val_tx_refclk                {REFCLK0_Q0}
    CONFIG.identical_val_tx_reference_clock {125.000}
    CONFIG.gt0_val_txbuf_en                 {true}
    CONFIG.gt0_val_rxbuf_en                 {true}
    CONFIG.gt0_val_port_rxslide             {false}
    CONFIG.gt0_usesharedlogic               {1}
    CONFIG.identical_val_rx_line_rate       {1.25}
    CONFIG.gt_val_tx_pll                    {CPLL}
    CONFIG.gt_val_rx_pll                    {CPLL}
    CONFIG.identical_val_tx_reference_clock {125.000}
    CONFIG.identical_val_rx_reference_clock {125.000}
    CONFIG.gt0_val_tx_line_rate             {1.25}
    CONFIG.gt0_val_tx_data_width            {20}
    CONFIG.gt0_val_tx_int_datawidth         {20}
    CONFIG.gt0_val_tx_reference_clock       {125.000}
    CONFIG.gt0_val_rx_line_rate             {1.25}
    CONFIG.gt0_val_rx_data_width            {20}
    CONFIG.gt0_val_rx_int_datawidth         {20}
    CONFIG.gt0_val_rx_reference_clock       {125.000}
    CONFIG.gt0_val_cpll_fbdiv               {4}
    CONFIG.gt0_val_cpll_rxout_div           {4}
    CONFIG.gt0_val_cpll_txout_div           {4}
    CONFIG.gt0_val_tx_buffer_bypass_mode    {Auto}
    CONFIG.gt0_val_txoutclk_source          {false}
    CONFIG.gt0_val_rx_buffer_bypass_mode    {Auto}
    CONFIG.gt0_val_rxusrclk                 {RXOUTCLK}
    CONFIG.gt0_val_rxslide_mode             {OFF}
    CONFIG.gt0_val_port_txbufstatus         {true}
    CONFIG.gt0_val_port_txrate              {false}
    CONFIG.gt0_val_port_rxbufstatus         {true}
    CONFIG.gt0_val_port_rxrate              {false}
    CONFIG.gt0_val_port_rxpmareset          {true}
    CONFIG.gt0_val_align_mcomma_det         {true}
    CONFIG.gt0_val_align_pcomma_det         {true}
    CONFIG.gt0_val_dec_valid_comma_only     {false}
    CONFIG.gt0_val_comma_preset             {User_defined}
    CONFIG.gt0_val_align_pcomma_value       {0101111100}
    CONFIG.gt0_val_align_mcomma_value       {1010000011}
    CONFIG.gt0_val_align_comma_enable       {0001111111}
    CONFIG.gt0_val_align_comma_double       {false}
    CONFIG.gt0_val_align_comma_word         {Two_Byte_Boundaries}
    CONFIG.gt0_val_port_rxpcommaalignen     {false}
    CONFIG.gt0_val_port_rxmcommaalignen     {false}
    CONFIG.gt0_val_dfe_mode                 {LPM-Auto}
    CONFIG.gt0_val_rx_termination_voltage   {Programmable}
    CONFIG.gt0_val_rx_cm_trim               {800}
    CONFIG.gt0_val_port_rxdfereset          {true}
    CONFIG.gt0_val_pcs_pcie_en              {false}
    CONFIG.gt0_val_sata_rx_burst_val        {4}
    CONFIG.gt0_val_sata_e_idle_val          {4}
    CONFIG.gt0_val_pd_trans_time_to_p2      {100}
    CONFIG.gt0_val_pd_trans_time_from_p2    {60}
    CONFIG.gt0_val_pd_trans_time_non_p2     {25}
    CONFIG.gt0_val_port_rxstatus            {false}
    CONFIG.gt0_val_port_rxvalid             {false}
    CONFIG.gt0_val_port_cominitdet          {false}
    CONFIG.gt0_val_port_comsasdet           {false}
    CONFIG.gt0_val_port_comwakedet          {false}
    CONFIG.gt0_val_port_txcominit           {false}
    CONFIG.gt0_val_port_txcomsas            {false}
    CONFIG.gt0_val_port_txcomwake           {false}
    CONFIG.gt0_val_port_txcomfinish         {false}
    CONFIG.gt0_val_port_txdetectrx          {false}
    CONFIG.gt0_val_port_phystatus           {false}
    CONFIG.gt0_val_rxprbs_err_loopback      {false}
    CONFIG.gt0_val_cb                       {false}
    CONFIG.gt0_val_cc                       {false}
    CONFIG.gt0_val_clk_cor_seq_1_1          {0100000000}
    CONFIG.gt0_val_clk_cor_seq_1_2          {0000000000}
    CONFIG.gt0_val_clk_cor_seq_1_3          {0000000000}
    CONFIG.gt0_val_clk_cor_seq_1_4          {0000000000}
    CONFIG.gt0_val_clk_cor_seq_2_1          {0100000000}
    CONFIG.gt0_val_clk_cor_seq_2_2          {0000000000}
    CONFIG.gt0_val_clk_cor_seq_2_3          {0000000000}
    CONFIG.gt0_val_clk_cor_seq_2_4          {0000000000}
} [get_ips gtwizard]
generate_target {instantiation_template} [get_files gtwizard.xci]
generate_target all [get_files  gtwizard.xci]
export_ip_user_files -of_objects [get_files gtwizard.xci] -no_script -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] gtwizard.xci]

