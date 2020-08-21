// Maps QSPI memory into the picorv address space.
// Maximum 24 bit = 16 Mbyte
// Config reg. at address 0x__FFFFFC
// almost works at 75 MHz on CMODA7 (fails if it gets hot)
// stable at 68.2 MHz

module spimemio_pack #(
	parameter BASE_ADDR=8'h00
) (
	input clk, resetn,

	output        flash_csb,
	output        flash_clk,

	// Tristate Data IO pins
	inout  [ 3:0] flash_dz,

	// PicoRV32 packed MEM Bus interface
	input  [68:0] mem_packed_fwd,  //DEC > GPO
	output [32:0] mem_packed_ret   //DEC < GPO
);

localparam SPIMEM_CFG_REG  =  24'hFFFFFC;

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire        mem_ready_mem;
reg  [31:0] mem_rdata = 0;
wire [31:0] mem_rdata_cfg;
wire [31:0] mem_rdata_mem;

reg mem_ready = 0;
reg mem_ready_ = 0;
wire ready_sum = mem_ready || mem_ready_;

munpack mu (
	.clk           (clk),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret ),
    .mem_wdata ( mem_wdata    ),
    .mem_wstrb ( mem_wstrb    ),
    .mem_valid ( mem_valid    ),
    .mem_addr  ( mem_addr     ),
    .mem_ready ( mem_ready    ),
    .mem_rdata ( mem_rdata    )
);
// split apart the address word
wire  [7 :0] mem_base_addr  = mem_addr[31:24]; // Which peripheral   (BASE_ADDR)
wire  [23:0] mem_flash_addr = mem_addr[23:0];  // Which address on the flash chip
// Decode address bus and see when SPI memory or the config words get addressed
wire         isFlashSelect   = mem_valid && !ready_sum && mem_base_addr==BASE_ADDR;
wire         isAddrCfg       = mem_flash_addr == SPIMEM_CFG_REG;
wire  [ 3:0] flash_di;
wire  [ 3:0] flash_do;
wire  [ 3:0] flash_doe;

spimemio mio (
	.clk            (clk         ),
	.resetn         (resetn      ),
	.flash_csb      (flash_csb   ),
	.flash_clk      (flash_clk   ),
	.flash_io0_oe   (flash_doe[0]),
	.flash_io1_oe   (flash_doe[1]),
	.flash_io2_oe   (flash_doe[2]),
	.flash_io3_oe   (flash_doe[3]),
	.flash_io0_do   (flash_do[0] ),
	.flash_io1_do   (flash_do[1] ),
	.flash_io2_do   (flash_do[2] ),
	.flash_io3_do   (flash_do[3] ),
	.flash_io0_di   (flash_di[0] ),
	.flash_io1_di   (flash_di[1] ),
	.flash_io2_di   (flash_di[2] ),
	.flash_io3_di   (flash_di[3] ),

	.valid          ( isFlashSelect && !isAddrCfg ),
	.ready          ( mem_ready_mem ),
	.addr           ( mem_flash_addr ),
	.rdata          ( mem_rdata_mem ),

	.cfgreg_we      ( (isFlashSelect&&isAddrCfg) ? mem_wstrb : 4'h0 ),
	.cfgreg_di      ( mem_wdata ),
	.cfgreg_do      ( mem_rdata_cfg )
);

// Wire it up to the flash_dz pins
generate
    genvar i;
    for (i=0; i<=3; i=i+1) begin
        assign flash_dz[i] = flash_doe[i] ? flash_do[i] : 1'bz;
    end
endgenerate
assign flash_di = flash_dz;

always @(posedge clk) begin
	mem_ready <= 0;
	mem_rdata <= 0;

	if (isFlashSelect) begin
		if (isAddrCfg) begin
			mem_rdata <= mem_rdata_cfg;
			mem_ready <= 1;
		end else begin
			if (mem_ready_mem) begin
				mem_rdata <= mem_rdata_mem;
				mem_ready <= 1;
			end
		end
	end

	mem_ready_ <= mem_ready;
end

endmodule
