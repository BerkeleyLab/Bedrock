`timescale 1 ns / 1 ps

module fmc150_tb;
    localparam CLK_PERIOD =    1.0/0.200; // System clock period in [ns]
    localparam CLK_AB_PERIOD = 1.0/0.224; // DSP clock period in [ns]
    reg mem_clk=1, clk_ab=1;
    integer cc=0;
    initial
        while (1) begin
            #(CLK_PERIOD/2);
            mem_clk=~mem_clk;
            cc = cc + 1;
        end
    initial begin
        #(2.345)
        while (1) begin
            #(CLK_AB_PERIOD/2);
            clk_ab=~clk_ab;
        end
    end
    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg rst = 1;
    integer pass=1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("fmc150.vcd");
            $dumpvars(5,fmc150_tb);
        end
        repeat (10) @(posedge mem_clk);
        rst <= 0;
        #40000
        pass = 0;
        $display("TIMEOUT\nFAIL");
        $stop();
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    always @(posedge mem_clk) begin
        if (~rst && trap) begin
            $display("TRAP");
            if (pass) begin
                $display("PASS");
                $finish;
            end
            $display("FAIL");
            $stop;
        end
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    pico_pack cpu (
        .clk           ( mem_clk        ),
        .reset         ( rst            ),
        .trap          ( trap           ),
        .irqFlags      ( 32'b0          ),
        // Packed bus
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > ...
        .mem_packed_ret( packed_cpu_ret )  //CPU < ...
    );
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_cha_ret;
    wire [32:0] packed_ads_ret;
    assign packed_cpu_ret = packed_mem_ret |
                            packed_ads_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory_pack #(
        .MEM_INIT      ("./fmc15032.hex"),
        .BASE_ADDR     (8'h00)
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk        ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ),
        .mem_packed_ret( packed_mem_ret )
    );

    // Naive way of generating a DDR test signal
    reg [13:0] testValue=14'b10101010101010;
    reg [ 6:0] testSample =7'h0;
    integer i;
    always @(posedge clk_ab) begin
        for (i=0; i<=6; i=i+1)
            testSample[i] = testValue[2*i];
    end
    always @(negedge clk_ab) begin
        for (i=0; i<=6; i=i+1)
            testSample[i] = testValue[2*i+1];
        testValue = ~testValue;
    end

    ads62 #(
        .BASE_ADDR       (8'h01),
        .BASE2_OFFSET    (8'h02),
        .REFCLK_FREQUENCY(200.0)
    ) ads62_inst (
        .clk_ab_p      ( clk_ab),
        .clk_ab_n      (~clk_ab),
        .inA_p         ( testSample),
        .inA_n         (~testSample),
        .inB_p         ( testSample),
        .inB_n         (~testSample),
        .outA          (),
        .outB          (),
        .clk           (mem_clk),
        .rst           (rst),
        .mem_packed_fwd(packed_cpu_fwd),
        .mem_packed_ret(packed_ads_ret)
    );

    IDELAYCTRL idelayctrl_inst (
      .RST    ( rst     ),
      .REFCLK ( mem_clk ),
      .RDY    (         )
    );

endmodule
