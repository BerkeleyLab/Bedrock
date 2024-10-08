// Move tinyEVR's 64-bit timestamp to another clock domain
// Uses Gray codes to get (almost) ideal results.
// Time delay is one evr_clk plus one-to-two usr_clk cycles.
// Yes, that's the inevitable clock-domain-crossing jitter.
//
// The Gray code scheme fails at the time when ts_tcks gets reset to zero by the evr_pps event.
// As a workaround, the first _two_ values of the output usr_tcks are forced to zero, every time usr_secs is updated.
//
// Obligatory xkcd: https://xkcd.com/2867/
module evr_ts_cdc(
    input evr_clk,
    input [31:0] ts_secs,
    input [31:0] ts_tcks,
    input evr_pps,
    //
    input usr_clk,
    output [31:0] usr_secs,
    output [31:0] usr_tcks
);

// binary to Gray
reg [31:0] ts_tgray=0;
always @(posedge evr_clk) ts_tgray <= ts_tcks ^ {1'b0, ts_tcks[30:1]};

// CDC
reg [31:0] usr_tgray=0;
always @(posedge usr_clk) usr_tgray <= ts_tgray;

// Gray to binary
// verilator lint_save
// verilator lint_off UNOPTFLAT
wire [31:0] usr_bin1 = usr_tgray ^ {1'b0, usr_bin1[30:1]};
// verilator lint_restore
reg [31:0] usr_bin=0;
always @(posedge usr_clk) usr_bin <= usr_bin1;

// Move coarse seconds across
// Almost, but not quite, data_xdomain.
reg pps_toggle=0;
always @(posedge evr_clk) if (evr_pps) pps_toggle <= ~pps_toggle;
reg pps_cap0=0, pps_cap1=0;
reg [31:0] usr_sec1=0, usr_sec2=0;
wire pps_grab = pps_cap0 != pps_cap1;
always @(posedge usr_clk) begin
    pps_cap0 <= pps_toggle;
    pps_cap1 <= pps_cap0;
    usr_sec1 <= ts_secs;
    if (pps_grab) usr_sec2 <= usr_sec1;
end

// At this point usr_sec2 is right, and usr_bin is (almost always) right,
// but there is a chance they will not roll over at the same time.
// That means you can get usr_bin as 0 or 1 with the old value of usr_sec2
// for a cycle, or usr_sec2 updated to the new value a cycle before usr_bin jumps back to 0 or 1.
// My test bench is (sadly) not good enough to show the effect.
// Eliminating that potential glitch isn't easy, and seems guaranteed to have side effects.
// The approach below zeros out the tcks data from _both_ possibly corrupt edges.
reg pps_grab1=0;
reg [31:0] usr_bin2=0;
wire pps_zero = pps_grab | pps_grab1;
always @(posedge usr_clk) begin
    pps_grab1 <= pps_grab;
    usr_bin2 <= pps_zero ? 32'b0 : usr_bin;
end
assign usr_secs = usr_sec2;
assign usr_tcks = usr_bin2;

endmodule
