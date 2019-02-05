`timescale 1 ns / 1ns

module decimationLowpass_tb;

parameter STAGES            = 2;
parameter DATA_WIDTH        = 28;
parameter CHANNEL_COUNT     = 4;
parameter COEFFICIENT_WIDTH = 25;
parameter DECIMATION_FACTOR = 1000;

reg clk = 1;
reg csrStrobe = 0;
reg [31:0] GPIO_OUT = {32{1'bx}};

reg inputToggle = 0;
reg decimateFlag = 1; // No decimation for now -- want to check filter response
reg [(CHANNEL_COUNT*DATA_WIDTH)-1:0] inputData = {CHANNEL_COUNT*DATA_WIDTH{1'bx}};
wire outputToggle;
wire [(CHANNEL_COUNT*DATA_WIDTH)-1:0] outputData;

decimationLowpass #(.DATA_WIDTH(DATA_WIDTH),
                    .CHANNEL_COUNT(CHANNEL_COUNT),
                    .COEFFICIENT_WIDTH(COEFFICIENT_WIDTH))
  decimationLowpass (
    .clk(clk),
    .csrStrobe(csrStrobe),
    .GPIO_OUT(GPIO_OUT),
    .inputData(inputData),
    .inputToggle(inputToggle),
    .decimateFlag(decimateFlag),
    .outputData(outputData),
    .outputToggle(outputToggle));

always begin
    #5 clk = !clk;
end

integer pass = 1;
integer xCheck, x, xOld;
integer i;

initial begin
    $dumpfile("decimationLowpass_tb.lxt");
    $dumpvars(0, decimationLowpass_tb);
    #40;

    $display("Unity gain");
    setCoefficients(1, 0, 0, 0, 0, 1, 0, 0, 0, 0);
    step(20, 1000000);

    $display("First order");
    setCoefficients(0.1, 0, 0, -0.9, 0, 1, 0, 0, 0, 0);
    step(100, 1000000);

    $display("4th-order Elliptic (SA Fc=4)");
    setCoefficients(0.0624582422449415,
                   -0.124914164588175,
                    0.0624582422465767,
                   -1.99853376375492,
                    0.998536083658262,
                    0.636826823900075,
                   -1.27364754862627,
                    0.636826823883403,
                   -1.9997058160665,
                    0.999711915223715);
    step(20000, 1000000);

    #100;
    $display("%s",  pass ? "PASS" : "FAIL");
    $finish;
end

task setCoefficients;
    input real b00, b01, b02, a01, a02, b10, b11, b12, a11, a12;
    reg [COEFFICIENT_WIDTH-1:0] ib0, ib1, ib2, ia1, ia2, v;
    reg [32-3-1:0] bIndex;
    reg [2:0] cIndex;
    begin
    for (bIndex = 0 ; bIndex < STAGES ; bIndex += 1) begin
        case (bIndex)
        0: begin
            ib0 = (1 << (COEFFICIENT_WIDTH-2)) * b00;
            ib1 = (1 << (COEFFICIENT_WIDTH-2)) * b01;
            ib2 = (1 << (COEFFICIENT_WIDTH-2)) * b02;
            ia1 = (1 << (COEFFICIENT_WIDTH-2)) * a01;
            ia2 = (1 << (COEFFICIENT_WIDTH-2)) * a02;
        end
        1: begin
            ib0 = (1 << (COEFFICIENT_WIDTH-2)) * b10;
            ib1 = (1 << (COEFFICIENT_WIDTH-2)) * b11;
            ib2 = (1 << (COEFFICIENT_WIDTH-2)) * b12;
            ia1 = (1 << (COEFFICIENT_WIDTH-2)) * a11;
            ia2 = (1 << (COEFFICIENT_WIDTH-2)) * a12;
        end
        endcase
        for (cIndex = 0 ; cIndex < 5 ; cIndex += 1) begin
            case (cIndex)
            0: v = ib0;
            1: v = ib1;
            2: v = ib2;
            3: v = -ia2;
            4: v = -ia1;
            endcase
            @(posedge clk) begin
                GPIO_OUT <= { bIndex, cIndex };
                csrStrobe <= 1;
            end
            @(posedge clk) begin
                GPIO_OUT <= { 1'b1, {32-1-COEFFICIENT_WIDTH{1'b0}}, v };
            end
            @(posedge clk) begin
                GPIO_OUT <= {32{1'bx}};
                csrStrobe <= 0;
            end
        end
    end
    cIndex = 7;
    for (bIndex = 0 ; bIndex < STAGES ; bIndex += 1) begin
        @(posedge clk) begin
            GPIO_OUT <= { bIndex, cIndex };
            csrStrobe <= 1;
        end
        @(posedge clk) begin
            GPIO_OUT <= { 1'b1, {31{1'bx}} };
        end
        @(posedge clk) begin
            GPIO_OUT <= {32{1'bx}};
            csrStrobe <= 0;
        end
    end
    @(posedge clk) ;
    end
endtask

task step;
    input integer steps;
    input [DATA_WIDTH-1:0] u;
    integer i;
    begin
    for (i = 0 ; i < 10 ; i = i + 1) begin
        crankFilter(0);
    end
    for (i = 0 ; i < steps ; i = i + 1) begin
        crankFilter(u);
    end
    end
endtask

reg outputToggle_d = 0;
always @(posedge clk) begin
    outputToggle_d <= outputToggle;
end

task crankFilter;
    input [DATA_WIDTH-1:0] u;
    reg [(CHANNEL_COUNT*DATA_WIDTH)-1:0] dIn;
    reg [DATA_WIDTH-1:0] y;
    begin
    for (i = 0 ; i < DATA_WIDTH ; i = i + 1) begin
        dIn[i*DATA_WIDTH+:DATA_WIDTH] = u * (i + 1);
    end
    @(posedge clk) begin
        inputData <= dIn;
        inputToggle <= ~inputToggle;
    end
    while (outputToggle == outputToggle_d) @(posedge clk);
    y = outputData[DATA_WIDTH-1:0];
    $display("%d %d", u, y);
    end
endtask

endmodule
