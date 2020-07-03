// system.v either interfaces to physical FPGA pins or to this testbench
// The output from UART0 is printed to the console

`timescale 1 ns / 1 ns

module system_tb;
    // parameters need to match settings.h

    // Simulated clock rate in [Hz]
    localparam F_CLK = (1200000 * 625 / 9);

    // Simulated clock period in [ns]
    localparam CLK_PERIOD_NS = 1000000000 / F_CLK;

    // matches BOOTLOADER_BAUDRATE in Makefile
    // localparam BOOTLOADER_BAUDRATE = 10416666;

    // UART clock dividers (they have an additional /8 divider inside)
    localparam UART_CLK_DIV = F_CLK / `BOOTLOADER_BAUDRATE / 8;
    wire [15:0] uart_prescale = UART_CLK_DIV;

    reg clk_p=1, clk_n=0;
    always #(CLK_PERIOD_NS / 2) begin
        clk_p = ~clk_p;
        clk_n = ~clk_n;
    end

    // ------------------------------------------------------------------------
    //  Handle the power on Reset
    // ------------------------------------------------------------------------
    reg reset = 1;
    reg pass = 1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("system.vcd");
            $dumpvars(5, system_tb);
        end
        $display(
            "UART0 baud_rate: %8d (clk_div: %4d)",
            `BOOTLOADER_BAUDRATE, UART_CLK_DIV
        );
        repeat(100) @(posedge clk_p);
        reset <= 0;

        // repeat(200000) @(posedge clk_p);  // 2 ms
        // $display("TIMEOUT");
        // $stop();
    end

    // ------------------------------------------------------------------------
    //  Instantiate the unit under test (system.v)
    // ------------------------------------------------------------------------
    wire trap;
    wire uart_tx0;
    wire uart_rx0;
    wire [31:0]gpio_z;

    wire [ 7:0] ram_data_z;
    wire [23:0] ram_address;
    wire        ram_nce;
    wire        ram_noe;
    wire        ram_nwe;

    `define DEBUGREGS
    system #(
        .SYSTEM_HEX_PATH("system32.hex")
    ) uut (
        .clk        (clk_p),
        .cpu_reset  (reset),
        .uart_tx0   (uart_tx0   ),
        .uart_rx0   (uart_rx0   ),
        .gpio_z     (gpio_z     ),
        .trap       (trap       ),

          // SRAM Hardware interface
        .ram_data_z  (ram_data_z),
        .ram_address (ram_address),
        .ram_nce     (ram_nce),
        .ram_noe     (ram_noe),
        .ram_nwe     (ram_nwe)
    );

    sram_model sram_model_inst (
        .we_n(ram_nwe),
        .ce_n(ram_nce),
        .oe_n(ram_noe),
        .addr(ram_address[18:0]),
        .data(ram_data_z)
    );

    assign gpio_z[31:0] = 0;

    // ------------------------------------------------------------------------
    //  Virtual UART bridge to console
    // ------------------------------------------------------------------------
    wire [7:0] urx_tdata;
    wire       urx_tvalid;
    reg        urx_tready;
    uart_rx #(
        .DATA_WIDTH(8)
    ) uart_debug_rx (
        .prescale           (uart_prescale),
        .clk                (clk_p),
        .rst                (reset),   // UART expects an active high reset
        // axi output
        .output_axis_tdata  (urx_tdata),
        .output_axis_tvalid (urx_tvalid),
        .input_axis_tready (urx_tready),
        // uart pins
        .rxd                (uart_tx0)
    );

    // If the virtual debug UART received data, print it to the console
    always @(posedge clk_p) begin
        urx_tready <= 0;
        if (!reset && urx_tvalid && !urx_tready) begin
            $write("%c", urx_tdata);
            $fflush();
            urx_tready <= 1;
        end
    end

    reg [7:0] utx_tdata = 8'h0;
    reg        utx_tvalid = 1'b0;
    wire       utx_tready;
    uart_tx #(
        .DATA_WIDTH(8)
    ) uart_debug_tx (
        .prescale         (uart_prescale),
        .clk              (clk_p),
        .rst              (reset),
        .input_axis_tdata (utx_tdata),
        .input_axis_tvalid(utx_tvalid),
        .output_axis_tready(utx_tready),
        .txd              (uart_rx0)
    );

    // send characters to the picorv UART
    task wchar;
        input [7:0] char;
        begin
            wait(utx_tready);
            @ (posedge clk_p);
            utx_tvalid = 1'b1;
            utx_tdata = char;
            @ (posedge clk_p);
            utx_tvalid = 1'b0;
        end
    endtask

    // test sequence
    initial begin
        // test soft-reset
        // #200000
        // wchar(8'h14);
        // start sieving
        #200000
        wchar("s");
    end

    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    // But wait until the UART is done receiving the last character
    // `retVal` is the value returned from main()
    wire [31:0] retVal = uut.cpu_inst.picorv32_core.dbg_reg_x10;
    always @(posedge clk_p) begin
        if (~reset && trap && !uart_debug_rx.busy) begin
            #10000
            $display("TRAP,  return %08x;", retVal);
            if (retVal == 32'h1234)
                $finish;
            else
                $stop;
        end
        $fflush();
    end

endmodule
