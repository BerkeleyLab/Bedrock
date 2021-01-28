// This testbench does test all of the following
//  * onewire_soft library against a simulated model
//  * gpioz_pack tristate IO module
//  * gpio_pack IO module
//  * sfr_pack bit addressable memory module

`timescale 1 ns / 1 ns

module onewire_tb;
    // CLK_PERIOD should match F_CLK in settings.h
    localparam CLK_PERIOD = 200;    // Simulated clock period in [ns]
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    integer pass=1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("onewire.vcd");
            $dumpvars(5,onewire_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #25000000
        $display("\nTIMEOUT\nFAIL");
        $stop();
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    // `retVal` is the value returned from main()
    wire [31:0] retVal = cpu.picorv32_core.dbg_reg_x10;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("\nTRAP");
            if (retVal == 32'h1) begin
                $display("PASS");
                $finish;
            end
            $display("FAIL");
            $stop;
        end
        $fflush();
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    `define DEBUGREGS
    pico_pack cpu (
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        .trap          ( trap           ),
        .irqFlags      ( 32'b0          ),
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > ...
        .mem_packed_ret( packed_cpu_ret )  //CPU < ...
    );
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_gpio_ret;
    wire [32:0] packed_dbg_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_gpio_ret | packed_dbg_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory_pack #(
        .MEM_INIT      ("./onewire32.hex"),
        .BASE_ADDR     ( 8'h00          )
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk        ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > MEM
        .mem_packed_ret( packed_mem_ret )  //CPU < MEM
    );

    // --------------------------------------------------------------
    //  GPIO module
    // --------------------------------------------------------------
    wire [31:0] gpio_z;
    gpioz_pack #(
        .BASE_ADDR     (8'h01)
    ) gpio (
        // Hardware interface
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > GPIO
        .mem_packed_ret( packed_gpio_ret), //CPU < GPIO
        // Hardware interface
        .gpio_z        ( gpio_z         )
    );

    // --------------------------------------------------------------
    //  Debug "console"
    // --------------------------------------------------------------
    debug_console #(
        .BASE_ADDR     (8'h02)
    ) dbg (
        .clk           ( mem_clk        ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > DBG
        .mem_packed_ret( packed_dbg_ret)   //CPU < DBG
    );

    // --------------------------------------------------------------
    //  Simulated onewire model
    // --------------------------------------------------------------
    localparam PIN_ONEWIRE_A = 3;  // has to match settings.h
    localparam PIN_ONEWIRE_B = 4;

    pullup(gpio_z[PIN_ONEWIRE_A]);
    pullup(gpio_z[PIN_ONEWIRE_B]);

    // Simplified mockup of a onewire device
    ds1822 #(
        .debug(0),
        .rom  (64'hbe000008e52f8e01)
    ) ds1822_A_inst (
        .pin(gpio_z[PIN_ONEWIRE_A])
    );

    ds1822 #(
        .debug(0),
        .rom  (64'h1234567890123456)
    ) ds1822_B_inst (
        .pin(gpio_z[PIN_ONEWIRE_B])
    );

endmodule
