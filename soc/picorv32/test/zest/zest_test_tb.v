`timescale 1 ns / 1 ps

module zest_test_tb;
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
            $dumpfile("zest_test.vcd");
            $dumpvars(5,zest_test_tb);
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
        .MEM_INIT      ("./zest_test32.hex"),
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
    reg [ 7:0] testSample =8'h0;
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
    wire adc_pdwn = 0;
    zest #(
        .BASE_ADDR       (8'h01)
    ) zest_inst (
        .ADC_PDWN           (adc_pdwn),
        .CLK_TO_FPGA_P      ( clk_ab),
        .CLK_TO_FPGA_N      (~clk_ab),
        .ADC_D0_P         ( testSample),
        .ADC_D0_N         ( ~testSample),
        .ADC_DCO_P (2'b00),
        .ADC_DCO_N (2'b00),
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
