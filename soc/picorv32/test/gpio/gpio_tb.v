`timescale 1 ns / 1 ns

module gpio_tb;
    localparam CLK_PERIOD = 10;    // Simulated clock period in [ns]
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    integer pass=1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("gpio.vcd");
            $dumpvars(5,gpio_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #100000
        pass = 0;
        $display("TIMEOUT\nFAIL");
        $stop();
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            pass = 0;
            $display("preliminary TRAP\nFAIL");
            $stop();
        end
    end

    // --------------------------------------------------------------
    //  Instantiate the packed picorv32 CPU core
    // --------------------------------------------------------------
    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [ 3:0] mem_la_wstrb;
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    pico_pack cpu (
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        .trap          ( trap           ),
        .irqFlags      ( 32'b0          ),
        // Look ahead mem interface
        .mem_la_read   (mem_la_read     ),
        .mem_la_write  (mem_la_write    ),
        .mem_la_addr   (mem_la_addr     ),
        .mem_la_wdata  (mem_la_wdata    ),
        .mem_la_wstrb  (mem_la_wstrb    ),
        // Packed bus
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > ...
        .mem_packed_ret( packed_cpu_ret )  //CPU < ...
    );
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_gpio_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_gpio_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory2_pack #(
        .MEM_INIT      ("./gpio32.hex"  ),
        .BASE_ADDR     ( 8'h00          )
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        // Look ahead interface
        .mem_la_read   (mem_la_read     ),
        .mem_la_write  (mem_la_write    ),
        .mem_la_addr   (mem_la_addr     ),
        .mem_la_wdata  (mem_la_wdata    ),
        .mem_la_wstrb  (mem_la_wstrb    ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_ret( packed_mem_ret )  //CPU < MEM
    );

    // --------------------------------------------------------------
    //  GPIO module
    // --------------------------------------------------------------
    wire [31:0] out;
    wire [31:0] oe;
    gpio_pack #(
        .BASE_ADDR     (8'h01)
    ) gpio (
        // Hardware interface
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ), //CPU > GPIO
        .mem_packed_ret( packed_gpio_ret), //CPU < GPIO
        // Hardware interface
        .gpio_out      ( out            ),
        .gpio_oe       ( oe             ),
        .gpio_in       ( out ^ oe       )  //for testing the read back
    );

    // --------------------------------------------------------------
    //  Make the CPU speak
    // --------------------------------------------------------------
    // always @(posedge cpu.picorv32_core.clk) begin
    //     if (cpu.mem_valid && cpu.mem_ready) begin
    //         if (cpu.picorv32_core.mem_instr)
    //             ;// $display("ifetch 0x%08x: 0x%08x", cpu.mem_addr, cpu.mem_rdata);
    //         else if (cpu.mem_wstrb)
    //             $display("write  0x%08x: 0x%08x (wstrb=%b)", cpu.mem_addr, cpu.mem_wdata, cpu.mem_wstrb);
    //         else begin
    //             $display("read   0x%08x: 0x%08x", cpu.mem_addr, cpu.mem_rdata);
    //         end
    //     end
    // end

    // --------------------------------------------------------------
    //  Pass / fail logic
    // --------------------------------------------------------------
    initial begin
        // 32 bit mode
        gpio_expect( 32'h12345678, 32'h00000000 );
        gpio_expect( 32'h12345678, 32'hAAAAAAAA );
        gpio_expect( 32'h12345678^32'hAAAAAAAA, 32'hAAAAAAAA );
        gpio_expect( 32'hFFFFFFFF, 32'hAAAAAAAA );

        // 16 bit mode
        gpio_expect( 32'hFFFFFFFF, 32'hDEADAAAA );
        gpio_expect( 32'hFFFFFFFF, 32'hDEADBEEF );

        // 8 bit mode
        gpio_expect( 32'hFFFFFF10, 32'hDEADBEEF );
        gpio_expect( 32'hFFFF3210, 32'hDEADBEEF );
        gpio_expect( 32'hFF543210, 32'hDEADBEEF );
        gpio_expect( 32'h76543210, 32'hDEADBEEF );
        gpio_expect( 32'hFFFFFFFF, 32'hDEADBEEF );
        gpio_expect( 32'hFFFFFFFF, 32'h00000000 );

        // 1 bit mode - set
        gpio_expect( 32'hFFFFFFFF, (1<<0) );
        gpio_expect( 32'hFFFFFFFF, (1<<0)|(1<<2) );
        gpio_expect( 32'hFFFFFFFF, (1<<0)|(1<<2)|(1<<28) );

        // 1 bit mode - clear
        gpio_expect( 32'hFFFFFFFF^(               (1<<1)), (1<<0)|(1<<2)|(1<<28) );
        gpio_expect( 32'hFFFFFFFF^(        (1<<3)|(1<<1)), (1<<0)|(1<<2)|(1<<28) );
        gpio_expect( 32'hFFFFFFFF^((1<<31)|(1<<3)|(1<<1)), (1<<0)|(1<<2)|(1<<28) );

        if (pass) begin
            $display("PASS");
            $finish;
        end
        $display("FAIL");
        $stop;
    end

    task gpio_expect;
        input [31:0] out_expect;
        input [31:0]  oe_expect;
        begin
            // Wait for gpio activity
            wait (gpio.sfrInst.mem_ready && |gpio.sfrInst.mem_wstrb);
            @ (posedge mem_clk);
            $display("out: %x  oe: %x", out, oe);
            if ( out !== out_expect ) begin
                $error("out should be %x", out_expect);
                pass = 0;
            end
            if ( oe !== oe_expect ) begin
                $error("oe should be %x", oe_expect);
                pass = 0;
            end
            @ (posedge mem_clk);
        end
    endtask

endmodule
