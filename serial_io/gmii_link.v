// This module acts as a GMII PHY, so the port directions seem backwards
// Keep the Tx and Rx clock domains separate, they could be 100ppm different
// in a normal environment.
module gmii_link #(
	parameter TIMER=1250000,  // see negotiate.v
	parameter ENC_DISPINIT=1,
	parameter CTRACE_AW = 14,
	parameter INDENT = "",
	parameter [0:0] ADVERSARY = 1'b0
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
	,input ctrace_start,
	output ctrace_running,
	output [CTRACE_AW-1:0] ctrace_pc_mon,
	input  [31:0] ctrace_mask_0,
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
wire [7:0] tx_odata, tx_odata_pcs, tx_odata_an;
wire tx_is_k;
wire tx_is_k_pcs;
wire [15:0] lacr_out;
wire lacr_send;
reg enc_dispin=ENC_DISPINIT;
wire enc_dispout;
wire [7:0] txd;
ep_tx_pcs #(.INDENT(INDENT)) tx(.clk(GTX_CLK), .rst(tx_rst),
	.tx_data_i(txd),
	.tx_enable(TX_EN & (operate | an_bypass)), // Wait for AN to complete (if enabled)
	.ep_tcr_en_pcs_i(1'b1),
	.ep_lacr_tx_val_i(lacr_out),
	.ep_lacr_tx_en_i(lacr_send & ~an_bypass),
	.tx_odata_reg(tx_odata_pcs),
	.tx_is_k(tx_is_k_pcs),
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
wire lacr_rx_stb, lacr_rx_stb_ep;
wire lacr_rx_en;
wire [15:0] lacr_rx_val_pcs;
wire rx_is_k = rxdata_dec_out[8];
wire [7:0] rx_data = rxdata_dec_out[7:0];
ep_rx_pcs #(.INDENT(INDENT)) rx(.clk(RX_CLK), .rst(rx_rst),
	.dec_out(rx_data),
	.dec_is_k(rx_is_k),
	.dec_err_code(rx_err_code),
	.dec_err_rdisp(rx_err_rdisp),
	.dec_err_los(rx_err_los),
	.gmii_data(RXD),
	.gmii_dv(RX_DV),
	.gmii_err(RX_ER),
	.ep_rcr_en_pcs_i(1'b1),  // module enable
	.lacr_rx_en(lacr_rx_en), // input
	.lacr_rx_stb(lacr_rx_stb_ep), // output
	.lacr_rx_val(lacr_rx_val_pcs) // output [15:0]
);

reg dec_dispin=0;
wire dec_dispout;

always @(posedge RX_CLK) dec_dispin <= dec_dispout & ~rx_rst;

dec_8b10b my_dec_8b10b(
	.datain(rxdata), .dispin(dec_dispin),
	.dataout(rxdata_dec_out), .dispout(dec_dispout),
	.code_err(rx_err_code), .disp_err(rx_err_rdisp)
);

wire [15:0] lacr_rx_val;
generate
	if (ADVERSARY == 1'b1) begin: adversary
		assign lacr_rx_en = 1'b0;
		//wire [7:0] tx_byte;
		wire tx_is_k_an;
		wire negotiating;
		//assign txd = negotiating ? tx_byte : TXD;
		assign txd = TXD;
		assign tx_is_k = negotiating ? tx_is_k_an : tx_is_k_pcs;
		assign operate = ~negotiating;
		assign tx_odata = negotiating ? tx_odata_an : tx_odata_pcs;
		adversary_negotiate #(.TIMER_TICKS(TIMER), .INDENT(INDENT)) adversary_negotiate_i (
			.clk(RX_CLK), // input
			.rst(1'b0), // input
			.rx_byte(rxdata_dec_out[7:0]), // input [7:0]
			.rx_is_k(rxdata_dec_out[8]), // input
			.tx_byte(tx_odata_an),      // output [7:0]
			.tx_is_k(tx_is_k_an),       // output
			.negotiating(negotiating),  // output
			.los(rx_err_los),           // input
			.lacr_rx_val(lacr_rx_val),  // output [15:0]
			.an_status(an_status),      // output [8:0]
			.lacr_tx_val(lacr_out),     // output [15:0]
			.lacr_send(lacr_send),      // output
			.lacr_rx_stb(lacr_rx_stb)   // output
		);
	end else begin: protagonist
		assign lacr_rx_en=1'b1;
		assign txd = TXD;
		assign tx_is_k = tx_is_k_pcs;
		assign tx_odata = tx_odata_pcs;
		assign lacr_rx_stb = lacr_rx_stb_ep;
		negotiate #(.TIMER_TICKS(TIMER), .INDENT(INDENT)) negotiator(
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
	assign lacr_rx_val = lacr_rx_val_pcs;
	end
endgenerate

`ifdef APP_LB_FROM_FIBER
`ifdef FIBER_TRACE
wire ctrace_clk = RX_CLK;
reg rx_stb_envelope = 1'b0;
reg [1:0] rx_stb_envelope_counter = 0;
always @(posedge ctrace_clk) begin
  if (lacr_rx_stb) begin
    rx_stb_envelope_counter <= 0;
    rx_stb_envelope <= 1'b1;
  end else begin
    if (rx_stb_envelope_counter == 3) rx_stb_envelope <= 1'b0;
    rx_stb_envelope_counter <= rx_stb_envelope_counter + 1;
  end
end

/*
reg [13:0] rx_stb_update_counter = 0;
reg [11:0] rx_stb_counter = 0, rx_stb_counter_capture = 0;
wire rx_stb_update = rx_stb_update_counter == 0;
always @(posedge ctrace_clk) begin
  rx_stb_update_counter <= rx_stb_update_counter + 1;
  if (lacr_rx_stb) begin
    rx_stb_counter <= rx_stb_counter + 1;
  end
end
*/
localparam CTRACE_TW = 24;
// I guess we'll just catch everything going between 'negotiate'
localparam CTRACE_DW = 46;
wire rx_stb_mask = ctrace_mask_0[0];
wire [CTRACE_DW-1:0] ctrace_data;
assign ctrace_data[15: 0] = lacr_rx_val;
assign ctrace_data[31:16] = lacr_out;
assign ctrace_data[40:32] = an_status;
assign ctrace_data[41]    = rx_err_los;
assign ctrace_data[42]    = lacr_rx_stb & rx_stb_mask;
assign ctrace_data[43]    = lacr_send;
assign ctrace_data[44]    = operate;
assign ctrace_data[45]    = rx_stb_envelope;
// Ensure strobe and potentially cross clock domains
reg ctrace_start_stb=1'b0, ctrace_start_d0=1'b0, ctrace_start_d1=1'b0;
always @(posedge ctrace_clk) begin
  ctrace_start_d0 <= ctrace_start;
  ctrace_start_d1 <= ctrace_start_d0;
  ctrace_start_stb <= ctrace_start_d0 & ~ctrace_start_d1;
end

reg boot_stb=1'b0, boot_0=1'b0, boot_1=1'b0;
wire link_lock = ~rx_err_los;
reg link_lock_0=1'b0, link_lock_1=1'b0, link_lock_stb=1'b0;
always @(posedge ctrace_clk) begin
  boot_0 <= 1'b1;
  boot_1 <= boot_0;
  boot_stb <= boot_0 & (~boot_1);
  link_lock_0 <= link_lock;
  link_lock_1 <= link_lock_0;
  link_lock_stb <= link_lock_0 & (~link_lock_1);
end
wire start_stb = ctrace_start_stb | boot_stb | link_lock_stb;
wctrace #(
  .AW(CTRACE_AW),
  .DW(CTRACE_DW),
  .TW(CTRACE_TW)
) wctrace_i (
  .clk(ctrace_clk), // input
  .data(ctrace_data), // input [DW-1:0]
  .start(start_stb), // input
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
