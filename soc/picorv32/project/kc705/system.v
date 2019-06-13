// --------------------------------------------------------------
//  system.v
// --------------------------------------------------------------

`timescale 1 ns / 1 ps

// --------------------------------------------------------------
//  Interface to the outside world (which is fpga pins or testbench)
// --------------------------------------------------------------
module system #(
    parameter SYSTEM_HEX_PATH="system32.hex",
    parameter LB_ADW     = 20
) (
    input           clk,
    input           cpu_reset,

    inout  [31:0]   gpio_z,

    output          uart_tx,
    input           uart_rx,

    output          trap
);

// --------------------------------------------------------------
//  Highest byte of the memory address selects peripherals, must match main.h
// --------------------------------------------------------------
localparam BASE_MEM         = 8'h00;
localparam BASE_GPIO        = 8'h01;
localparam BASE_UART0       = 8'h02;

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
wire        mem_la_read;
wire        mem_la_write;
wire [31:0] mem_la_addr;
wire [31:0] mem_la_wdata;
wire [ 3:0] mem_la_wstrb;
wire [68:0] packed_cpu_fwd;
wire [32:0] packed_cpu_ret;

pico_pack cpu_inst (
    .clk           ( clk            ),
    .reset         ( reset          ),
    .trap          ( trap           ),
    .irqFlags      ( 32'd0          ), //Rising edge interrupts
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
wire [32:0] packed_gpio_ret;
wire [32:0] packed_URT0_ret;
assign packed_cpu_ret = packed_mem_ret |
                        packed_gpio_ret|
                        packed_URT0_ret;

// --------------------------------------------------------------
//  Instantiate the memory (holds data and program!)
//  Active from mem_addr = 0 ... MEM_SIZE-1
// --------------------------------------------------------------
`ifdef MEMORY_PACK_FAST
memory2_pack #(
    .MEM_INIT      (SYSTEM_HEX_PATH ),
    .BASE_ADDR     (BASE_MEM        )
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
    .BASE_ADDR     ( BASE_MEM )
) mem_inst (
    // Hardware interface
    .clk           ( clk            ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd( packed_cpu_fwd ), //CPU > MEM
    .mem_packed_ret( packed_mem_ret )  //CPU < MEM
);
`endif

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
uart_pack #(
    .DATA_WIDTH  ( 8 ),
    .BASE_ADDR   ( BASE_UART0 )
) uart_inst0 (
    // Hardware interface
    .clk         ( clk       ),
    .rst         ( reset     ),
    .rxd         ( uart_rx   ),
    .txd         ( uart_tx   ),
    .irq_rx_valid(),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd( packed_cpu_fwd ), //CPU > URT
    .mem_packed_ret( packed_URT0_ret )  //CPU < URT
);

endmodule
