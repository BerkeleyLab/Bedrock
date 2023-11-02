module ad9653 (
	input                 D0NA,
	input                 D0NB,
	input                 D0NC,
	input                 D0ND,
	input                 D0PA,
	input                 D0PB,
	input                 D0PC,
	input                 D0PD,
	input                 D1NA,
	input                 D1NB,
	input                 D1NC,
	input                 D1ND,
	input                 D1PA,
	input                 D1PB,
	input                 D1PC,
	input                 D1PD,
	input                 DCON,
	input                 DCOP,
	input                 FCON,
	input                 FCOP,
	output                PDWN,
	inout                 SYNC,
	output                CSB,
	output                SCLK,
	inout                 SDIO, // Truly bi-directional, see IOBUF below
	input                 pdwn_in,
	input  [5*DWIDTH-1:0] idelay_value_in,
	output [5*DWIDTH-1:0] idelay_value_out,
	input                 clk_reset,
	input                 mmcm_reset,
	output                mmcm_locked,
	input  [BANK_CNT-1:0] iserdes_reset,     // state change create reset
	output [8*DWIDTH-1:0] dout,
	output                clk_div_bufr,
	output                clk_div_bufg,
	input  [DWIDTH-1:0]   bitslip,
	input  [DWIDTH-1:0]   idelay_ce,
	input  [DWIDTH-1:0]   idelay_ld,
	input  [BANK_CNT-1:0] clk_div_in,
	input  [BANK_CNT-1:0] dco_clk_in,
	output                dco_clk_out,
	input                 csb_in,
	input                 sclk_in,
	output                sdi,
	input                 sdo,
	input                 sdio_as_i,
	input                 mmcm_psclk,
	input                 mmcm_psen,
	input                 mmcm_psincdec,
	output                mmcm_psdone
);
parameter DWIDTH=8;
parameter BANK_CNT=1;
parameter BANK_CNT_WIDTH=clog2(BANK_CNT)+1;
function integer clog2;
	input integer value;
	integer local_value;
	begin
		local_value = value-1;
		for (clog2=0; local_value>0; clog2=clog2+1)
			local_value = local_value>>1;
	end
endfunction
parameter [DWIDTH*BANK_CNT_WIDTH-1:0] BANK_SEL=0;
parameter SPIMODE="passthrough";
parameter dbg = "true";
parameter [DWIDTH-1:0] FLIP_D=0;
parameter FLIP_DCO=0;
parameter FLIP_FRAME=0;
parameter INFER_IOBUF=0;

assign PDWN = pdwn_in;

generate
if (SPIMODE=="passthrough") begin: passthrough
	assign CSB  = csb_in;
	assign SCLK = sclk_in;
	if (INFER_IOBUF == 0) begin
`ifndef SIMULATE
	IOBUF IOBUF(.O(sdi), .T(sdio_as_i), .I(sdo), .IO(SDIO));
`endif
	end else begin: no_passthrough
		// Inferred IOBUF
		assign SDIO = sdio_as_i ? 1'bz : sdo;
		assign sdi = SDIO;
	end
end
endgenerate

wire frameout;
lvds_frame #(.flip_frame(FLIP_FRAME)) lv_frame (.frame_p(FCOP), .frame_n(FCON),.frame(frameout));

lvds_dco #(.flip_dco(FLIP_DCO)) dco (
	.clk_reset(clk_reset),
	.mmcm_reset(mmcm_reset),.mmcm_locked(mmcm_locked),
	.dco_p(DCOP),.dco_n(DCON),
	.clk_div_bufr(clk_div_bufr), .clk_div_bufg(clk_div_bufg),
	.dco_clk_out(dco_clk_out),
	.mmcm_psclk(mmcm_psclk), .mmcm_psen(mmcm_psen),
	.mmcm_psincdec(mmcm_psincdec), .mmcm_psdone(mmcm_psdone)
);

wire [DWIDTH-1:0] d_p = ({D1PA,D0PA,D1PB,D0PB,D1PC,D0PC,D1PD,D0PD});
wire [DWIDTH-1:0] d_n = ({D1NA,D0NA,D1NB,D0NB,D1NC,D0NC,D1ND,D0ND});
wire idelay_inc_int = (1'b0);
reg [DWIDTH-1:0] idelay_ld_div_0=0,idelay_ld_div_1=0;
reg [DWIDTH-1:0] idelay_ce_div_0=0,idelay_ce_div_1=0;
reg [DWIDTH-1:0] bitslip_div_0=0,bitslip_div_1=0;

wire [DWIDTH-1:0] idelay_ld_div = idelay_ld_div_0 & ~idelay_ld_div_1;
wire [DWIDTH-1:0] idelay_ce_div = idelay_ce_div_0 & ~idelay_ce_div_1;
wire [DWIDTH-1:0] bitslip_div = bitslip_div_0 & ~bitslip_div_1;
wire [DWIDTH-1:0] clk_div;
wire [DWIDTH-1:0] dco_clk;
wire [DWIDTH-1:0] reset;
reg [5*DWIDTH-1:0] idelay_value_in_r;

genvar ix;
generate for (ix=0; ix < DWIDTH; ix=ix+1) begin: in_cell
`ifndef VERILATOR
	assign clk_div[ix] = clk_div_in[BANK_SEL[(ix+1)*BANK_CNT_WIDTH-1:ix*BANK_CNT_WIDTH]];
	assign dco_clk[ix] = dco_clk_in[BANK_SEL[(ix+1)*BANK_CNT_WIDTH-1:ix*BANK_CNT_WIDTH]];
	assign reset[ix] = iserdes_reset[BANK_SEL[(ix+1)*BANK_CNT_WIDTH-1:ix*BANK_CNT_WIDTH]];
	always @(negedge clk_div[ix]) begin
		idelay_ld_div_0[ix] <= idelay_ld[ix];
		idelay_ld_div_1[ix] <= idelay_ld_div_0[ix];
		idelay_ce_div_0[ix] <= idelay_ce[ix];
		idelay_ce_div_1[ix] <= idelay_ce_div_0[ix];
		bitslip_div_0[ix] <= bitslip[ix];
		bitslip_div_1[ix] <= bitslip_div_0[ix];
		idelay_value_in_r[5*ix+4:5*ix] <= idelay_value_in[5*ix+4:5*ix];
	end
`endif

lvds_iophy #(.flip_d(FLIP_D[ix])) iophy (
	.d_p              (d_p[ix]),
	.d_n              (d_n[ix]),
	.dout             (dout[8*ix+7:8*ix]),
	.clk_div          (clk_div[ix]),
	.dco_clk          (dco_clk[ix]),
	.idelay_value_out (idelay_value_out[5*ix+4:5*ix]),
	.idelay_value_in  (idelay_value_in_r[5*ix+4:5*ix]),
	.iserdes_reset    (reset[ix]), // iserdes_reset should be in clk_div/clk_div_out domain
	.idelay_ld        (idelay_ld_div[ix]), // idelay_ld should be in clk_div/clk_div_out domain
	.idelay_ce        (idelay_ce_div[ix]), // idelay enable
	.bitslip          (bitslip_div[ix]), // bitslip pulse iserdese2_o(),
	.idelay_inc_int   (idelay_inc_int)
);

end
endgenerate
endmodule
