`timescale 1 ns / 1 ps

module system #(
    parameter SYSTEM_HEX_PATH="system32.hex"
) (
    input               clk,
    input               reset,
    output              trap,

    // UART
    output              uart_tx0,  // debug
    input               uart_rx0,

    // SRAM Hardware interface
    inout  [ 7:0] ram_data_z,
    output [23:0] ram_address,
    output        ram_nce,
    output        ram_noe,
    output        ram_nwe
);
    localparam IRQ_UART0_RX     = 8'h03;

    localparam BASE_MEM         = 8'h00;
    localparam BASE_SRAM        = 8'h01;
    localparam BASE_UART0       = 8'h02;

    wire        mem_la_read;
    wire        mem_la_write;
    wire [31:0] mem_la_addr;
    wire [31:0] mem_la_wdata;
    wire [ 3:0] mem_la_wstrb;
    wire [68:0] packed_cpu_fwd;
    wire [32:0] packed_cpu_ret;
    wire [31:0] irqFlags;

    genvar g;
    for(g=0; g<=31; g=g+1)
        pulldown(irqFlags[g]);

    pico_pack cpu (
        .clk           (clk),
        .reset         (reset),
        .trap          (trap),
        .irqFlags      (irqFlags), //Rising edge interrupts
        // Look ahead mem interface
        .mem_la_read   (mem_la_read),
        .mem_la_write  (mem_la_write),
        .mem_la_addr   (mem_la_addr),
        .mem_la_wdata  (mem_la_wdata),
        .mem_la_wstrb  (mem_la_wstrb),
        // Packed bus
        .mem_packed_fwd(packed_cpu_fwd), //CPU > ...
        .mem_packed_ret(packed_cpu_ret)  //CPU < ...
    );
    wire [32:0] packed_mem_ret;
    wire [32:0] packed_sram_ret;
    wire [32:0] packed_URT0_ret;
    assign packed_cpu_ret = packed_mem_ret | packed_sram_ret | packed_URT0_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    `ifdef MEMORY_PACK_FAST
        memory2_pack #(
            .MEM_INIT      (SYSTEM_HEX_PATH),
            .BASE_ADDR     (BASE_MEM)
        ) mem_inst (
            // Hardware interface
            .clk           (clk),
            .reset         (reset),

            // Look ahead interface
            .mem_la_read   (mem_la_read),
            .mem_la_write  (mem_la_write),
            .mem_la_addr   (mem_la_addr),
            .mem_la_wdata  (mem_la_wdata),
            .mem_la_wstrb  (mem_la_wstrb),

            // PicoRV32 packed MEM Bus interface
            .mem_packed_ret(packed_mem_ret)
        );
    `else
        memory_pack #(
            .MEM_INIT      (SYSTEM_HEX_PATH),
            .BASE_ADDR     (BASE_MEM)
        ) mem_inst (
            // Hardware interface
            .clk           (clk),

            // PicoRV32 packed MEM Bus interface
            .mem_packed_fwd(packed_cpu_fwd),
            .mem_packed_ret(packed_mem_ret)
        );
    `endif

    // --------------------------------------------------------------
    //  UART0, does printf
    // --------------------------------------------------------------
    uart_pack #(
        .DATA_WIDTH  (8),
        .BASE_ADDR   (BASE_UART0)
    ) uart_inst0 (
        // Hardware interface
        .clk         (clk),
        .rst         (reset),
        .rxd         (uart_rx0),
        .txd         (uart_tx0),
        .irq_rx_valid(irqFlags[IRQ_UART0_RX]),
        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd(packed_cpu_fwd), //CPU > URT
        .mem_packed_ret(packed_URT0_ret)  //CPU < URT
    );

    // --------------------------------------------------------------
    //  SRAM module
    // --------------------------------------------------------------
    `ifdef MEMORY_PACK_FAST
        sram2_pack #(
            .BASE_ADDR     (BASE_SRAM)
        ) sram (
            // Hardware interface
            .clk           (clk),

            // Look ahead interface
            .mem_la_read   (mem_la_read),
            .mem_la_write  (mem_la_write),
            .mem_la_addr   (mem_la_addr),
            .mem_la_wdata  (mem_la_wdata),
            .mem_la_wstrb  (mem_la_wstrb),

            // PicoRV32 packed MEM Bus interface
            .mem_packed_ret(packed_sram_ret),

            // Hardware interface
            .ram_data_z    (ram_data_z),
            .ram_address   (ram_address),
            .ram_nce       (ram_nce),
            .ram_noe       (ram_noe),
            .ram_nwe       (ram_nwe)
        );
    `else
        sram_pack #(
            .BASE_ADDR     (BASE_SRAM)
        ) sram (
            // Hardware interface
            .clk           (clk),

            // PicoRV32 packed MEM Bus interface
            .mem_packed_fwd(packed_cpu_fwd),
            .mem_packed_ret(packed_sram_ret),

            // Hardware interface
            .ram_data_z    (ram_data_z),
            .ram_address   (ram_address),
            .ram_nce       (ram_nce),
            .ram_noe       (ram_noe),
            .ram_nwe       (ram_nwe)
        );
    `endif

endmodule
