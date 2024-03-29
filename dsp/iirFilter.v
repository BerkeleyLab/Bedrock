// Infinite Impulse Response Filter
//
// Chain of biquad elements
//
module iirFilter #(
    parameter STAGES            = -1,
    parameter DATA_WIDTH        = -1,
    parameter DATA_COUNT        = -1,
    parameter COEFFICIENT_WIDTH = -1,
    parameter DEBUG             = "false"
) (
    input        sysClk,
    input        sysGPIO_Strobe,
    input [31:0] sysGPIO_Out,

    input                                                          dataClk,
    (*mark_debug=DEBUG*) input       [(DATA_COUNT*DATA_WIDTH)-1:0] S_TDATA,
    (*mark_debug=DEBUG*) input                                     S_TVALID,
    (*mark_debug=DEBUG*) output wire                               S_TREADY,
    (*mark_debug=DEBUG*) output wire [(DATA_COUNT*DATA_WIDTH)-1:0] M_TDATA,
    (*mark_debug=DEBUG*) output wire                               M_TVALID,
    (*mark_debug=DEBUG*) input                                     M_TREADY
);

// Can't use $clog2 in localparam expression with this version of the tools.
parameter STAGE_ADDRESS_WIDTH = $clog2(STAGES);

reg [STAGES-1:0]sysStageSelect;
reg       [23:0]sysCoefficientValueHigh;
reg        [2:0]sysCoefficientAddress;
wire [24+31-1:0]sysCoefficientValue={sysCoefficientValueHigh,sysGPIO_Out[30:0]};
wire            sysIsValue = sysGPIO_Out[31];

always @(posedge sysClk) begin
    if (sysGPIO_Strobe && !sysIsValue) begin
        sysCoefficientAddress <= sysGPIO_Out[2:0];
        sysStageSelect <= 1 << sysGPIO_Out[3+:STAGE_ADDRESS_WIDTH];
        sysCoefficientValueHigh <= sysGPIO_Out[31:8];
    end
end

///////////////////////////////////////////////////////////////////////////////
// Instantiate stages

localparam DW = DATA_COUNT*DATA_WIDTH;

wire [((STAGES+1)*DW)-1:0] interStageData;
wire [STAGES:0] interStageValid, interStageReady;

assign interStageData[0+:DW] = S_TDATA;
assign interStageValid[0] = S_TVALID;
assign S_TREADY = interStageReady[0];
assign M_TDATA = interStageData[STAGES*DW+:DW];
assign M_TVALID = interStageValid[STAGES];
assign interStageReady[STAGES] = M_TREADY;

genvar i;
generate
for (i = 0 ; i < STAGES ; i = i + 1) begin
  biquad #(.DATA_WIDTH(DATA_WIDTH),
           .DATA_COUNT(DATA_COUNT),
           .COEFFICIENT_WIDTH(COEFFICIENT_WIDTH))
    biquad_i(
      .sysClk(sysClk),
      .sysCoefficientStrobe(sysGPIO_Strobe && sysIsValue && sysStageSelect[i]),
      .sysCoefficientAddress(sysCoefficientAddress),
      .sysCoefficientValue(sysCoefficientValue[COEFFICIENT_WIDTH-1:0]),
      .dataClk(dataClk),
      .S_TDATA(interStageData[i*DW+:DW]),
      .S_TVALID(interStageValid[i]),
      .S_TREADY(interStageReady[i]),
      .M_TDATA(interStageData[(i+1)*DW+:DW]),
      .M_TVALID(interStageValid[i+1]),
      .M_TREADY(interStageReady[i+1]));

end
endgenerate
endmodule
