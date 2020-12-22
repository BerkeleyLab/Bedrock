module zest_clk_map #(
    parameter N_ADC=2,
    parameter N_CH=4*N_ADC
) (
    input  [N_ADC-1:0] clk_dco_in,
    input  [N_ADC-1:0] clk_div_in,
    output [N_ADC-1:0] clk_dco_frame,
    output [N_ADC-1:0] clk_div_frame,
    output [N_CH-1:0] clk_dco_data,
    output [N_CH-1:0] clk_div_data
);
    assign clk_dco_data[0 ] = clk_dco_in[0];
    assign clk_dco_data[1 ] = clk_dco_in[0];
    assign clk_dco_data[2 ] = clk_dco_in[0];
    assign clk_dco_data[3 ] = clk_dco_in[0];
    assign clk_dco_data[4 ] = clk_dco_in[1];
    assign clk_dco_data[5 ] = clk_dco_in[1];
    assign clk_dco_data[6 ] = clk_dco_in[0]; // not 1
    assign clk_dco_data[7 ] = clk_dco_in[0]; // not 1


    assign clk_div_data[0 ] = clk_div_in[0];
    assign clk_div_data[1 ] = clk_div_in[0];
    assign clk_div_data[2 ] = clk_div_in[0];
    assign clk_div_data[3 ] = clk_div_in[0];
    assign clk_div_data[4 ] = clk_div_in[1];
    assign clk_div_data[5 ] = clk_div_in[1];
    assign clk_div_data[6 ] = clk_div_in[0]; // not 1
    assign clk_div_data[7 ] = clk_div_in[0]; // not 1

    assign clk_dco_frame[0] = clk_dco_in[0];
    assign clk_dco_frame[1] = clk_dco_in[1];

    assign clk_div_frame[0] = clk_div_in[0];
    assign clk_div_frame[1] = clk_div_in[1];

endmodule
