module spi_pack #(
    parameter BASE_ADDR=8'h00,
    parameter BASE2_ADDR=8'h00    // Takes 1 BASE2 slot at BASE2_ADDR
) (
    input           clk,
    input           rst,
    // Hardware interface
    output          spi_cs,     // active low chip select
    output          spi_sck,  // serial clock
    output          spi_copi,  // controller out / peripheral in
    input           spi_cipo,  // controller in / peripheral out
	output [31:0]   spi_cfg_reg,
    // PicoRV32 packed MEM Bus interface
    input  [68:0]   mem_packed_fwd,  //CPU > SPI
    output [32:0]   mem_packed_ret   //CPU < SPI
);

// ------------------------------------------------------------------------
//  SPI Registers
// ------------------------------------------------------------------------
// SPI data register (spi_tx_reg) is at BASE_ADDR
// Writing to the LSB of BASE_ADDR will start the SPI transmission
// Reading BASE_ADDR will return the last complete reception.
// spi_pack will never stall the CPU. So block on the BUSY bit in firmware.
// The configuration register is at BASE_ADDR + 4. It contains:
localparam BIT_CLK_DIV  =  0; // 8 bit clock prescaler (halfperiod cycle count)
localparam BIT_NBITS    =  8; // Send / Receive N bits per transfer (1-32)
localparam BIT_CPOL     = 16; // Clock polarity: 0 = idle low, 1 = idle high
localparam BIT_CPHA     = 17; // Clock phase: 0 = sample on 1st edge, 1 = 2nd
localparam BIT_LSB      = 18; // When set, transmit LSB first, otherwise MSB
localparam BIT_SS_MAN   = 25; // 0 = Automatic, 1 = Manual control of SS pin
localparam BIT_SS_CTRL  = 26; // Set state of SS pin (when BIT_SS_MAN == 1)
localparam BIT_BUSY     = 30; // BIT_BUSY == 1 while spi_engine is busy
localparam BIT_MISO     = 31; // Status of MISO pin

wire [2*32-1:0] sfRegsOut;
wire [2*32-1:0] sfRegsWrStr;
wire [2*32-1:0] sfRegsIn;
wire [31:0] spi_rdata;
wire        spi_busy;
wire        spi_cs_auto;
sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR ),
    .BASE2_ADDR     ( BASE2_ADDR ),
    .N_REGS         ( 2 )
) sfrInst (
    .clk            ( clk ),
    .rst            ( rst ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_ret ),
    .sfRegsOut      ( sfRegsOut ),
    .sfRegsWrStr    ( sfRegsWrStr ),
    .sfRegsIn       ( sfRegsIn )
);

// Connect spi_tx_reg to "write on BASE_ADDR"
wire [31:0] spi_tx_reg  = sfRegsOut[0*32+:32];

// Connect spi_rdata to "read on BASE_ADDR"
assign sfRegsIn[0*32+:32] = spi_rdata;

// Connect spi_cfg_reg to "write on BASE_ADDR+4"
assign spi_cfg_reg = sfRegsOut[1*32+:32];

// Connect config word to "read on BASE_ADDR+4"
assign sfRegsIn[1*32+:32] = { spi_cipo, spi_busy, spi_cfg_reg[29:0] };
wire [ 7:0] cfg_clk_div = spi_cfg_reg[BIT_CLK_DIV+:8]; // Clock divider word
wire [ 5:0] cfg_nbits   = spi_cfg_reg[BIT_NBITS  +:6]; // N bits per transf. (1-32)

// Auto / manual control of SS pin
assign spi_cs = spi_cfg_reg[BIT_SS_MAN] ? spi_cfg_reg[BIT_SS_CTRL] : spi_cs_auto;

// ------------------------------------------------------------------------
//  Instantiate the SPI engine
// ------------------------------------------------------------------------
spi_engine spi_inst (
    .clk                 (clk),
    .reset               (rst),
    // If lowest bit of `spi_tx_reg` is written, start SPI transmission
    .wdata_val           ( sfRegsWrStr[0] ),
    .wdata               (spi_tx_reg),
    .rdata               (spi_rdata),
    .rdata_val           (),
    .busy                (spi_busy),
    .cfg_sckhalfperiod   (cfg_clk_div),
    .cfg_cpol            (spi_cfg_reg[BIT_CPOL]),
    .cfg_cpha            (spi_cfg_reg[BIT_CPHA]),
    .cfg_lsb             (spi_cfg_reg[BIT_LSB]),
    .cfg_scklen          ({2'h0, cfg_nbits}),
    .cs                  (spi_cs_auto),
    .sck                 (spi_sck),
    .copi                (spi_copi),
    .cipo                (spi_cipo)
);

endmodule
