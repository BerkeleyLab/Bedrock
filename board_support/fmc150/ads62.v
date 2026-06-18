// --------------------------------------------------------------
//  ads62.v
// --------------------------------------------------------------
// handle 2 ADC channels of the ads62p49
// takes care of
//   * 14 x data + 1 x clock LVDS lanes
//   * each one has a picorv accessible IDELAY
//   * de-interleaving the DDR LVDS signals to get 2 x 14 bit samples (channel A, B)
//   * make the sample values accessible to picorv32 (to evaluate test-patterns)

module ads62 #(
    parameter BASE_ADDR =8'h00,
    parameter BASE2_OFFSET = 8'h00,  // Takes 2 BASE2_ADDR slots
    parameter REFCLK_FREQUENCY = 200.0
) (
    // 14 x DDR LVDS interface (for 2 channels) + clk_ab
    input         clk_ab_p,
    input         clk_ab_n,
    input  [ 6:0] inA_p,
    input  [ 6:0] inA_n,
    input  [ 6:0] inB_p,
    input  [ 6:0] inB_n,

    // output of ADC samples
    output        clk_ab_del,
    output [13:0] outA,
    output [13:0] outB,

    // PicoRV32 packed MEM Bus interface
    input  clk,
    input  rst,
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret
);

wire [32:0] packed_del_ret, packed_mon_ret;
assign mem_packed_ret = packed_del_ret | packed_mon_ret;

wire [14:0] sig_p  = { clk_ab_p, inB_p, inA_p };  // differential DDR signals
wire [14:0] sig_n  = { clk_ab_n, inB_n, inA_n };  // ...
wire [14:0] sig_se;                       // single ended DDR signals
wire [13:0] sig_del;                      // delayed DDR signals
wire [27:0] sdrSamples;                   // samples, [27:14] chB, [13:0] chA
assign { outB, outA } = sdrSamples;

// For each differential DDR LVDS lane + the clk_ab lane
genvar i;
generate for (i=0; i<=14; i=i+1) begin: lane
    // Differential to single ended input buffer
    IBUFDS #(
        .DIFF_TERM ("TRUE")
    ) ibufds_inst (
        .I  ( sig_p[i]),
        .IB ( sig_n[i]),
        .O  (sig_se[i])
    );

    // IDDR: double data rate at 2f to 2 x single data rate at f
    // i==14 is the clock signal and shall not get an IDDR
    if( i<=13 )
        IDDR #(
            .DDR_CLK_EDGE("SAME_EDGE_PIPELINED")
        ) IDDR_inst (
            .D  (sig_del[i] ),      // DDR data input
            .C  (clk_ab_del ),      // clock input
            // Odd / even bits had to be swapped here to get clk phase right
            .Q1 (sdrSamples[2*i]),  // output even bits
            .Q2 (sdrSamples[2*i+1]),// output odd bits
            .CE (1'b1       ),      // clock enable input
            .R  (rst        ),      // reset
            .S  (1'b0       )       // set
        );
end endgenerate

//---------------------------------------------
// Adjustable IDELAYs (on Reg0)
//---------------------------------------------
idelays_pack #(
    .BASE_ADDR     ( BASE_ADDR     ),
    .BASE2_ADDR    ( BASE2_OFFSET  ),   // Takes one BASE2 slot
    .SIZE          ( 14 )   // 14 data lanes, no idelay for the clock
) idels_inst (
    .in            (sig_se[13:0]),
    .out_del       (sig_del),
    .clk           (clk),
    .rst           (rst),
    .mem_packed_fwd(mem_packed_fwd),
    .mem_packed_ret(packed_del_ret)
);

// Make sure the clock is routed on a global net
BUFG bufg_inst (
    .I( sig_se[14] ),
    .O( clk_ab_del )
);

//---------------------------------------------
// Freq. counter for clk_ab_del (on Reg2)
//---------------------------------------------
wire [27:0] clkAbFreqCnt;
freq_count #(
    .glitch_thresh(15)
) fcnt (
    .f_in              (clk_ab_del),
    .sysclk            (clk),
    .frequency         (clkAbFreqCnt),
    .freq_strobe       (),
    .diff_stream       (),
    .diff_stream_strobe(),
    .glitch_catcher    ()
);

//---------------------------------------------
// Sample Monitor (on Reg1)
//---------------------------------------------
// for picorv monitoring the test-pattern on { BASE_ADDR, 8'h01, 16'h00 }
// chB: [29:16],  chA: [13:0]
reg [(2*28-1):0] sdrSamplesPingPong;
reg pingOrPong = 1'b0;
always @(posedge clk_ab_del) begin
    sdrSamplesPingPong[pingOrPong*28+:28] <= sdrSamples;
    pingOrPong <= ~pingOrPong;
end

// A naughty way of crossing clock domains, but (hopefully) ok for static test-patterns
reg [(2*28-1):0] sdrSamplesPingPongClk;
always @(posedge clk) sdrSamplesPingPongClk <= sdrSamplesPingPong;

sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR      ),
    .BASE2_ADDR     ( BASE2_OFFSET + 1 ),
    .N_REGS         ( 3              )
) sfrInst (
    .clk            ( clk            ),
    .rst            ( rst            ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( packed_mon_ret ),
    .sfRegsOut      (),
    .sfRegsIn       ( {
        4'h0, clkAbFreqCnt,                  // reg2,[27:0]
        2'h0, sdrSamplesPingPongClk[42+:14], // reg1,  hi16
        2'h0, sdrSamplesPingPongClk[28+:14], // reg1, low16
        2'h0, sdrSamplesPingPongClk[14+:14], // reg0,  hi16
        2'h0, sdrSamplesPingPongClk[ 0+:14]  // reg0, low16
    } ),
    .sfRegsWrStr    ()
);

endmodule
