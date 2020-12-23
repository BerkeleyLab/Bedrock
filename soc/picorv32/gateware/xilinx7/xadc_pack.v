module xadc_pack #(
    parameter SIM_MONITOR_FILE="design.txt",
    parameter  [7:0] BASE_ADDR=8'h01
) (
    // XADC hardware pin
    input trigger_in,
    input vp_in,                 // Dedicated Analog Input Pair
    input vn_in,
    input [15:0] vaux_p,
    input [15:0] vaux_n,

    input         clk,
    input         reset,
    // PicoRV32 packed MEM Bus interface
    input  [68:0] mem_packed_fwd,  //CPU > SFR
    output [32:0] mem_packed_ret   //DEC < SFR
);

/// #define XADC_BASE2_XADC 0x0
/// #define XADC_BASE2_SFR  0x100000
localparam [7:0] BASE2_XADC = 8'h00;
localparam [7:0] BASE2_SFR  = 8'h10;

wire [32:0] mem_packed_sfr_ret;
wire [32:0] mem_packed_xadc_ret;
assign mem_packed_ret = mem_packed_sfr_ret | mem_packed_xadc_ret;

wire [31:0] sfRegsOut, sfRegsInp, sfRegsWrt;
sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR      ),
    .BASE2_ADDR     ( BASE2_SFR       ),
    .N_REGS         ( 1              )
) sfrInst (
    .clk            ( clk            ),
    .rst            ( reset          ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_sfr_ret ),
    .sfRegsOut      ( sfRegsOut      ),
    .sfRegsIn       ( sfRegsInp      ),
    .sfRegsWrStr    ( sfRegsWrt      )
);

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire [31:0] mem_rdata;
wire        mem_ready;
munpack mu (
    .clk           (clk),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_xadc_ret ),

    .mem_wdata ( mem_wdata    ),
    .mem_wstrb ( mem_wstrb    ),
    .mem_valid ( mem_valid    ),
    .mem_addr  ( mem_addr     ),
    .mem_ready ( mem_ready    ),
    .mem_rdata ( mem_rdata    )
);

wire reset_in;
wire den_in;
wire dwe_in;
reg [15:0] di_in=0;
reg [6:0] daddr_in=0;
wire [15:0] do_out;
wire drdy_out;
wire busy_out;
wire eoc_out;
wire eos_out;
wire [4:0] channel_out;
wire [7:0] alm_int;
wire ot_out;

/// #define SFR_BIT_BUSY    0
/// #define SFR_BIT_EOC     1
/// #define SFR_BIT_EOS     2
/// #define SFR_BIT_OT      4
/// #define SFR_BYTE_CHANNEL_OUT 4
/// #define SFR_BYTE_ALM_INT     12

/// #define SFR_BIT_XADC_RESET    0
assign sfRegsInp = {
    12'h0,
    alm_int,
    3'h0, channel_out,
    ot_out, eos_out, eoc_out, busy_out};

wire xadc_reset;
assign xadc_reset = sfRegsWrt[0];

wire mem_addr_hit = mem_valid && mem_addr[31:16]=={BASE_ADDR, BASE2_XADC};
// word access only
wire mem_write = &mem_wstrb && mem_addr_hit;
wire mem_read = !(|mem_wstrb) && mem_addr_hit;
reg drp_valid=0, drp_valid1=0;
// UG480 Figure 5-3
always @(posedge clk) begin
    drp_valid <= 1'b0;
    drp_valid1 <= drp_valid;
    if (!mem_ready && mem_addr_hit) begin // software handle busy_out
        drp_valid <= 1'b1;
        di_in <= mem_wdata[15:0];
        daddr_in <= mem_addr[8:2];
    end
end
assign mem_rdata = drdy_out ? do_out : 0;
assign mem_ready = drdy_out;

assign den_in = drp_valid && !drp_valid1;
assign dwe_in = den_in && mem_write;

assign reset_in = (reset || xadc_reset);
// event mode
(* ASYNC_REG="TRUE" *) reg trig_m=0, trig=0;
always @(posedge clk) begin
    trig_m <= trigger_in;
    trig <= trig_m;
end

XADC #(
    .INIT_40(16'h0000), // config reg 0, no average
    .INIT_41(16'h21A0), // config reg 1
    .INIT_42(16'h0500), // config reg 2
    .INIT_48(16'h0F00), // Sequencer channel selection
    .INIT_49(16'h0000), // Sequencer channel selection
    .INIT_4A(16'h0000), // Sequencer Average selection
    .INIT_4B(16'h0000), // Sequencer Average selection
    .INIT_4C(16'h0000), // Sequencer Bipolar selection
    .INIT_4D(16'h0000), // Sequencer Bipolar selection
    .INIT_4E(16'h0000), // Sequencer Acq time selection
    .INIT_4F(16'h0000), // Sequencer Acq time selection
    .INIT_50(16'hB5ED), // Temp alarm trigger
    .INIT_51(16'h57E4), // Vccint upper alarm limit
    .INIT_52(16'hA147), // Vccaux upper alarm limit
    .INIT_53(16'hCA33), // Temp alarm OT upper
    .INIT_54(16'hA93A), // Temp alarm reset
    .INIT_55(16'h52C6), // Vccint lower alarm limit
    .INIT_56(16'h9555), // Vccaux lower alarm limit
    .INIT_57(16'hAE4E), // Temp alarm OT reset
    .INIT_58(16'h5999), // VCCBRAM upper alarm limit
    .INIT_5C(16'h5111), //  VCCBRAM lower alarm limit
    .SIM_DEVICE("7SERIES"),
    .SIM_MONITOR_FILE(SIM_MONITOR_FILE)// Analog Stimulus file for simulation
) xadc_inst (
        .CONVST         (trig),
        .CONVSTCLK      (trig),
        .DADDR          (daddr_in),
        .DCLK           (clk),
        .DEN            (den_in),
        .DI             (di_in),
        .DWE            (dwe_in),
        .RESET          (reset_in),
        .VAUXN          (vaux_n),
        .VAUXP          (vaux_p),
        .ALM            (alm_int),
        .BUSY           (busy_out),
        .CHANNEL        (channel_out),
        .DO             (do_out),
        .DRDY           (drdy_out),
        .EOC            (eoc_out),
        .EOS            (eos_out),
        .JTAGBUSY       (),
        .JTAGLOCKED     (),
        .JTAGMODIFIED   (),
        .OT             (ot_out),
        .MUXADDR        (),
        .VP             (vp_in),
        .VN             (vn_in)
);

endmodule
