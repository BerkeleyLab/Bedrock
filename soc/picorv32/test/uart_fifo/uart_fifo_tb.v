`timescale 1 ns / 1 ns

module uart_fifo_tb;
    localparam CLK_PERIOD = 10;    // Simulated clock period in [ns]
    reg mem_clk=1;
    always #(CLK_PERIOD/2)   mem_clk = ~mem_clk;

    //------------------------------------------------------------------------
    //  Handle the power on Reset
    //------------------------------------------------------------------------
    reg reset = 1;
    reg pass=1;
    initial begin
        if ($test$plusargs("vcd")) begin
            $dumpfile("uart_fifo.vcd");
            $dumpvars(5,uart_fifo_tb);
        end
        repeat (10) @(posedge mem_clk);
        reset <= 0;
        #500000
        $display("TIMEOUT\nFAIL");
        $stop();
    end

    wire trap;
    // --------------------------------------------------------------
    //  Catch the trap signal to end simulation
    // --------------------------------------------------------------
    // `retVal` is the value returned from main()
    wire [31:0] retVal = cpu.picorv32_core.dbg_reg_x10;
    always @(posedge mem_clk) begin
        if (~reset && trap) begin
            if (retVal == 32'h1) begin
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
    wire [31:0] irqFlags;
    assign irqFlags[2:0] = 0;
    assign irqFlags[4]   = 0;
    assign irqFlags[31:6]= 0;
    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [ 3:0] mem_la_wstrb;
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    `define DEBUGREGS
    pico_pack cpu (
        .clk           ( mem_clk        ),
        .reset         ( reset          ),
        .trap          ( trap           ),
        .irqFlags      ( irqFlags       ), //Rising edge interrupts
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
    wire [32:0] packed_uart_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_uart_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    memory2_pack #(
        .MEM_INIT      ("./uart_fifo32.hex"  ),
        .BASE_ADDR     ( 8'h00          )
    ) mem_inst (
        // Hardware interface
        .clk           ( mem_clk        ),
        .reset         (reset           ),
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
    //  UART module
    // --------------------------------------------------------------
    wire        uart_rx0;
    wire        uart_tx0;
    // uart_pack #(
    uart_fifo_pack #(
        .DATA_WIDTH  ( 8 ),
        .BASE_ADDR     (8'h08)
    ) uart (
        // Hardware interface
        .clk           ( mem_clk        ),
        .rst           ( reset          ),
        .rxd           ( uart_rx0       ),
        .txd           ( uart_tx0       ),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd( packed_cpu_fwd ),
        .mem_packed_ret( packed_uart_ret)
    );
    // loop back
    assign uart_rx0 = uart_tx0;

endmodule
