`timescale 1 ns / 1ns

module biquad_tb;

parameter DATA_WIDTH        = 28;
parameter DATA_COUNT        = 4;
parameter COEFFICIENT_WIDTH = 25;

reg sysClk = 1, dataClk = 1;
reg sysCoefficientStrobe = 0;
reg                   [2:0] sysCoefficientAddress = {3{1'bx}};
reg [COEFFICIENT_WIDTH-1:0] sysCoefficientValue = {COEFFICIENT_WIDTH{1'bx}};

reg S_TVALID = 0;
reg [(DATA_COUNT*DATA_WIDTH)-1:0] S_TDATA = {DATA_COUNT*DATA_WIDTH{1'bx}};
wire S_TREADY;
wire M_TVALID;
wire [(DATA_COUNT*DATA_WIDTH)-1:0] M_TDATA;

biquad #(.DATA_WIDTH(DATA_WIDTH),
         .DATA_COUNT(DATA_COUNT),
         .COEFFICIENT_WIDTH(COEFFICIENT_WIDTH))
  biquad (
    .sysClk(sysClk),
    .sysCoefficientStrobe(sysCoefficientStrobe),
    .sysCoefficientAddress(sysCoefficientAddress),
    .sysCoefficientValue(sysCoefficientValue),
    .dataClk(dataClk),
    .S_TDATA(S_TDATA),
    .S_TVALID(S_TVALID),
    .S_TREADY(S_TREADY),
    .M_TDATA(M_TDATA),
    .M_TVALID(M_TVALID),
    .M_TREADY(1'b1));

always begin
    #5 sysClk = !sysClk;
end
always begin
    #4 dataClk = !dataClk;
end

integer pass = 1;
integer xCheck, x, xOld;
integer i;

initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("biquad.vcd");
        $dumpvars(3,biquad_tb);
    end
    #40;

    $display("Unity gain");
    setCoefficients(1, 0, 0, 0, 0);
    check(-101, -101);
    check(101, 101);
    check({1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1},
          {1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1});

    $display("Unity gain, one sample delay");
    setCoefficients(0, 1, 0, 0, 0);
    check(-101, 0);
    check(101, -101);
    check({1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1}, 101);
    check(0, {1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1});

    $display("Unity gain, two sample delay");
    setCoefficients(0, 0, 1, 0, 0);
    check(-101, 0);
    check(101, 0);
    check({1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1}, -101);
    check(0, 101);
    check(0, {1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1});

    $display("Boxcar average");
    setCoefficients(1, 1, 1, 0, 0);
    check(101, 101);
    check(101, 202);
    check(101, 303);
    check(101, 303);
    check(-101, 101);
    check(-101, -101);
    check(101, -101);
    check(101,  101);
    // Check overflow
    check({1'b0, {DATA_WIDTH-1{1'b1}}}, {1'b0, {DATA_WIDTH-1{1'b1}}});
    check({1'b0, {DATA_WIDTH-1{1'b1}}}, {1'b0, {DATA_WIDTH-1{1'b1}}});
    check(0, {1'b0, {DATA_WIDTH-1{1'b1}}});
    // Check exit from overflow
    check(-1, {1'b0, {DATA_WIDTH-1{1'b1}}} - 1);
    check(0, -1);

    $display("Weighted average (FIR)");
    setCoefficients(0.1, -0.25, 0.65, 0, 0);
    check(100000000, 10000000);
    check( 90000000,-16000000);
    check( 80000000, 50500000);
    check(        0, 38500000);

    $display("First order low pass");
    setCoefficients(0.25, 0, 0, -0.75, 0);
    x = 16777216;
    check(16777216 * 4, x);
    for (i = 0 ; i < 20 ; i += 1) begin
        x = x * 3 / 4;
        check(0, x);
    end
    setCoefficients(0.125, 0, 0, -0.875, 0);
    x = -67108864 / 8;
    for (i = 0 ; i < 20 ; i += 1) begin
        check(-67108864, x);
        x = (-67108864  + x * 7) / 8;
    end

    $display("Second order low pass");
    setCoefficients(0.5, 0, 0, -1, 0.5);
    x = 0;
    xOld = 0;
    for (i = 0 ; i < 20 ; i += 1) begin
        xCheck = 5000000 + x - (xOld / 2);
        check(10000000, xCheck);
        xOld = x;
        x = xCheck;
    end

    #100;
    $display("%s",  pass ? "PASS" : "FAIL");
    $finish;
end

task setCoefficients;
    input real b0, b1, b2, a1, a2;
    reg [COEFFICIENT_WIDTH-1:0] ib0, ib1, ib2, ia1, ia2;
    begin
    ib0 = (1 << (COEFFICIENT_WIDTH-2)) * b0;
    ib1 = (1 << (COEFFICIENT_WIDTH-2)) * b1;
    ib2 = (1 << (COEFFICIENT_WIDTH-2)) * b2;
    ia1 = (1 << (COEFFICIENT_WIDTH-2)) * a1;
    ia2 = (1 << (COEFFICIENT_WIDTH-2)) * a2;

    @(posedge sysClk) begin
        sysCoefficientAddress <= 0;
        sysCoefficientValue <= ib0;
        sysCoefficientStrobe <= 1;
    end
    @(posedge sysClk) begin
        sysCoefficientAddress <= 1;
        sysCoefficientValue <= ib1;
    end
    @(posedge sysClk) begin
        sysCoefficientAddress <= 2;
        sysCoefficientValue <= ib2;
    end
    @(posedge sysClk) begin
        sysCoefficientAddress <= 3;
        sysCoefficientValue <= -ia2;
    end
    @(posedge sysClk) begin
        sysCoefficientAddress <= 4;
        sysCoefficientValue <= -ia1;
    end
    @(posedge sysClk) begin
        sysCoefficientAddress <= 7;
        sysCoefficientValue <= {COEFFICIENT_WIDTH{1'bx}};
    end
    @(posedge sysClk) begin
        sysCoefficientAddress <= {3{1'bx}};
        sysCoefficientStrobe <= 0;
    end
    end
endtask

task check;
    input signed [DATA_WIDTH-1:0] u, yGood;
    reg [(DATA_COUNT*DATA_WIDTH)-1:0] dIn, dOutGood;
    reg signed [DATA_WIDTH-1:0] yActual, diff;
    integer i, match, near;
    begin
    for (i = 0 ; i < DATA_WIDTH ; i = i + 1) begin
        dIn[i*DATA_WIDTH+:DATA_WIDTH] = u * $signed(i + 1);
        dOutGood[i*DATA_WIDTH+:DATA_WIDTH] = yGood * $signed(i + 1);
    end
    @(posedge dataClk) begin
        S_TDATA <= dIn;
        S_TVALID <= 1;
    end
    while (!S_TREADY) #1;
    @(posedge dataClk) begin
        S_TDATA <= {DATA_COUNT*DATA_WIDTH{1'bx}};
        S_TVALID <= 0;
    end
    while (!M_TVALID) @(posedge dataClk);
    yActual = $signed(M_TDATA[DATA_WIDTH-1:0]);
    if (M_TDATA == dOutGood) begin
        match = 1;
        near = 1;
    end
    else begin
        match = 0;
        diff = yGood - yActual;
        if ($abs(diff) <= 4) begin
            near = 1;
        end
        else begin
            near = 0;
            pass = 0;
        end
    end
    $display("u:%d expect:%d got:%d   dIn:%x dOutGood:%x dOut:%x %s", u, yGood,
                                    yActual, dIn, dOutGood, M_TDATA,
                                    match ? "PASS" : near ? "NEAR" : "FAIL");
    @(posedge dataClk) ;
    end
endtask

endmodule
