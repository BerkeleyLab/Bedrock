module iserdes_pack #(
    parameter [7:0] BASE_ADDR = 8'h00,
    parameter [7:0] BASE2_ADDR=8'h00,
    parameter BUFR_DIVIDE="4",
    parameter DW=4   // how many data LVDS pairs, or channels
) (
    // LVDS interface
    input clk_dco,
    input clk_div,
    input [DW-1:0]      in_p,
    input [DW-1:0]      in_n,
    output [8*DW-1:0]   dout,

    // PicoRV32 packed MEM Bus interface
    input  clk,
    input  rst,
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret
);

wire [31:0] sfRegsOut, sfRegsInp, sfRegsWrt;

// del_mux = index of selected idelay to read / write
wire [ 7:0]     del_mux =  sfRegsOut[ 7:0];
// del_val = delay tap value to write to idelay (0-31)
wire [ 4:0]     del_val =  sfRegsOut[12:8];
// del_wrt pulses high when del_val is written
wire            del_wrt = |sfRegsWrt[12:8];
// Binary decoder to provide an individual `LD` signal to each idelay
wire [DW-1:0]   del_ld = (del_wrt << del_mux);
// Many to one multiplexer for tap-value readback
wire [ 4:0]     del_mon[DW-1:0];

// Binary decoder to provide an individual strobe signal to each iserdes
wire [DW-1:0]   iserdes_reset_cmd = sfRegsWrt[16] << del_mux;
wire [DW-1:0]   bitslip_cmd       = sfRegsWrt[17] << del_mux;
// Many to one multiplexer for iserdesq readback
reg  [ 7:0]     dat_mon[DW-1:0];

integer k=0;
initial for (k=0;k<DW;k=k+1) dat_mon[k]=8'h0;

wire [7:0] dat_mon_mux = dat_mon[del_mux];
wire [4:0] del_mon_mux = del_mon[del_mux];

assign sfRegsInp = { 8'h0, dat_mon_mux, 3'h0, del_mon_mux, del_mux };

sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR      ),
    .BASE2_ADDR     ( BASE2_ADDR     ),
    .N_REGS         ( 1              )
) sfrInst (
    .clk            ( clk            ),
    .rst            ( rst            ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_ret ),
    .sfRegsOut      ( sfRegsOut      ),
    .sfRegsIn       ( sfRegsInp      ),
    .sfRegsWrStr    ( sfRegsWrt      )
);

// --------------------------------------------------------------
// Hardware
// --------------------------------------------------------------
genvar ix;
generate for (ix=0; ix < DW; ix=ix+1) begin: in_cell
    wire out_del;
    wire iserdese2_o;  // not used
    wire del_ld_i = del_ld[ix];
    wire [4:0] del_mon_i = del_mon[ix];
    // IDELAY control input @mem_clk domain
    idelay_wrap idelay (
        .in_p               (in_p[ix]),
        .in_n               (in_n[ix]),
        .out_del            (out_del),

        .clk                (clk),
        .rst                (rst),
        .del_ld             (del_ld[ix]),
        .del_cnt_wr         (del_val),
        .del_cnt_rd         (del_mon[ix])
    );

    wire iserdes_reset;
    wire bitslip;
    wire [7:0] dq;

    flag_xdomain flag1 (
       .clk1        (clk),
       .flagin_clk1 (iserdes_reset_cmd[ix]),
       .clk2        (clk_div),
       .flagout_clk2(iserdes_reset)
    );

    flag_xdomain flag2 (
       .clk1        (clk),
       .flagin_clk1 (bitslip_cmd[ix]),
       .clk2        (clk_div),
       .flagout_clk2(bitslip)
    );

    ISERDESE2 #(
        .DATA_RATE          ("DDR"),
        .DATA_WIDTH         (8),
        .INTERFACE_TYPE     ("NETWORKING"),
        .DYN_CLKDIV_INV_EN  ("FALSE"),
        .DYN_CLK_INV_EN     ("FALSE"),
        .NUM_CE             (2),
        .OFB_USED           ("FALSE"),
        .IOBDELAY           ("IFD"),
        .SERDES_MODE        ("MASTER")
    ) serdes_i (
        .RST                (iserdes_reset),
        .CE1                (1'b1),
        .CE2                (1'b1),
        .CLK                (clk_dco),
        .CLKB               (~clk_dco),
        .CLKDIV             (clk_div),
        .CLKDIVP            (1'b0),
        .D                  (1'b0),
        .DDLY               (out_del),
        .Q1                 (dq[0]),
        .Q2                 (dq[1]),
        .Q3                 (dq[2]),
        .Q4                 (dq[3]),
        .Q5                 (dq[4]),
        .Q6                 (dq[5]),
        .Q7                 (dq[6]),
        .Q8                 (dq[7]),
        .BITSLIP            (bitslip),
        .SHIFTIN1           (1'b0),
        .SHIFTIN2           (1'b0),
        .SHIFTOUT1          (),
        .SHIFTOUT2          (),
        .O                  (iserdese2_o),
        .DYNCLKDIVSEL       (1'b0),
        .DYNCLKSEL          (1'b0),
        .OFB                (1'b0),
        .OCLK               (1'b0),
        .OCLKB              (1'b0)
    );
    assign dout[8*ix+7 : 8*ix] = dq;

    // XXX cross domains, data has to be a static training pattern
    always @(posedge clk) begin
       dat_mon[ix] <= rst ? 8'h0 : dq;
    end

end endgenerate

endmodule
