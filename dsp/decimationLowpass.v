//
// Low pass filter for FA/SA decimastion
//
module decimationLowpass #(
    parameter DATA_WIDTH        = -1,
    parameter CHANNEL_COUNT     = -1,
    parameter COEFFICIENT_WIDTH = -1,
    parameter DEBUG             = "false"
    ) (
    input                     clk,
    input                     csrStrobe,
    input              [31:0] GPIO_OUT,

    input [(CHANNEL_COUNT*DATA_WIDTH)-1:0] inputData,
    input                                  inputToggle,
    input                                  decimateFlag,

    output reg                                  outputToggle = 0,
    output reg [(CHANNEL_COUNT*DATA_WIDTH)-1:0] outputData);

reg inputToggle_d = 0;
reg downsample = 0;
wire dInValid = (inputToggle != inputToggle_d);
wire dOutValid;
wire [(CHANNEL_COUNT*DATA_WIDTH)-1:0] dOut;
always @(posedge clk) begin
    inputToggle_d <= inputToggle;
    if (dInValid) begin
        downsample <= decimateFlag;
    end
    if (dOutValid && downsample) begin
        outputData <= dOut;
        outputToggle <= !outputToggle;
    end
end

// Add a bit since our values are unsigned.
// Add another bit to allow for filter overshoot.
// Add some bits on least-significant side to provide rounding.
localparam MSB_WIDEN = 2;
localparam LSB_WIDEN = 8;
localparam FULL_WIDTH = MSB_WIDEN + DATA_WIDTH + LSB_WIDEN;
wire [(CHANNEL_COUNT*FULL_WIDTH)-1:0] dInWide;
wire [(CHANNEL_COUNT*FULL_WIDTH)-1:0] dOutWide;
genvar i;
generate
for (i = 0 ; i < CHANNEL_COUNT ; i = i + 1) begin
    assign dInWide[i*FULL_WIDTH+:FULL_WIDTH] = {
                                            {MSB_WIDEN{1'b0}},
                                            inputData[i*DATA_WIDTH+:DATA_WIDTH],
                                            {LSB_WIDEN{1'b0}} };
    // Clip negative values to 0
    // Clip overflow to maximum value
    assign dOut[i*DATA_WIDTH+:DATA_WIDTH] =
            dOutWide[(i+1)*FULL_WIDTH-1] ? {DATA_WIDTH{1'b0}} :
            dOutWide[(i+1)*FULL_WIDTH-2] ? {DATA_WIDTH{1'b1}} :
                                 dOutWide[(i*FULL_WIDTH)+LSB_WIDEN+:DATA_WIDTH];
end
endgenerate

iirFilter #( .STAGES(2),
             .DATA_WIDTH(FULL_WIDTH),
             .DATA_COUNT(CHANNEL_COUNT),
             .COEFFICIENT_WIDTH(COEFFICIENT_WIDTH),
             .DEBUG(DEBUG))
  iirFilter_i (
    .sysClk(clk),
    .sysGPIO_Strobe(csrStrobe),
    .sysGPIO_Out(GPIO_OUT),
    .dataClk(clk),
    .S_TDATA(dInWide),
    .S_TVALID(dInValid),
    .S_TREADY(),
    .M_TDATA(dOutWide),
    .M_TVALID(dOutValid),
    .M_TREADY(1'b1));

endmodule
