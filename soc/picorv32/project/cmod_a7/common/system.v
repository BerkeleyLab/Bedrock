// --------------------------------------------------------------
//  system.v
// --------------------------------------------------------------
// Here we tie together the picorv32 softcore with
//  * a very simple (TM) memory interface
//  * some memory (initialized with program code from .hex file)
//  * a debugging interface printing to console when simulating with a testbench
//  * an UART module from https://github.com/alexforencich/verilog-uart with an even simpler memory interface

`timescale 1 ns / 1 ps

// --------------------------------------------------------------
//  Interface to the outside world (which is fpga pins or testbench)
// --------------------------------------------------------------
module system #(
    parameter SYSTEM_HEX_PATH="system32.hex"
) (
    input               clk,
    input               cpu_reset,

    // GPIO
    inout  [31:0]       gpio_z,

    // UART
    output              uart_tx0,
    input               uart_rx0,

    // SRAM Hardware interface
    inout  [ 7:0]       ram_data_z,
    output [23:0]       ram_address,
    output              ram_nce,
    output              ram_noe,
    output              ram_nwe,

    // quad SPI flash
    output              flash_csb,
    output              flash_clk,
    inout  [3:0]        flash_dz,

    output              trap
);

// --------------------------------------------------------------
//  Interrupt mapping
// --------------------------------------------------------------
// IRQ 0 - 15 = level triggered. IRQ 16 - 31 rising edge triggered
localparam IRQ_TIMER0 = 8'h00;
localparam IRQ_EBREAK = 8'h01;
localparam IRQ_BUSERR = 8'h02;
// Triggers when byte received. Cleared when byte read from UART_RX_REG
localparam IRQ_UART0_RX = 8'h03;

// --------------------------------------------------------------
//  Highest byte of the memory address selects peripherals
// --------------------------------------------------------------
// match settings.h
localparam BASE_BRAM =  8'h00;
localparam BASE_SRAM =  8'h01;
localparam BASE_GPIO =  8'h02;
localparam BASE_UART0 = 8'h03;
localparam BASE_MEMIO = 8'h04;

// --------------------------------------------------------------
//  Internal reset generator
// --------------------------------------------------------------
//  keep the cpu in reset for 0xFF cycles after the external reset was released
reg [7:0] cnt = 0;
wire [8:0] cnt_next = cnt+1;
always @(posedge clk) cnt <= (cpu_reset) ? 0 : cnt_next[8] ? 8'hff : cnt_next[7:0];
wire reset = ~cnt_next[8];

// --------------------------------------------------------------
//  Instantiate the packed picorv32 CPU core
// --------------------------------------------------------------
wire [31:0] irqFlags;
wire        mem_la_read;
wire        mem_la_write;
wire [31:0] mem_la_addr;
wire [31:0] mem_la_wdata;
wire [ 3:0] mem_la_wstrb;
wire [68:0] packed_cpu_fwd;
wire [32:0] packed_cpu_ret;

assign irqFlags[2:0] = 0;
assign irqFlags[31:4]= 0;

pico_pack cpu_inst (
    .clk           ( clk            ),
    .reset         ( reset          ),
    .trap          ( trap           ),
    .irqFlags      ( irqFlags       ), //Rising edge interrupts
    .mem_la_read   ( mem_la_read    ), //Look ahead mem interface
    .mem_la_write  ( mem_la_write   ),
    .mem_la_addr   ( mem_la_addr    ),
    .mem_la_wdata  ( mem_la_wdata   ),
    .mem_la_wstrb  ( mem_la_wstrb   ),
    .mem_packed_fwd( packed_cpu_fwd ), //CPU > PERIPHERAL
    .mem_packed_ret( packed_cpu_ret )  //CPU < PERIPHERAL
);

// --------------------------------------------------------------
//  32 bit Memory Bus
// --------------------------------------------------------------
wire [32:0] packed_mem_ret;
wire [32:0] packed_sram_ret;
wire [32:0] packed_gpio_ret;
wire [32:0] packed_URT0_ret;
wire [32:0] packed_memio_ret;
assign packed_cpu_ret = packed_mem_ret |
                        packed_sram_ret |
                        packed_gpio_ret |
                        packed_URT0_ret |
                        packed_memio_ret;

// --------------------------------------------------------------
//  internal block-ram memory
// --------------------------------------------------------------
`ifdef MEMORY_PACK_FAST
memory2_pack #(
    .MEM_INIT      (SYSTEM_HEX_PATH ),
    .BASE_ADDR     (BASE_BRAM        )
) mem_inst (
    // Hardware interface
    .clk           (clk             ),
    .reset         (reset           ),
    // Look ahead interface
    .mem_la_read   (mem_la_read     ),
    .mem_la_write  (mem_la_write    ),
    .mem_la_addr   (mem_la_addr     ),
    .mem_la_wdata  (mem_la_wdata    ),
    .mem_la_wstrb  (mem_la_wstrb    ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_ret(packed_mem_ret  )  //CPU < MEM
);
`else
memory_pack #(
    .MEM_INIT      ( SYSTEM_HEX_PATH ),
    .BASE_ADDR     ( BASE_BRAM )
) mem_inst (
    // Hardware interface
    .clk           ( clk            ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd( packed_cpu_fwd ), //CPU > MEM
    .mem_packed_ret( packed_mem_ret )  //CPU < MEM
);
`endif

// --------------------------------------------------------------
//  external 512 kByte SRAM module (5x slower than BRAM)
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

// --------------------------------------------------------------
//  GPIO module
// --------------------------------------------------------------
gpioz_pack #(
    .BASE_ADDR   ( BASE_GPIO )
) gpio (
    // Hardware interface
    .clk           ( clk            ),
    .reset         ( reset          ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd( packed_cpu_fwd ), //CPU > GPIO
    .mem_packed_ret( packed_gpio_ret), //CPU < GPIO
    // Hardware interface
    .gpio_z        ( gpio_z         )
);

// --------------------------------------------------------------
//  UART0, prints debugging info to onboard USB serial
// --------------------------------------------------------------
uart_fifo_pack #(
    .DATA_WIDTH  ( 8 ),
    .BASE_ADDR   ( BASE_UART0 ),
    .AW_TX       ( 8 ),
    .AW_RX       ( 8 )
) uart_inst0 (
    // Hardware interface
    .clk         ( clk        ),
    .rst         ( reset      ),
    .rxd         ( uart_rx0   ),
    .txd         ( uart_tx0   ),
    .irq_rx_valid( irqFlags[IRQ_UART0_RX] ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd( packed_cpu_fwd ), //CPU > URT
    .mem_packed_ret( packed_URT0_ret )  //CPU < URT
);

endmodule
