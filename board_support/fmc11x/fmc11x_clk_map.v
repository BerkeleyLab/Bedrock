module fmc11x_clk_map #(
    parameter N_IC=4,
    localparam N_CH=4*N_IC
) (
    input  [N_IC-1:0] clk_dco_in,
    input  [N_IC-1:0] clk_div_in,
    output [N_IC-1:0] clk_dco_frame,
    output [N_IC-1:0] clk_div_frame,
    output [N_CH-1:0] clk_dco_data,
    output [N_CH-1:0] clk_div_data
);
    assign clk_dco_data[0 ] = clk_dco_in[0];
    assign clk_dco_data[1 ] = clk_dco_in[0];
    assign clk_dco_data[2 ] = clk_dco_in[0];
    assign clk_dco_data[3 ] = clk_dco_in[1]; // not 0
    assign clk_dco_data[4 ] = clk_dco_in[2]; // not 1
    assign clk_dco_data[5 ] = clk_dco_in[1];
    assign clk_dco_data[6 ] = clk_dco_in[1];
    assign clk_dco_data[7 ] = clk_dco_in[1];
    assign clk_dco_data[8 ] = clk_dco_in[2];
    assign clk_dco_data[9 ] = clk_dco_in[2];
    assign clk_dco_data[10] = clk_dco_in[2];
    assign clk_dco_data[11] = clk_dco_in[2];


    assign clk_div_data[0 ] = clk_div_in[0];
    assign clk_div_data[1 ] = clk_div_in[0];
    assign clk_div_data[2 ] = clk_div_in[0];
    assign clk_div_data[3 ] = clk_div_in[1]; // not 0
    assign clk_div_data[4 ] = clk_div_in[2]; // not 1
    assign clk_div_data[5 ] = clk_div_in[1];
    assign clk_div_data[6 ] = clk_div_in[1];
    assign clk_div_data[7 ] = clk_div_in[1];
    assign clk_div_data[8 ] = clk_div_in[2];
    assign clk_div_data[9 ] = clk_div_in[2];
    assign clk_div_data[10] = clk_div_in[2];
    assign clk_div_data[11] = clk_div_in[2];

    assign clk_dco_frame[0] = clk_dco_in[0];
    assign clk_dco_frame[1] = clk_dco_in[2]; // not 1
    assign clk_dco_frame[2] = clk_dco_in[2];

    assign clk_div_frame[0] = clk_div_in[0];
    assign clk_div_frame[1] = clk_div_in[2]; // not 1
    assign clk_div_frame[2] = clk_div_in[2];

generate
	if (N_IC==4) begin : ic4
    assign clk_dco_data[12] = clk_dco_in[3];
    assign clk_dco_data[13] = clk_dco_in[3];
    assign clk_dco_data[14] = clk_dco_in[3];
    assign clk_dco_data[15] = clk_dco_in[3];
    assign clk_div_data[12] = clk_div_in[3];
    assign clk_div_data[13] = clk_div_in[3];
    assign clk_div_data[14] = clk_div_in[3];
    assign clk_div_data[15] = clk_div_in[3];
    assign clk_dco_frame[3] = clk_dco_in[3];
    assign clk_div_frame[3] = clk_div_in[3];
end endgenerate

endmodule
