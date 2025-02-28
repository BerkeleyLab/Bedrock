// This module acts as a GMII PHY, so the port directions seem backwards
// Keep the Tx and Rx clock domains separate, they could be 100ppm different
// in a normal environment.
module gmii_link #(
	parameter DELAY=1250000,  // see negotiate.v
	parameter ENC_DISPINIT=1,
	parameter CTRACE_AW = 14
) (
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
	// other
	input an_bypass,  // disables lacr transmission for autonegotiation
	output operate,   // (GTX_CLK domain) tells upper levels we're ready to transmit
	output [15:0] lacr_rx,  // (RX_CLK domain) layering violation
	output [8:0] an_status
`ifdef APP_LB_FROM_FIBER
`ifdef FIBER_TRACE
	// ctrace CSRs
	,input ctrace_start, // TODO hook me up!
	output ctrace_running, // TODO hook me up!
	output [CTRACE_AW-1:0] ctrace_pc_mon, // TODO hook me up!
	// ctrace readout in lb_clk domain
	input lb_clk,
	input  [CTRACE_AW-1:0] lb_addr,
	output [31:0] lb_out
`endif
`endif
);

//New internal wires removed from the module interface (error signals from 8b10b enc/dec)
wire rx_err_code, rx_err_rdisp;


reg rx_rst=1, tx_rst=1;
always @(posedge RX_CLK) rx_rst<=0;
always @(posedge GTX_CLK) tx_rst<=0;

// Tx path from GMII to serializer
wire [7:0] tx_odata;
wire tx_is_k;
wire [15:0] lacr_out;
wire lacr_send;
reg enc_dispin=ENC_DISPINIT;
wire enc_dispout;
ep_tx_pcs tx(.clk(GTX_CLK), .rst(tx_rst),
	.tx_data_i(TXD),
	.tx_enable(TX_EN & (operate | an_bypass)), // Wait for AN to complete (if enabled)
	.ep_tcr_en_pcs_i(1'b1),
	.ep_lacr_tx_val_i(lacr_out),
	.ep_lacr_tx_en_i(lacr_send & ~an_bypass),
	.tx_odata_reg(tx_odata),
	.tx_is_k(tx_is_k),
	.disparity_i(enc_dispout)
);

wire [8:0] txdata_in_enc={tx_is_k, tx_odata};

always @(posedge GTX_CLK) enc_dispin <= enc_dispout & ~tx_rst;

enc_8b10b my_enc_8b10b (
	.datain(txdata_in_enc), .dispin(enc_dispin),
	.dataout(txdata), .dispout(enc_dispout)
);

wire [8:0] rxdata_dec_out;
// Rx path from deserializer to GMII
wire lacr_rx_stb;
wire [15:0] lacr_rx_val;
ep_rx_pcs rx(.clk(RX_CLK), .rst(rx_rst),
	.dec_out(rxdata_dec_out[7:0]),
	.dec_is_k(rxdata_dec_out[8]),
	.dec_err_code(rx_err_code),
	.dec_err_rdisp(rx_err_rdisp),
	.dec_err_los(rx_err_los),
	.gmii_data(RXD),
	.gmii_dv(RX_DV),
	.gmii_err(RX_ER),
	.ep_rcr_en_pcs_i(1'b1),  // module enable
	.lacr_rx_en(1'b1),
	.lacr_rx_stb(lacr_rx_stb),
	.lacr_rx_val(lacr_rx_val)
);

reg dec_dispin=0;
wire dec_dispout;

always @(posedge RX_CLK) dec_dispin <= dec_dispout & ~rx_rst;

dec_8b10b my_dec_8b10b(
	.datain(rxdata), .dispin(dec_dispin),
	.dataout(rxdata_dec_out), .dispout(dec_dispout),
	.code_err(rx_err_code), .disp_err(rx_err_rdisp)
);

negotiate #(.TIMER_TICKS(DELAY)) negotiator(
	.rx_clk(RX_CLK),
	.tx_clk(GTX_CLK),
	.los(rx_err_los),           // input
	.lacr_in(lacr_rx_val),      // input [15:0]
	.lacr_in_stb(lacr_rx_stb),  // input
	.lacr_out(lacr_out),        // output [15:0]
	.lacr_send(lacr_send),      // output
	.operate(operate),          // output
	.an_status(an_status)       // output [8:0]
);

`ifdef APP_LB_FROM_FIBER
`ifdef FIBER_TRACE
// TODO - What clock?
wire ctrace_clk = RX_CLK;
localparam CTRACE_TW = 24;
// I guess we'll just catch everything going between 'negotiate'
localparam CTRACE_DW = 45;
wire [CTRACE_DW-1:0] ctrace_data;
assign ctrace_data[15: 0] = lacr_rx_val;
assign ctrace_data[31:16] = lacr_out;
assign ctrace_data[40:32] = an_status;
assign ctrace_data[41]    = rx_err_los;
assign ctrace_data[42]    = lacr_rx_stb;
assign ctrace_data[43]    = lacr_send;
assign ctrace_data[44]    = operate;
wctrace #(
  .AW(CTRACE_AW),
  .DW(CTRACE_DW),
  .TW(CTRACE_TW)
) wctrace_i (
  .clk(ctrace_clk), // input
  .data(ctrace_data), // input [DW-1:0]
  .start(ctrace_start), // input
  .running(ctrace_running), // output
  .pc_mon(ctrace_pc_mon), // output [AW-1:0]
  .lb_clk(lb_clk), // input
  .lb_addr(lb_addr), // input [AW-1:0]
  .lb_out(lb_out) // output [31:0]
);
`endif
`endif

assign lacr_rx = lacr_rx_val;

endmodule
