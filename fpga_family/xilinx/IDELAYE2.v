// This is super basic. Not anywhere near to complete!!!

`timescale 1 ns / 1 ps

module IDELAYE2 (CNTVALUEOUT, DATAOUT, C, CE, CINVCTRL, CNTVALUEIN, DATAIN, IDATAIN, INC, LD, LDPIPEEN, REGRST);
    parameter CINVCTRL_SEL = "FALSE";
    parameter DELAY_SRC = "IDATAIN";
    parameter HIGH_PERFORMANCE_MODE    = "FALSE";
    parameter IDELAY_TYPE  = "FIXED";
    parameter integer IDELAY_VALUE = 0;
    parameter [0:0] IS_C_INVERTED = 1'b0;
    parameter [0:0] IS_DATAIN_INVERTED = 1'b0;
    parameter [0:0] IS_IDATAIN_INVERTED = 1'b0;
    parameter PIPE_SEL = "FALSE";
    parameter real REFCLK_FREQUENCY = 200.0;
    parameter SIGNAL_PATTERN    = "DATA";

    output [4:0] CNTVALUEOUT;
    output reg DATAOUT;
    input C;
    input CE;
    input CINVCTRL;
    input [4:0] CNTVALUEIN;
    input DATAIN;
    input IDATAIN;
    input INC;
    input LD;
    input LDPIPEEN;
    input REGRST;

// To get a bit more than 360 degree range
localparam real TAP_DEL = (1.0 / REFCLK_FREQUENCY * 1000 / 31);

// assign DATAOUT = IDATAIN;
reg [4:0] cntValue = 5'h0;
assign CNTVALUEOUT = cntValue;

always @(posedge C) begin
    if(LD) begin
        cntValue <= CNTVALUEIN;
    end
end

reg [31:0] shiftReg = 32'h0;
always begin
    #(TAP_DEL);
    shiftReg = { shiftReg[30:0], IDATAIN };
    DATAOUT = shiftReg[cntValue];
end

endmodule // IDELAYE2
