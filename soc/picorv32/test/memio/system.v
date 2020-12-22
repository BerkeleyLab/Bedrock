`timescale 1 ns / 1 ps

module system #(
    parameter SYSTEM_HEX_PATH="system32.hex"
) (
    input               clk,
    input               reset,
    output              trap,

    output              flash_csb,
    output              flash_clk,
    inout  [3:0]        flash_dz
);

    localparam BASE_BRAM        = 8'h00;
    localparam BASE_MEMIO       = 8'h01;

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
    wire [32:0] packed_memio_ret;
    assign packed_cpu_ret = packed_mem_ret |
                            packed_memio_ret;

    // --------------------------------------------------------------
    //  Instantiate the memory (holds data and program!)
    // --------------------------------------------------------------
    `ifdef MEMORY_PACK_FAST
        memory2_pack #(
            .MEM_INIT      (SYSTEM_HEX_PATH),
            .BASE_ADDR     (BASE_BRAM)
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
            .BASE_ADDR     (BASE_BRAM)
        ) mem_inst (
            // Hardware interface
            .clk           (clk),

            // PicoRV32 packed MEM Bus interface
            .mem_packed_fwd(packed_cpu_fwd),
            .mem_packed_ret(packed_mem_ret)
        );
    `endif

    // --------------------------------------------------------------
    //  Memory mapped SPI flash (MEMIO)
    // --------------------------------------------------------------
    spimemio_pack #(
        .BASE_ADDR     (BASE_MEMIO)
    ) memio_inst (
        // Hardware interface
        .clk           (clk),
        .resetn        (!reset),

        // PicoRV32 packed MEM Bus interface
        .mem_packed_fwd(packed_cpu_fwd),
        .mem_packed_ret(packed_memio_ret),

        // SPI FLASH interface
        .flash_csb     (flash_csb),
        .flash_clk     (flash_clk),
        .flash_dz      (flash_dz)
    );

endmodule
