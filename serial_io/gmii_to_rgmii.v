`timescale 1ns / 1ns

module gmii_to_rgmii #(
   parameter in_phase_tx_clk=0,
   parameter idelay_value=0,
   parameter use_idelay=0
) (

    // RGMII physical interface with PHY
    output [3:0] rgmii_txd, // to PHY
    output rgmii_tx_ctl,    // to PHY
    output rgmii_tx_clk,    // to PHY
    input [3:0] rgmii_rxd,  // from PHY
    input rgmii_rx_ctl,     // from PHY
    input rgmii_rx_clk,     // from PHY

    // GMII internal interface with MAC
    input gmii_tx_clk,      // from MAC
    input gmii_tx_clk90,    // from MAC
    input [7:0] gmii_txd,   // from MAC
    input gmii_tx_en,       // from MAC
    input gmii_tx_er,       // from MAC
    output [7:0] gmii_rxd,  // to MAC
    output gmii_rx_clk,     // to MAC
    output gmii_rx_dv,      // to MAC
    output gmii_rx_er,      // to MAC

    // IDELAYE2 control, matches lvds_iophy
    input            clk_div,
    input            idelay_ce,
    input [4:0]      idelay_value_in,
    output [4:0]     idelay_value_out_ctl,
    output [4:0]     idelay_value_out_data
);

// RGMII
wire [3:0] rgmii_txd_obuf;
wire [3:0] rgmii_rxd_ibuf;
wire rgmii_tx_ctl_buf;
wire rgmii_tx_clk_buf;
wire rgmii_rx_ctl_ibuf;
wire rgmii_rx_clk_buf;

OBUF rgmii_tx_ctl_obuf_i (
    .I(rgmii_tx_ctl_buf),
    .O(rgmii_tx_ctl)
);

OBUF rgmii_tx_clk_obuf_i (
    .I(rgmii_tx_clk_buf),
    .O(rgmii_tx_clk)
);

genvar ox;
generate for (ox=0; ox<4; ox=ox+1)
    begin: gen_rgmii_txd_obuf
        OBUF rgmii_txd_obuf_i (
            .I(rgmii_txd_obuf[ox]),
            .O(rgmii_txd[ox])
        );
    end
endgenerate

IBUF rgmii_rx_ctl_ibuf_i (
    .O(rgmii_rx_ctl_ibuf),
    .I(rgmii_rx_ctl)
);

IBUF rgmii_rx_clk_ibuf_i (
    .O(rgmii_rx_clk_buf),
    .I(rgmii_rx_clk)
);

genvar ix;
generate for (ix=0; ix<4; ix=ix+1)
    begin: gen_rgmii_rxd_ibuf
        IBUF rgmii_rxd_ibuf_i (
            .O(rgmii_rxd_ibuf[ix]),
            .I(rgmii_rxd[ix])
        );
    end
endgenerate

// Notes here refer to PG051, which is
//  Tri-Mode Ethernet MAC LogiCORE IP Product Guide (PG051)
// currently v9.0, May 17, 2023.  Of course my figure references
// are for a much older version, going back to at least 2018.
//
// RGMII Tx, Refer to PG051 Fig 3-66
// Refer to PG051 page 154 for reason of using ODDR & 90 phase clock.
// Other hardware (like Marvell 88E1512 in default mode)
// wants an in-phase clock.
wire rgmii_tx_clk_ = in_phase_tx_clk ? gmii_tx_clk : gmii_tx_clk90;
ODDR #(
    .SRTYPE ("ASYNC"),
    .DDR_CLK_EDGE  ("SAME_EDGE")
) rgmii_tx_clk_oddr (
    .Q(rgmii_tx_clk_buf),
    .C(rgmii_tx_clk_),
    .D1(1'b1),
    .D2(1'b0),
    .R(1'b0),
    .S(1'b0)
);

// rgmii_tx_ctl
ODDR #(
    .SRTYPE ("ASYNC"),
    .DDR_CLK_EDGE("SAME_EDGE")
) rgmii_tx_ctl_oddr (
    .Q(rgmii_tx_ctl_buf),
    .C(gmii_tx_clk),
    .D1(gmii_tx_en),
    .D2(gmii_tx_en ^ gmii_tx_er),
    .R(1'b0),
    //.R(tx_reset),
    .S(1'b0)
);

// rgmii_txd
wire [3:0] gmii_txd_rise = gmii_txd[3:0];
wire [3:0] gmii_txd_fall = gmii_txd[7:4];

genvar i;
generate for (i=0; i<4; i=i+1)
    begin: gen_rgmii_txd_oddr
        ODDR #(
            .SRTYPE ("ASYNC"),
            .DDR_CLK_EDGE("SAME_EDGE")
        ) rgmii_txd_oddr (
            .Q(rgmii_txd_obuf[i]),
            .C(gmii_tx_clk),
            .CE(1'b1),
            .D1(gmii_txd_rise[i]),
            .D2(gmii_txd_fall[i]),
            .R(1'b0),
            //.R(tx_reset),
            .S(1'b0)
        );
    end
endgenerate

// RGMII Rx, refer to PG051 Fig 3-67
// refer to PG051 page 155 for using BUFIO + BUFR + IODELAY
// rgmii_rx_clk
wire rgmii_rx_clk_bufio;

BUFG rgmii_rx_clk_bufio_i (
    .I(rgmii_rx_clk_buf),
    .O(rgmii_rx_clk_bufio)
);

`ifndef CHIP_FAMILY_ULTRASCALE
wire rgmii_rx_clk_bufr;
BUFR rgmii_rx_clk_bufr_i (
    .I(rgmii_rx_clk_buf),
    .CE(1'b1),
    .CLR(1'b0),
    .O(rgmii_rx_clk_bufr)
);
assign gmii_rx_clk = rgmii_rx_clk_bufr;
`else
assign gmii_rx_clk = rgmii_rx_clk_bufio;
`endif

// AC701 seems to not need RX delay.
// Note that this chunk of code delays rxd (and ctl) but not clk.
//
// I'm pretty sure that instantiating IDELAY doesn't really change the hardware;
// that block is always present in the data flow from the I/O pin, just set to
// a minimum delay configuration.
//
// Instantiating it does two things:  gives us access to the control pins,
// and the tools then force us to instantiate an IDELAYCTRL block somewhere
// to define calibration.
//
// Leaving it non-instantiated (parameter use_idelay=0) constructs the
// hdl as a bare wire, speeding and simplifying simulation, and avoiding
// the need to instantiate an IDELAYCTRL.
wire rgmii_rx_ctl_delay;
wire [3:0] rgmii_rxd_delay;
genvar j;
generate if (use_idelay) begin : with_idelay

wire [4:0] idelay_rx_ctl_value_out;
assign idelay_value_out_ctl = idelay_rx_ctl_value_out;
(* IODELAY_GROUP = "IODELAY_200" *)
IDELAYE2 #(
    .DELAY_SRC("IDATAIN"),
    .IDELAY_TYPE("VAR_LOAD"),
    .IDELAY_VALUE(idelay_value)
) rgmii_rx_ctl_delay_i (
    .IDATAIN(rgmii_rx_ctl_ibuf),
    .DATAOUT(rgmii_rx_ctl_delay),
    .DATAIN(1'b0),
    .C(clk_div),
    .CE(1'b0),
    .INC(1'b0),
    .CINVCTRL(1'b0),
    .CNTVALUEIN(idelay_value_in),
    .CNTVALUEOUT(idelay_rx_ctl_value_out),
    .LD(idelay_ce),
    .LDPIPEEN(1'b0),
    .REGRST(1'b0)
);

wire [4:0] idelay_rxd_value_out [0:3];  // [1:3] ignored
assign idelay_value_out_data = idelay_rxd_value_out[0];
for (j=0; j<4; j=j+1)
    begin: gen_gmii_rxd_delay
        (* IODELAY_GROUP = "IODELAY_200" *)
        IDELAYE2 #(
            .DELAY_SRC("IDATAIN"),
            .IDELAY_TYPE("VAR_LOAD"),
            .IDELAY_VALUE(idelay_value)
        ) delay_rgmii_rxd (
            .IDATAIN(rgmii_rxd_ibuf[j]),
            .DATAOUT(rgmii_rxd_delay[j]),
            .DATAIN(1'b0),
            .C(clk_div),
            .CE(1'b0),
            .INC(1'b0),
            .CINVCTRL(1'b0),
            .CNTVALUEIN(idelay_value_in),
            .CNTVALUEOUT(idelay_rxd_value_out[j]),
            .LD(idelay_ce),
            .LDPIPEEN(1'b0),
            .REGRST(1'b0)
        );
    end

end else begin : without_idelay
// pass-through
assign rgmii_rx_ctl_delay = rgmii_rx_ctl_ibuf;
assign rgmii_rxd_delay = rgmii_rxd_ibuf;
assign idelay_value_out_ctl = 0;
assign idelay_value_out_data = 0;
end endgenerate

// rgmii_rx_ctl
wire gmii_rx_dv_int;
wire rgmii_rx_ctl_int;

IDDR #(
    .SRTYPE ("ASYNC"),
    .DDR_CLK_EDGE("SAME_EDGE_PIPELINED")
) rgmii_rx_ctl_iddr (
    .Q1(gmii_rx_dv_int),
    .Q2(rgmii_rx_ctl_int),
    .C(rgmii_rx_clk_bufio),
    .CE(1'b1),
    .D(rgmii_rx_ctl_delay),
    .R(1'b0),
    .S(1'b0)
);

// Decode gmii_rx_er
assign gmii_rx_er = gmii_rx_dv_int ^ rgmii_rx_ctl_int;
assign gmii_rx_dv = gmii_rx_dv_int;

// rgmii_rxd

wire [3:0] gmii_rxd_rise, gmii_rxd_fall;
assign gmii_rxd = {gmii_rxd_fall, gmii_rxd_rise};

genvar k;
generate for (k=0; k<4; k=k+1)
    begin: gen_rgmii_rxd_iddr
        IDDR #(
            .SRTYPE ("ASYNC"),
            .DDR_CLK_EDGE("SAME_EDGE_PIPELINED")
        ) rgmii_rxd_iddr (
            .Q1(gmii_rxd_rise[k]),
            .Q2(gmii_rxd_fall[k]),
            .C(rgmii_rx_clk_bufio),
            .CE(1'b1),
            .D(rgmii_rxd_delay[k]),
            .R(1'b0),
            .S(1'b0)
        );
    end
endgenerate

endmodule
