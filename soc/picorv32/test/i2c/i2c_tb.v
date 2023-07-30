// This testbench does test all of the following
//  * soft_i2c library against a simulated model device
//  * gpioz_pack tristate IO module
//  * gpio_pack IO module
//  * sfr_pack bit addressable memory module
//

`timescale 1 ns / 1 ns

module i2c_tb;
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
            $dumpfile("i2c.vcd");
            $dumpvars(5,i2c_tb);
        end
        $display("R = picorv reads data");
        $display("W = picorv writes data");
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #1000000
        $display("\nTIMEOUT\nFAIL");
        $stop(0);
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    wire trap;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            $display("\nTRAP\nFAIL");
            $stop(0);
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
        .MEM_INIT      ("./i2c32.hex"),
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
    //  Simulated I2C model
    // --------------------------------------------------------------
    localparam PIN_I2C_SDA = 1;  // has to match settings.h
    localparam PIN_I2C_SCL = 0;  // has to match settings.h
    pullup ( gpio_z[PIN_I2C_SDA] );
    pullup ( gpio_z[PIN_I2C_SCL] );
    wire       read_req;
    wire       data_valid;
    wire [7:0] data_from_tb;
    reg  [7:0] data_to_tb = 8'h00;
    wire stop;
    I2C_model #(
        .ADDR      ( 7'h42             )
    ) i2c_model (
        .clk             ( mem_clk           ),
        .rst             ( reset             ),
        .sda             ( gpio_z[PIN_I2C_SDA]),
        .scl             ( gpio_z[PIN_I2C_SCL]),

        // Data interface
        .read_req        ( read_req ),
        .data_to_tb  ( data_to_tb ),
        .data_valid      ( data_valid ),
        .data_from_tb( data_from_tb ),
        .stop        (stop)
    );

    // --------------------------------------------------------------
    //  Pass / Fail sequence
    // --------------------------------------------------------------
    // all names from picorv master point of view (read = return data to picorv)
    // hand over 8 random bytes to master and take them back
    localparam [31:0] N_BYTES = 8;
    reg [7:0] testData[N_BYTES-1:0];
    integer x;
    initial begin
        i2c_wait_for_start();
        i2c_write_task(  8'h24 );
        i2c_wait_for_start();
        for (x=0; x<N_BYTES; x=x+1 )begin
            testData[x] = $random;
            i2c_read_task( testData[x] );
        end
        i2c_wait_for_stop();

        i2c_wait_for_start();
        i2c_write_task( 8'h24 );
        for (x=0; x<N_BYTES; x=x+1 )begin
            i2c_write_task( testData[x] );
        end
        i2c_wait_for_stop();
        if (pass) begin
            $display("PASS");
            $finish;
        end
        $display("FAIL");
        $stop(0);
    end

    // --------------------------------------------------------------
    // Blocking helper functions
    // --------------------------------------------------------------
    task i2c_wait_for_start;
        begin
            wait (i2c_model.start_reg);
            $write("<start> ");
        end
    endtask

    task i2c_wait_for_stop;
        begin
            wait (stop);
            $write("<stop>\n");
        end
    endtask

    task i2c_read_task;
        input [7:0] sendVal;
        begin
            @ (posedge mem_clk);
            data_to_tb <= sendVal;
            wait (read_req);
            $write("R%x ", data_to_tb);
            @ (posedge mem_clk);
        end
    endtask

    task i2c_write_task;
        input [7:0] expectVal;
        begin
            wait( data_valid );
            @ (posedge mem_clk);
            if( data_from_tb === expectVal ) begin
                $write("W%x ", data_from_tb);
            end else begin
                $write("W<%2x!=%2x> ", data_from_tb, expectVal);
                pass = 0;
            end
            @ (posedge mem_clk);
        end
    endtask

endmodule
