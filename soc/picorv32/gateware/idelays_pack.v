// --------------------------------------------------------------
//  idelays_pack.v
// --------------------------------------------------------------
// make the IDELAYE2 delay circuits of each of the 7-series input
// pins controllable by picorv32
//
// Defines a single register at {BASE_ADDR, BASE2_ADDR, 16'h0} with content:
// reg[31:13] = 0
// reg[12: 8] = del_val
// reg[ 7: 0] = del_mux
// where:
// del_mux = index of the IDELAY channel to read / write (0 .. SIZE-1)
// del_val = IDELAY tap value (0 .. 31)
//
// Add this to TOP:
//
// (* IODELAY_GROUP = "idelays_pack_group" *)
// IDELAYCTRL idelayctrl_inst (
//   .RST    ( rst ),
//   .REFCLK ( clk ),
//   .RDY    (     )
// );

module idelays_pack #(
    parameter [7:0] BASE_ADDR =8'h00,
    parameter [7:0] BASE2_ADDR=8'h00,
    parameter [7:0] SIZE=1,
    parameter       REFCLK_FREQUENCY=200.0 //[MHz] one of: 200, 300, 400
) (
    input  [SIZE-1:0] in,       // interface to IOB / PAD
    output [SIZE-1:0] out_del,  // delayed interface to ISERDESE2 / fabric
    // PicoRV32 packed MEM Bus interface
    input             clk,
    input             rst,
    input  [68:0]     mem_packed_fwd,
    output [32:0]     mem_packed_ret
);

wire [31:0] sfRegsOut, sfRegsInp, sfRegsWrt;
// del_mux = index of selected idelay to read / write
wire [ 7:0]     del_mux =  sfRegsOut[ 7:0];
// del_val = delay tap value to write to idelay (0-31)
wire [ 4:0]     del_val =  sfRegsOut[12:8];
// del_wrt pulses high when del_val is written
wire            del_wrt = |sfRegsWrt[12:8];
// Binary decoder to provide an individual `LD` signal to each idelay
wire [SIZE-1:0] del_ld = (del_wrt << del_mux);
// Many to one multiplexer for tap-value readback
wire [ 4:0]     del_mon[SIZE-1:0];
assign sfRegsInp = { 19'h0, del_mon[del_mux], del_mux };

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

genvar i;
generate for (i=0; i<SIZE; i=i+1) begin: idel
    IDELAYE2 #(
        .CINVCTRL_SEL         ( "FALSE"    ),// Enable dynamic clock inversion ("TRUE"/"FALSE")
        .DELAY_SRC            ( "IDATAIN"  ),// Delay input ("IDATAIN" or "DATAIN")
        .HIGH_PERFORMANCE_MODE( "TRUE"     ),// Reduced jitter ("TRUE"), Reduced power ("FALSE")
        .IDELAY_TYPE          ( "VAR_LOAD" ),// "FIXED", "VARIABLE", "VAR_LOAD" or "VAR_LOAD_PIPE"
        .IDELAY_VALUE         ( 0          ),// Delay tap setting for FIXED mode (0-31)
        .REFCLK_FREQUENCY     ( REFCLK_FREQUENCY),// IDELAYCTRL clock input frequency in MHz
        .SIGNAL_PATTERN       ( "DATA"     ),// "DATA" or "CLOCK" input signal
        .PIPE_SEL             ( "FALSE"    ) // Select pipelined mode, "TRUE"/"FALSE"
    ) idelaye2_inst (
        .CNTVALUEOUT          ( del_mon[i] ),// Tap value for monitoring purpose
        .DATAOUT              ( out_del[i] ),// Delayed data output
        .C                    ( clk        ),// Clock input
        .CE                   ( 1'b0       ),// Active high enable increment/decrement function
        .CINVCTRL             ( 1'b0       ),// Dynamically inverts the Clock (C) polarity
        .CNTVALUEIN           ( del_val    ),// Counter value for loadable counter application
        .DATAIN               ( 1'b0       ),// fabric-style input
        .IDATAIN              ( in[i]      ),// IOB-style input
        .INC                  ( 1'b0       ),// Increment / Decrement tap delay
        .REGRST               ( rst        ),// Active high, synchronous reset,
        // resets delay chain to IDELAY_VALUE tap. If no value is specified, the default is 0.
        .LD                   ( del_ld[i]  ),// Pulse high to latch IDELAY_VALUE input
        .LDPIPEEN             ( 1'b0       ) // Enable PIPELINE register to load data input
    );
end endgenerate
endmodule
