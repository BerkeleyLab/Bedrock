// system.v either interfaces to physical FPGA pins or to this testbench
// The CPU softcore and internal memory interface is both handled by system.v
// The output from UART0 is printed to the console

`timescale 1 ns / 1 ns

module general_tb;
    localparam F_CLK = 100000000;                      // Simulated clock rate in [Hz]
    localparam CLK_PERIOD_NS = 1000000000/F_CLK;       // Simulated clock period in [ns]
    localparam BAUD_RATE = 9216000;                    // debug text baudrate
    reg clk_p=1, clk_n=0;
    always #(CLK_PERIOD_NS/2) begin
        clk_p = ~clk_p;
        clk_n = ~clk_n;
    end

    // ------------------------------------------------------------------------
    //  Handle the power on Reset
    // ------------------------------------------------------------------------
    reg reset = 1;
    reg [15:0] baud_rate=0;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("system.vcd");
            $dumpvars(5,general_tb);
        end
        baud_rate = (F_CLK/(BAUD_RATE*8))|1;
        $display("Testbench UART Baud-rate: %d (prescaler: %d)", BAUD_RATE, baud_rate);
        repeat (100) @(posedge clk_p);
        reset <= 0;
    end


    // ------------------------------------------------------------------------
    //  Instantiate the unit under test (system.v)
    // ------------------------------------------------------------------------
    wire trap;
    wire uart_tx0;
    wire uart_rx0;
    wire [31:0]gpio_z;
    `define DEBUGREGS
    system #(
        .SYSTEM_HEX_PATH("./system32.hex")
    ) uut (
        .clk        (clk_p),
        .cpu_reset  (reset),
        .uart_tx0   (uart_tx0   ),
        .uart_rx0   (uart_rx0   ),
        .gpio_z     (gpio_z     ),
        .trap       (trap       )
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
        .prescale           (baud_rate),
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
        .prescale         (baud_rate),
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

    initial begin
        // test soft-reset
        #200000
        wchar(8'h14);
        // test sieving
        #400000
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
            #100000
            $display("TRAP");
            if (retVal == 32'h0) begin
                // $display("PASS");
                $finish;
            end
            // $display("FAIL");
            $stop;
        end
        $fflush();
    end

endmodule
