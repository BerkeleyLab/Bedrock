// --------------------------------------------------------------
//  memory_pack.v
// --------------------------------------------------------------
// Everything from Address 0 to _MEM_SIZE-1 goes to the memory.
// MEM_SIZE must be specified as macro on cmdline

module memory_pack #(
    parameter MEM_INIT = "",
    parameter BASE_ADDR=8'h00
)(
    // Hardware interface
    input  wire       clk,
    // PicoRV32 packed MEM Bus interface
    input  [68:0] mem_packed_fwd,  //DEC > MEM
    output [32:0] mem_packed_ret   //DEC < MEM
);

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire [21:0] word_addr = mem_addr[23:2];// [words] Addressing 4 byte words
reg  [31:0] mem_rdata=0;
reg         mem_ready=0;
munpack mu (
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret ),

    .mem_wdata ( mem_wdata  ),
    .mem_wstrb ( mem_wstrb  ),
    .mem_valid ( mem_valid  ),
    .mem_addr  ( mem_addr   ),
    .mem_ready ( mem_ready  ),
    .mem_rdata ( mem_rdata  )
);

// --------------------------------------------------------------
//  Init the memory and its interface wires
// --------------------------------------------------------------
// Makefile passes -DMEM_SIZE=$(MEM_SIZE) [bytes]
// _MEM_SIZE [32 bit words]
localparam _MEM_SIZE = `MEM_SIZE/4;
integer i;
reg [31:0] memory[0:_MEM_SIZE-1];
initial begin
    for (i=0; i<_MEM_SIZE; i=i+1) memory[i] = 32'h00000000;
    $readmemh( MEM_INIT, memory );
    $write("--------------------------\n");
    $write(" memory_pack\n");
    $write("--------------------------\n");
    $write("Size:      0x%x words\n", _MEM_SIZE);
    $write("Init file: %s\n",         MEM_INIT);
    $fflush();
end

// --------------------------------------------------------------
//  Logic for MEM (read and write) access
// --------------------------------------------------------------
always @( posedge clk ) begin
    // Initialize status lines operating with single clock wide pulses
    mem_ready <=  1'b0;
    mem_rdata <= 32'h00000000;
    if ( mem_valid && !mem_ready && mem_addr[31:24]==BASE_ADDR ) begin
        // ------------------------
        // --- Read from memory ---
        // ------------------------
        // In a read transfer mem_wstrb has the value 0 and mem_wdata is unused.
        mem_rdata <= memory[word_addr];
        mem_ready <= 1;
        // -----------------------
        // --- Write to memory ---
        // -----------------------
        //In a write transfer mem_wstrb != 0 encodes the number of bytes to write in one go.
        if (mem_wstrb[0]) memory[word_addr][ 7: 0] <= mem_wdata[ 7: 0];
        if (mem_wstrb[1]) memory[word_addr][15: 8] <= mem_wdata[15: 8];
        if (mem_wstrb[2]) memory[word_addr][23:16] <= mem_wdata[23:16];
        if (mem_wstrb[3]) memory[word_addr][31:24] <= mem_wdata[31:24];
        mem_ready <= 1;
    end
end
endmodule
