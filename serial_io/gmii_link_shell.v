// Ultra-stupid layer to define clock domains of signals coming in to gmii_link
// for the benefit of cdc_snitch
module gmii_link_shell(
	// GMII Rx
	input  RX_CLK,
	output [7:0] RXD,
	output RX_DV,
	output RX_ER,
	// GMII Tx
	input GTX_CLK,
	input [7:0] TXD,
	input TX_EN,
	input TX_ER,
	// Output to serdes
	output [9:0] txdata,
	// Input from serdes
	input [9:0] rxdata,
	input rx_err_los,
	// other in GTX_CLK domain
	input an_bypass,  // disables lacr transmission for autonegotiation
	output operate,   // tells upper levels we're ready to transmit
	output [8:0] an_status,  // status reporting
	// other in RX_CLK domain
	output [15:0] lacr_rx  // layering violation
);

(* magic_cdc *) reg [7:0] TXD_r=0;
(* magic_cdc *) reg TX_EN_r=0, TX_ER_r=0, an_bypass_r=0;
always @(posedge GTX_CLK) begin
	TXD_r <= TXD;
	TX_EN_r <= TX_EN;
	TX_ER_r <= TX_ER;
	an_bypass_r <= an_bypass;
end

(* magic_cdc *) reg [9:0] rxdata_r=0;
(* magic_cdc *) reg rx_err_los_r=0;
always @(posedge RX_CLK) begin
	rxdata_r <= rxdata;
	rx_err_los_r <= rx_err_los;
end

wire [8:0] an_status_w;
reg [8:0] an_status_r=0;
wire operate_w;
reg operate_r=0;
always @(posedge GTX_CLK) begin
	an_status_r <= an_status_w;
	operate_r <= operate_w;
end
assign an_status = an_status_r;
assign operate = operate_r;

gmii_link gmii_link_(
	.RX_CLK(RX_CLK),
	.RXD(RXD),
	.RX_DV(RX_DV),
	.RX_ER(RX_ER),
	.GTX_CLK(GTX_CLK),
	.TXD(TXD_r),
	.TX_EN(TX_EN_r),
	.TX_ER(TX_ER_r),
	.txdata(txdata),
	.rxdata(rxdata_r),
	.rx_err_los(rx_err_los_r),
	.an_bypass(an_bypass_r),
	.operate(operate_w),
	.lacr_rx(lacr_rx),
	.an_status(an_status_w)
);

endmodule
