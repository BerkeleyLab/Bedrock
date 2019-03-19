module ad9653
  (D0NA,D0NB,D0NC,D0ND,D0PA,D0PB,D0PC,D0PD,D1NA,D1NB,D1NC,D1ND,D1PA,D1PB,D1PC,D1PD,DCOP,DCON,FCOP,FCON,PDWN,SYNC,
   CSB,SCLK,SDIO,
   pdwn_in,clk_reset,mmcm_reset,mmcm_locked,iserdes_reset,dout,clk_div_bufg,clk_div_bufr,dco_clk_out,dco_clk_in,idelay_ce,bitslip,idelay_value_in,idelay_value_out,clk_div_in,idelay_ld,
   //,iserdese2_o
   csb_in, sclk_in,
   //,sdio_inout
   sdi,sdo,sdio_as_i,
   mmcm_psclk, mmcm_psen, mmcm_psincdec, mmcm_psdone
   );
parameter DWIDTH=8;
parameter BANK_CNT=1;
parameter BANK_CNT_WIDTH=clog2(BANK_CNT)+1;
function integer clog2;
	input integer value;
	begin
		value = value-1;
		for (clog2=0; value>0; clog2=clog2+1)
			value = value>>1;
	end
endfunction
parameter [DWIDTH*BANK_CNT_WIDTH-1:0] BANK_SEL=0;
parameter SPIMODE="passthrough";
parameter dbg = "true";
//localparam DWIDTH_PAIRS=8;
parameter [DWIDTH-1:0] FLIP_D=0;
parameter FLIP_DCO=0;
parameter FLIP_FRAME=0;
inout D0NA;
inout D0NB;
inout D0NC;
inout D0ND;
inout D0PA;
inout D0PB;
inout D0PC;
inout D0PD;
inout D1NA;
inout D1NB;
inout D1NC;
inout D1ND;
inout D1PA;
inout D1PB;
inout D1PC;
inout D1PD;
inout DCON;
inout DCOP;
inout FCON;
inout FCOP;
inout PDWN;
inout SYNC;
output CSB;
output SCLK;
inout SDIO;
input pdwn_in;
input [5*DWIDTH-1:0] idelay_value_in;
output [5*DWIDTH-1:0] idelay_value_out;
//(* mark_debug = dbg *)
//output [7:0] iserdese2_o;
assign PDWN=pdwn_in;
input clk_reset;
input mmcm_reset;
output mmcm_locked;
input [BANK_CNT-1:0] iserdes_reset;     // state change create reset
output [8*DWIDTH-1:0] dout;
output clk_div_bufr;
output clk_div_bufg;
input  [DWIDTH-1:0] bitslip;
input [DWIDTH-1:0] idelay_ce;
input [DWIDTH-1:0] idelay_ld;
input [BANK_CNT-1:0] clk_div_in;
input [BANK_CNT-1:0] dco_clk_in;
output dco_clk_out;
input csb_in;
input sclk_in;
//inout sdio_inout;
output sdi;
input sdo;
input sdio_as_i;
input mmcm_psclk;
input mmcm_psen;
input mmcm_psincdec;
output mmcm_psdone;

generate
if (SPIMODE=="passthrough")begin
	assign CSB=csb_in;
	assign SCLK=sclk_in;
	//via sdiovia(.a(SDIO),.b(sdio_inout));
	IOBUF IOBUF(.O(sdi), .T(sdio_as_i),.I(sdo),.IO(SDIO));
end

endgenerate
/*
reg [BANK_CNT-1:0] reset_d=0;
reg [3:0] sync_reset=4'b0;
always @(posedge clk_div_bufr) begin
	reset_d <= iserdes_reset;
	sync_reset <= {sync_reset[2:0],iserdes_reset&~reset_d};   // ISERDESE2 reset require 2 cycles of clk_div
end
wire reset_in_clk_div=sync_reset[3]^sync_reset[1];
*/
wire frameout;
lvds_frame #(.flip_frame(FLIP_FRAME)) frame (.frame_p(FCOP), .frame_n(FCON),.frame(frameout));
lvds_dco #(.flip_dco(FLIP_DCO)) dco (.clk_reset(clk_reset),.mmcm_reset(mmcm_reset),.mmcm_locked(mmcm_locked),.dco_p(DCOP),.dco_n(DCON),.clk_div_bufr(clk_div_bufr),.clk_div_bufg(clk_div_bufg),.dco_clk_out(dco_clk_out),
.mmcm_psclk(mmcm_psclk), .mmcm_psen(mmcm_psen), .mmcm_psincdec(mmcm_psincdec), .mmcm_psdone(mmcm_psdone)
);

wire [DWIDTH-1:0] d_p=({D1PA,D0PA,D1PB,D0PB,D1PC,D0PC,D1PD,D0PD});
wire [DWIDTH-1:0] d_n=({D1NA,D0NA,D1NB,D0NB,D1NC,D0NC,D1ND,D0ND});
//wire iserdes_reset=reset;//_in_clk_div;
//wire idelay_ld=idelay_ld
wire idelay_inc_int=(1'b0);
reg [DWIDTH-1:0] idelay_ld_div_0=0,idelay_ld_div_1=0;
reg [DWIDTH-1:0] idelay_ce_div_0=0,idelay_ce_div_1=0;
reg [DWIDTH-1:0] bitslip_div_0=0,bitslip_div_1=0;
wire [DWIDTH-1:0] idelay_ld_div=idelay_ld_div_0&~idelay_ld_div_1;
wire [DWIDTH-1:0] idelay_ce_div=idelay_ce_div_0&~idelay_ce_div_1;
wire [DWIDTH-1:0] bitslip_div=bitslip_div_0&~bitslip_div_1;
wire [DWIDTH-1:0] clk_div;
wire [DWIDTH-1:0] dco_clk;
wire [DWIDTH-1:0] reset;
reg [5*DWIDTH-1:0] idelay_value_in_r;
genvar ix;
generate for (ix=0; ix < DWIDTH; ix=ix+1) begin: in_cell
	assign clk_div[ix] = clk_div_in[BANK_SEL[(ix+1)*BANK_CNT_WIDTH-1:ix*BANK_CNT_WIDTH]];
	assign dco_clk[ix] = dco_clk_in[BANK_SEL[(ix+1)*BANK_CNT_WIDTH-1:ix*BANK_CNT_WIDTH]];
	assign reset[ix]=iserdes_reset[BANK_SEL[(ix+1)*BANK_CNT_WIDTH-1:ix*BANK_CNT_WIDTH]];
	always @(negedge clk_div[ix]) begin
		idelay_ld_div_0[ix] <= idelay_ld[ix];
		idelay_ld_div_1[ix] <= idelay_ld_div_0[ix];
		idelay_ce_div_0[ix] <= idelay_ce[ix];
		idelay_ce_div_1[ix] <= idelay_ce_div_0[ix];
		bitslip_div_0[ix] <= bitslip[ix];
		bitslip_div_1[ix] <= bitslip_div_0[ix];
		idelay_value_in_r[5*ix+4:5*ix] <= idelay_value_in[5*ix+4:5*ix];
	end

lvds_iophy #(.flip_d(FLIP_D[ix])) iophy (
.d_p(d_p[ix]),
.d_n(d_n[ix]),
.dout(dout[8*ix+7:8*ix]),
.clk_div(clk_div[ix]),
.dco_clk(dco_clk[ix]),
.idelay_value_out(idelay_value_out[5*ix+4:5*ix]),
.idelay_value_in(idelay_value_in_r[5*ix+4:5*ix]),
.iserdes_reset(reset[ix]), // iserdes_reset should be in clk_div/clk_div_out domain
.idelay_ld(idelay_ld_div[ix]), // idelay_ld should be in clk_div/clk_div_out domain
.idelay_ce(idelay_ce_div[ix]), // idelay enable
.bitslip(bitslip_div[ix]), // bitslip pulse iserdese2_o(),
.idelay_inc_int(idelay_inc_int)
);

end
endgenerate
/*
wire spi_ready;
wire sdo,sdi;
wire sdio_as_sdo;
assign digitizer_U27_2 = ~sdio_as_sdo;
assign sdo = sdio_as_sdo ?  digitizer_U2_SDIO : 1'b0;
assign digitizer_U2_SDIO = sdio_as_sdo ? 1'bz : sdi ;

//input spi_start;
//input spi_read;
//input [15:0] spi_addr;
//input [7:0] spi_data;
//output [15:0]  sdo_addr;
//output [7:0] sdo_rdbk;
//output spi_ready;
//output sdio_as_sdo;

wire cs_9653;
wire sck_9653;
wire sdi_9653;
wire sdo_9653;
spi_master #(.TSCKHALF(10),.ADDR_WIDTH(16),.DATA_WIDTH(8))
spi_master(.clk(clk_div_bufg),.spi_start(spi_start),.spi_read(spi_read),.spi_addr(spi_addr),.spi_data(spi_data),.cs(cs_9653),.sck(sck_9653),.sdi(sdi_9653),.sdo(sdo_9653),.sdo_addr(sdo_addr),.spi_rdbk(spi_rdbk),.spi_ready(spi_ready),.sdio_as_sdo(sdio_as_sdo));


wire spi_ready;
wire sdo,sdi;
wire sdio_as_sdo;
assign digitizer_U27_2 = ~sdio_as_sdo;
assign sdo = sdio_as_sdo ?  digitizer_U2_SDIO : 1'b0;
assign digitizer_U2_SDIO = sdio_as_sdo ? 1'bz : sdi ;
spi_master #(.TSCKHALF(10),.ADDR_WIDTH(16),.DATA_WIDTH(8))
spi_master(.clk(clk),.spi_start(start),.spi_read(dout[23]),.spi_addr(dout[23:8]),.spi_data(dout[7:0]),.cs(digitizer_U2_CSB),.sck(digitizer_U4_SCLK),.sdi(sdi),.sdo(sdo),.sdo_addr(),.spi_rdbk(value_w),.spi_ready(spi_ready),.sdio_as_sdo(sdio_as_sdo));
reg [15:0] start_cnt=0,ready_cnt=0;
always @(posedge clk) begin
    if (start)
        start_cnt <= start_cnt+1;
    if (spi_ready)
        ready_cnt <= ready_cnt+1;
end
*/
endmodule
