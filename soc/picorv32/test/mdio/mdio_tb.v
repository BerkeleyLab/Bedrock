// https://en.wikipedia.org/wiki/Management_Data_Input/Output

`timescale 1 ns / 1 ns

module mdio_tb;
    localparam CLK_PERIOD = 10;    // Simulated clock period in [ns]
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    integer pass=0;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("mdio.vcd");
            $dumpvars(5,mdio_tb);
        end
        $display("R = picorv reads data");
        $display("W = picorv writes data");
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #1500000
        $display("\nTIMEOUT\n%8s", "FAIL");
        $stop();
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("CPU trap. Stop.");
            if (pass) begin
                $display("\n    PASS\n");
                $finish();
            end else begin
                $display("\n    FAIL\n");
                $stop();
            end
        end
        $fflush();
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
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
    assign packed_cpu_ret = packed_mem_ret | packed_gpio_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory_pack #(
        .MEM_INIT      ("./mdio32.hex"),
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
    //  Simulated slave
    // --------------------------------------------------------------
    localparam PIN_PHY_RESET_B = 2; // has to match settings.h
    localparam PIN_PHY_MDIO = 1;    // has to match settings.h
    localparam PIN_PHY_MDC  = 0;    // has to match settings.h

    pullup ( gpio_z[PIN_PHY_MDIO] );

    mdio_slave #(
        .ADDR            ( 5'h10             )
    ) phy (
        .reset_b         ( gpio_z[PIN_PHY_RESET_B]),
        .mdio            ( gpio_z[PIN_PHY_MDIO]),
        .mdc             ( gpio_z[PIN_PHY_MDC])
    );

    // --------------------------------------------------------------
    //  Pass / Fail sequence
    // --------------------------------------------------------------
    wire cpu_read_valid = cpu.picorv32_core.dbg_mem_ready
                       && cpu.picorv32_core.dbg_insn_addr == 32'h382
                       && cpu.picorv32_core.dbg_mem_rdata == 32'hdead;
    initial begin
        wait (cpu_read_valid);
        pass = 1;
        $display("\nTime: %g ns, register read back passed.", $time);
        $display("Done.\n");
        $finish();
    end

endmodule
