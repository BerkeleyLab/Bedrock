`timescale 1ns / 1ns

module iirFilter_tb;

parameter STAGES            = 2;
parameter DATA_WIDTH        = 28;
parameter DATA_COUNT        = 4;
parameter COEFFICIENT_WIDTH = 25;

reg sysClk = 1, dataClk = 1;
reg sysGPIO_Strobe = 0;
reg [31:0] sysGPIO_Out = {32{1'bx}};

reg S_TVALID = 0;
reg [(DATA_COUNT*DATA_WIDTH)-1:0] S_TDATA = {DATA_COUNT*DATA_WIDTH{1'bx}};
wire S_TREADY;
wire M_TVALID;
wire [(DATA_COUNT*DATA_WIDTH)-1:0] M_TDATA;

iirFilter #(.STAGES(STAGES),
            .DATA_WIDTH(DATA_WIDTH),
            .DATA_COUNT(DATA_COUNT),
            .COEFFICIENT_WIDTH(COEFFICIENT_WIDTH))
  iirFilter (
    .sysClk(sysClk),
    .sysGPIO_Strobe(sysGPIO_Strobe),
    .sysGPIO_Out(sysGPIO_Out),
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
        $dumpfile("iirFilter.vcd");
        $dumpvars(3,iirFilter_tb);
    end
    #40;

    $display("Unity gain");
    setCoefficients(1, 0, 0, 0, 0);
    check(-101, -101);
    check(101, 101);
    check({1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1},
          {1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1});

    $display("Unity gain, one sample delay per biquad");
    setCoefficients(0, 1, 0, 0, 0);
    check(-101, 0);
    check(101, 0);
    check({1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1}, -101);
    check(0, 101);
    check(0, {1'b1, {DATA_WIDTH-2{1'b0}}, 1'b1});

    $display("Weighted average (FIR)");
    setCoefficients(0.1, -0.25, 0.65, 0, 0);
    check(100000000,  1000000);
    check( 90000000, -4100000);
    check( 80000000, 15550000);
    check(        0,-19175000);

    #100;
    if (pass) begin
      $display("PASS");
      $finish();
    end else begin
      $display("FAIL");
      $stop();
    end
end

task setCoefficients;
    input real b0, b1, b2, a1, a2;
    reg [COEFFICIENT_WIDTH-1:0] ib0, ib1, ib2, ia1, ia2, v;
    reg [32-3-1:0] bIndex;
    reg [2:0] iIndex;
    begin
    ib0 = (1 << (COEFFICIENT_WIDTH-2)) * b0;
    ib1 = (1 << (COEFFICIENT_WIDTH-2)) * b1;
    ib2 = (1 << (COEFFICIENT_WIDTH-2)) * b2;
    ia1 = (1 << (COEFFICIENT_WIDTH-2)) * a1;
    ia2 = (1 << (COEFFICIENT_WIDTH-2)) * a2;
    for (bIndex = 0 ; bIndex < STAGES ; bIndex += 1) begin
        for (iIndex = 0 ; iIndex < 5 ; iIndex += 1) begin
            case (iIndex)
            0: v = ib0;
            1: v = ib1;
            2: v = ib2;
            3: v = -ia2;
            4: v = -ia1;
            endcase
            @(posedge sysClk) begin
                sysGPIO_Out <= { bIndex, iIndex };
                sysGPIO_Strobe <= 1;
            end
            @(posedge sysClk) begin
                sysGPIO_Out <= { 1'b1, {32-1-COEFFICIENT_WIDTH{1'b0}}, v };
            end
            @(posedge sysClk) begin
                sysGPIO_Out <= {32{1'bx}};
                sysGPIO_Strobe <= 0;
            end
        end
    end
    iIndex = 7;
    for (bIndex = 0 ; bIndex < STAGES ; bIndex += 1) begin
        @(posedge sysClk) begin
            sysGPIO_Out <= { bIndex, iIndex };
            sysGPIO_Strobe <= 1;
        end
        @(posedge sysClk) begin
            sysGPIO_Out <= { 1'b1, {31{1'bx}} };
        end
        @(posedge sysClk) begin
            sysGPIO_Out <= {32{1'bx}};
            sysGPIO_Strobe <= 0;
        end
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
