// --------------------------------------------------------------
//  pico_pack.v
// --------------------------------------------------------------
// PicoRV32 CPU core wrapper. To get the packed interface

module pico_pack (
    input   clk,
    input   reset,
    output  trap,
    input   [31:0] irqFlags,        //trigger interrupt inputs
    output  [68:0] mem_packed_fwd,  //CPU > DEC
    input   [32:0] mem_packed_ret,  //CPU < DEC
    // lookahead mem intfc
    output        mem_la_read,
    output        mem_la_write,
    output [31:0] mem_la_addr,
    output [31:0] mem_la_wdata,
    output [ 3:0] mem_la_wstrb
);

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire [31:0] mem_rdata;
wire        mem_ready;
mpack mu (
    .mem_wdata ( mem_wdata  ),
    .mem_wstrb ( mem_wstrb  ),
    .mem_valid ( mem_valid  ),
    .mem_addr  ( mem_addr   ),
    .mem_ready ( mem_ready  ),
    .mem_rdata ( mem_rdata  ),

    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret )
);

// --------------------------------------------------------------
//  Fire interrupt 16-31 only on rising edges
// --------------------------------------------------------------
reg  [31:0] irqFlagsPrev;
wire [31:0] irqFlagsRising;
always @( posedge clk ) begin
    irqFlagsPrev <= irqFlags;
end
assign irqFlagsRising = irqFlags & ~irqFlagsPrev;

// --------------------------------------------------------------
//  Instantiate picorv32 CPU core
// --------------------------------------------------------------
wire trace_valid;
wire [35:0] trace_data;

picorv32 #(
    .ENABLE_COUNTERS      ( 1              ),
    .ENABLE_COUNTERS64    ( 1              ),
    .ENABLE_REGS_16_31    ( 1              ),
    .ENABLE_REGS_DUALPORT ( 1              ),
    .COMPRESSED_ISA       ( 1              ),// Enable support for compressed instr. set
    .ENABLE_IRQ           ( 1              ),// Enable interrupt controller
    .ENABLE_IRQ_QREGS     ( 1              ),
    .ENABLE_IRQ_TIMER     ( 1              ),
    .LATCHED_IRQ          ( 32'h FFFF_0000 ),// 1 = Interrupts are latched until served by ISR
    .PROGADDR_RESET       ( 32'h 0000_0000 ),// Start into the bootloader at 0x00000000
    .PROGADDR_IRQ         ( 32'h 0000_0210 ),// Interrupts jump into the main program at 0x00000210
    .CATCH_MISALIGN       ( 1              ),
    .BARREL_SHIFTER       ( 1              ),
    .ENABLE_MUL           ( 1              ),
    .ENABLE_FAST_MUL      ( 0              ),
    .ENABLE_DIV           ( 1              ),
    .TWO_CYCLE_COMPARE    ( 0              ),
    .TWO_CYCLE_ALU        ( 0              ),
`ifdef SIMULATE
    .ENABLE_TRACE    ( 1 )
`else
    .ENABLE_TRACE    ( 0 )
`endif
) picorv32_core (
    .clk         ( clk          ),
    .resetn      ( ~reset       ),        // cpu expects an active low reset
    .trap        ( trap         ),
    // IRQ Interface
    .irq         ( {irqFlagsRising[31:16],irqFlags[15:0]} ),    // 16 level trigger and 16 rising edge irq inputs, matches LATCHED_IRQ
    .eoi         (),
    // PicoRV32 Address Bus interface
    .mem_valid   ( mem_valid    ),
    .mem_ready   ( mem_ready    ),
    .mem_addr    ( mem_addr     ),
    .mem_wdata   ( mem_wdata    ),
    .mem_wstrb   ( mem_wstrb    ),
    .mem_rdata   ( mem_rdata    ),
    .mem_instr   (),
    // Look-Ahead Interface
    .mem_la_read ( mem_la_read  ),
    .mem_la_write( mem_la_write ),
    .mem_la_addr ( mem_la_addr  ),
    .mem_la_wdata( mem_la_wdata ),
    .mem_la_wstrb( mem_la_wstrb ),
    // Pico Co-Processor Interface (PCPI) (not used)
    .pcpi_valid   (),
    .pcpi_insn    (),
    .pcpi_rs1     (),
    .pcpi_rs2     (),
    .pcpi_wr      (1'b0),
    .pcpi_rd      (32'b0),
    .pcpi_wait    (1'b0),
    .pcpi_ready   (1'b0),
    // Trace Interface
    .trace_valid  (trace_valid),
    .trace_data   (trace_data)
);
`ifdef SIMULATE
    integer trace_file;
    initial begin
        trace_file = $fopen("pico.trace", "w");
        repeat (10) @(posedge clk);
        while (!trap) begin
            @(posedge clk);
            if (trace_valid)
                $fwrite(trace_file, "%x\n", trace_data);
        end
        $fclose(trace_file);
    end
`endif
endmodule
