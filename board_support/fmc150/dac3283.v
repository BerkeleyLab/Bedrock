// DAC3283 Dual-Channel, 16-Bit, 800 MSPS, Digital-to-Analog Converter
// LVDS PHY interface
// [1]: http://www.ti.com/lit/ds/symlink/dac3283.pdf

module dac3283 #(
    parameter [7:0] BASE_ADDR = 8'h0,
    parameter [7:0] BASE2_OFFSET = 8'h0,
    // Default test pattern
    parameter TEST_PAT = 64'hC6AA161A_45EAB67A
) (
    input           dac_clk_in,  // 229MHz
    output          dac_clk_out,

    input [15:0]    dac_inA,
    input [15:0]    dac_inB,
    output          FRAME_P,     // Frame marker
    output          FRAME_N,
    output          DAC_DCLK_P,  // LVDS data clock
    output          DAC_DCLK_N,
    output [7:0]    DAC_D_P,     // LVDS data lanes
    output [7:0]    DAC_D_N,

    // PicoRV32 packed MEM Bus interface
    input           clk,
    input           rst,
    input  [68:0]   mem_packed_fwd,
    output [32:0]   mem_packed_ret
);

wire [31:0] sfRegsOut, sfRegsWrt;
wire [27:0] dacClkFreqCnt;
wire io_rst_cmd, frame_cmd, training_cmd, locked;
assign training_cmd = sfRegsOut[28];
assign io_rst_cmd   = sfRegsWrt[29];
assign frame_cmd    = sfRegsWrt[30];
sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR      ),
    .BASE2_ADDR     ( BASE2_OFFSET   ),
    .N_REGS         ( 1              )
) sfrInst (
    .clk            ( clk            ),
    .rst            ( rst            ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_ret ),
    .sfRegsOut      ( sfRegsOut      ),
    .sfRegsIn       ( {locked, 2'h0, training_cmd, dacClkFreqCnt} ),
    .sfRegsWrStr    ( sfRegsWrt      )
);

//---------------------------------------------
// Freq. counter for dac_clk_in
//---------------------------------------------
freq_count #(
    .glitch_thresh(15)
) fcnt (
    .clk               (dac_clk_in),
    .usbclk            (clk),
    .frequency         (dacClkFreqCnt),
    .diff_stream       (),
    .diff_stream_strobe(),
    .glitch_catcher    ()
);

wire txclkmul2;
wire txclk;
assign dac_clk_out = txclk;

// CLK_DIV = 229, CLK = 458MHz for OSERDES
xilinx7_clocks #(
    .DIFF_CLKIN     ("BYPASS"),
    .CLKIN_PERIOD   (4.367),
    .MULT           (4),
    .DIV0           (2),
    .DIV1           (4)
) mmem_inst (
    .reset      (io_rst_cmd),
    .sysclk_p   (dac_clk_in),
    .sysclk_n   (1'b0),
    .clk_out0   (txclkmul2),
    .clk_out1   (txclk),
    .locked     (locked)
);

// Make io_rst synchronous to txclk
reg io_rst = 0;
always @(posedge txclk) io_rst <= ~locked;

wire frame;
flag_xdomain flag2 (
   .clk1        (clk),
   .flagin_clk1 (frame_cmd),
   .clk2        (txclk),
   .flagout_clk2(frame)
);

// oserdes in clock path
wire dac_dclk_prebuf;
wire [7:0] dac_data_prebuf;
wire frame_prebuf;

//---------------------------------------------
// Output serdes and LVDS buffers for clock
//---------------------------------------------
// 4:1 DDR mode
OSERDESE2 #(
    .DATA_RATE_OQ   ("DDR"),
    .DATA_RATE_TQ   ("DDR"),
    .DATA_WIDTH     (4),
    .SERDES_MODE    ("MASTER"),
    .TRISTATE_WIDTH (4)
) oserdes_clock (
    .OQ                ( dac_dclk_prebuf ),
    .OFB               ( ),
    .TQ                ( ),
    .TFB               ( ),
    .SHIFTOUT1         ( ),
    .SHIFTOUT2         ( ),
    .CLK               ( txclkmul2 ),
    .CLKDIV            ( txclk     ),
    .D1                ( 1'b1      ),
    .D2                ( 1'b0      ),
    .D3                ( 1'b1      ),
    .D4                ( 1'b0      ),
    .D5                ( 1'b0      ),
    .D6                ( 1'b0      ),
    .D7                ( 1'b0      ),
    .D8                ( 1'b0      ),
    .OCE               ( 1'b1      ),
    .SHIFTIN1          ( 1'b0      ),
    .SHIFTIN2          ( 1'b0      ),
    .RST               ( io_rst    ),
    .TBYTEIN           ( 1'b0      ),
    .TBYTEOUT          ( ),
    .T1                ( 1'b0      ),
    .T2                ( 1'b0      ),
    .T3                ( 1'b0      ),
    .T4                ( 1'b0      ),
    .TCE               ( 1'b0      )
);

OBUFDS obufds_clk (
    .I      (dac_dclk_prebuf),
    .O      (DAC_DCLK_P),
    .OB     (DAC_DCLK_N)
);

reg [31:0] odata = 32'h0;
//---------------------------------------------
// Output serdes and LVDS buffers for data
//---------------------------------------------
genvar i;   // lvds lane [7:0]
generate for (i=0; i<=7; i=i+1) begin: lane
// 4:1 DDR mode
OSERDESE2 #(
    .DATA_RATE_OQ   ("DDR"),
    .DATA_RATE_TQ   ("DDR"),
    .DATA_WIDTH     (4),
    .SERDES_MODE    ("MASTER"),
    .TRISTATE_WIDTH (4)
) oserdes_data (
    .OQ                ( dac_data_prebuf[i] ),
    .OFB               ( ),
    .TQ                ( ),
    .TFB               ( ),
    .SHIFTOUT1         ( ),
    .SHIFTOUT2         ( ),
    .CLK               ( txclkmul2 ),
    .CLKDIV            ( txclk     ),
    // place the bits in the right order for the serializers
    // the DAC expects: ch0 MSByte, ch0 LSB, ch1 MSB, ch1 LSB, ....
    // see page 21 [1]
    .D1                ( odata[ 8+i] ),
    .D2                ( odata[ 0+i] ),
    .D3                ( odata[24+i] ),
    .D4                ( odata[16+i] ),
    .D5                ( 1'b0      ),
    .D6                ( 1'b0      ),
    .D7                ( 1'b0      ),
    .D8                ( 1'b0      ),
    .OCE               ( 1'b1      ),
    .SHIFTIN1          ( 1'b0      ),
    .SHIFTIN2          ( 1'b0      ),
    .RST               ( io_rst    ),
    .TBYTEIN           ( 1'b0      ),
    .TBYTEOUT          ( ),
    .T1                ( 1'b0      ),
    .T2                ( 1'b0      ),
    .T3                ( 1'b0      ),
    .T4                ( 1'b0      ),
    .TCE               ( 1'b0      )
);

OBUFDS obufds_data (
    .I      (dac_data_prebuf[i]),
    .O      (DAC_D_P[i]),
    .OB     (DAC_D_N[i])
);
end endgenerate

//---------------------------------------------
// Output serdes and LVDS buffers for frame
//---------------------------------------------
// 4:1 DDR mode
OSERDESE2 #(
    .DATA_RATE_OQ   ("DDR"),
    .DATA_RATE_TQ   ("DDR"),
    .DATA_WIDTH     (4),
    .SERDES_MODE    ("MASTER"),
    .TRISTATE_WIDTH (4)
) oserdes_frame (
    .OQ                ( frame_prebuf ),
    .OFB               ( ),
    .TQ                ( ),
    .TFB               ( ),
    .SHIFTOUT1         ( ),
    .SHIFTOUT2         ( ),
    .CLK               ( txclkmul2 ),
    .CLKDIV            ( txclk     ),
    .D1                ( frame     ),
    .D2                ( frame     ),
    .D3                ( frame     ),
    .D4                ( frame     ),
    .D5                ( 1'b0      ),
    .D6                ( 1'b0      ),
    .D7                ( 1'b0      ),
    .D8                ( 1'b0      ),
    .OCE               ( 1'b1      ),
    .SHIFTIN1          ( 1'b0      ),
    .SHIFTIN2          ( 1'b0      ),
    .RST               ( io_rst    ),
    .TBYTEIN           ( 1'b0      ),
    .TBYTEOUT          ( ),
    .T1                ( 1'b0      ),
    .T2                ( 1'b0      ),
    .T3                ( 1'b0      ),
    .T4                ( 1'b0      ),
    .TCE               ( 1'b0      )
);

OBUFDS obufds_frame (
    .I      (frame_prebuf),
    .O      (FRAME_P),
    .OB     (FRAME_N)
);

reg test_pat_sel = 0;
// Rearrange test-pattern so it is sent out in the expected order
// as shown on page 25 [1]
wire [63:0] testPatRearrange = {
    TEST_PAT[48+:8], TEST_PAT[56+:8], TEST_PAT[32+:8], TEST_PAT[40+:8],
    TEST_PAT[16+:8], TEST_PAT[24+:8], TEST_PAT[ 0+:8], TEST_PAT[ 8+:8]
};
always @ (posedge txclk) begin
    // Alternate between Upper and lower 32 bit of test-pattern
    test_pat_sel <= (frame) ? 1'b0 : ~test_pat_sel;
    // Switch between training pattern and data
    odata        <= (training_cmd) ?
                    testPatRearrange[test_pat_sel*32+:32] :
                    {dac_inB, dac_inA};
end
endmodule
