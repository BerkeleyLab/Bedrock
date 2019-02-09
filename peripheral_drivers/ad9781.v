module ad9781 (
	output 	    D0N,
	output 	    D0P,
	output 	    D1N,
	output 	    D1P,
	output 	    D2P,
	output 	    D2N,
	output 	    D3N,
	output 	    D3P,
	output 	    D4N,
	output 	    D4P,
	output 	    D5N,
	output 	    D5P,
	output 	    D6N,
	output 	    D6P,
	output 	    D7N,
	output 	    D7P,
	output 	    D8N,
	output 	    D8P,
	output 	    D9N,
	output 	    D9P,
	output 	    D10N,
	output 	    D10P,
	output 	    D11N,
	output 	    D11P,
	output 	    D12N,
	output 	    D12P,
	output 	    D13N,
	output 	    D13P,
	output 	    DCIN,
	output 	    DCIP,
	input 	    DCON,
	input 	    DCOP,
	output 	    RESET,
	output 	    CSB,
	output 	    SCLK,
	inout 	    SDIO,
	input 	    SDO,
	input [13:0] data_i,
	input [13:0] data_q,
	output 	    dco_clk_out,
	input 	    dci,
	input 	    reset_in,
	input 	    csb_in,
	input 	    sclk_in,
	output 	    sdo_out,
	inout 	    sdio_inout
);
parameter SPIMODE="passthrough";
generate
if (SPIMODE=="passthrough")begin
	assign CSB=csb_in;
	assign SCLK=sclk_in;
	assign sdo_out =SDO;
	via sdiovia(sdio_inout,SDIO);
end
endgenerate
assign RESET=reset_in;

localparam width=14;
parameter [width-1:0] flip_d=0;
parameter flip_dco=0;
parameter flip_dci=0;
wire [width-1:0] d_p,d_n;
wire dco_clk_ds;
assign {D13P,D12P,D11P,D10P,D9P,D8P,D7P,D6P,D5P,D4P,D3P,D2P,D1P,D0P}=d_p;
assign {D13N,D12N,D11N,D10N,D9N,D8N,D7N,D6N,D5N,D4N,D3N,D2N,D1N,D0N}=d_n;
wire dco_p=DCOP;
wire dco_n=DCON;
`ifndef SIMULATE
IBUFDS ibuf_dco(.I(flip_dco ? dco_n : dco_p), .IB(flip_dco? dco_p : dco_n), .O(dco_clk_ds));
//BUFIO bufio_dco(.I(dco_clk), .O(dco_clk_buf));
BUFG bufg_dco(.I(dco_clk_ds), .O(dco_clk_out));
//wire [13:0] data_in_buf= dci ? data_i : data_q;
wire [13:0] data_in_buf;
wire dci_ddr;
ODDR oddr_dci(.C(dco_clk_out),.CE(1'b1),.D1(flip_dci),.D2(~flip_dci),.Q(dci_ddr));
OBUFDS obuf_dci(
	.O(DCIP),
	.OB(DCIN),
	.I(dci_ddr)
	);
genvar ix;
generate for (ix=0; ix < width; ix=ix+1) begin: in_cell
	ODDR oddr(.C(dco_clk_out),.CE(1'b1),.D1(data_i[ix]),.D2(data_q[ix]),.Q(data_in_buf[ix]));
	OBUFDS obuf_d(
		.O(d_p[ix]),
		.OB(d_n[ix]),
		.I(flip_d[ix] ? ~data_in_buf[ix] : data_in_buf[ix])
	);
end
endgenerate
`endif
endmodule
