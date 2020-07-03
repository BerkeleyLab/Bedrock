// system.v either interfaces to physical FPGA pins or to this testbench
// The CPU softcore and internal memory interface is both handled by system.v
// The output from UART0 is printed to the console

`timescale 1 ns / 1 ns

module system_tb;
    localparam F_CLK = 125000000;                      // Simulated clock rate in [Hz]
    localparam CLK_PERIOD_NS = 1000000000 / F_CLK;     // Simulated clock period in [ns]
    localparam UART_CLK_DIV = F_CLK / `BOOTLOADER_BAUDRATE / 8;
    reg clk=1, clk_n=0;
    integer pass=0;
    always #(CLK_PERIOD_NS / 2) begin
        clk = ~clk;
    end

    // ------------------------------------------------------------------------
    //  Handle the power on Reset
    // ------------------------------------------------------------------------
    reg reset = 1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("system.vcd");
            $dumpvars(5,system_tb);
        end
        $display(
            "UART0 baud_rate: %8d (clk_div: %4d)",
            `BOOTLOADER_BAUDRATE, UART_CLK_DIV
        );
        repeat (100) @(posedge clk);
        reset <= 0;
        #500000 $display("Simulation finish.");
        //$display("\n%8s", pass ? "PASS" : "FAIL" );
        $finish;
    end

    // ------------------------------------------------------------------------
    //  Instantiate the unit under test (system.v)
    // ------------------------------------------------------------------------
    wire trap;
    wire uart_tx;
    wire uart_rx;
    wire [31:0] gpio_z;

    `define DEBUGREGS
    system #(
        .SYSTEM_HEX_PATH("system32.hex")
    ) uut (
        .clk        (clk),
        .cpu_reset  (reset),
        .gpio_z     (gpio_z),
        .uart_tx    (uart_tx),
        .uart_rx    (uart_rx),
        .trap       (trap )
    );

    // ------------------------------------------------------------------------
    //  Instantiate the virtual UART which receives debug data from UART0
    // ------------------------------------------------------------------------
    //  its purpose is to print debug characers to the console
    wire [7:0] urx_tdata0;
    wire       urx_tvalid0;
    reg        urx_tready0;

    uart_rx #(
        .DATA_WIDTH(8)                // We transmit / receive 8 bit words + 1 start and stop bit
    ) uart_debug0 (
        .prescale(UART_CLK_DIV[15:0]),
        .clk ( clk ),
        .rst ( reset  ),            // UART expects an active high reset
        // axi output
        .output_axis_tdata(  urx_tdata0 ),
        .output_axis_tvalid( urx_tvalid0 ),
        .input_axis_tready( urx_tready0 ),
        // uart pins
        .rxd( uart_tx )
    );

    always @(posedge clk) begin
        urx_tready0 <= 0;
        // If the virtual debug UART received data, print it to the console
        if (!reset && urx_tvalid0 && !urx_tready0) begin
            $write("%c", urx_tdata0);
            $fflush();
            urx_tready0 <= 1;
        end
    end

    // End the simulation when the CPU falls into a `trap`
    // But wait until the UART is done receiving the last character
    always @(posedge clk) begin
        if (!reset && trap && !uart_debug0.busy) begin
            #10000
            $display("TRAP");
            $stop;
        end
    end

    wire i2c_scl = gpio_z[1];
    wire i2c_sda = gpio_z[0];
    pullup (i2c_scl);
    pullup (i2c_sda);

    wire [7:0] i2c_ioout;
    i2c_model #(
        .I2C_ADR    (7'h74)
    ) i2c_model (
        .SDA        (i2c_sda),
        .SCL        (i2c_scl),
        .IOout      (i2c_ioout)
    );

endmodule
