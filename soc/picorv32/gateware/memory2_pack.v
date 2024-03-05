// --------------------------------------------------------------
//  memory2_pack.v
// --------------------------------------------------------------
// This memory can look into the future with the picorv look-ahead interface
// hence ready goes high at the same time as valid
// BLOCK_RAM_SIZE must be specified as macro on cmdline

module memory2_pack #(
    parameter MEM_INIT = "",
    parameter BASE_ADDR=8'h00
)(
    output [32:0] mem_packed_ret,  //DEC < MEM
    // Look ahead mem interface
    input        clk,
    input        reset,
    input        mem_la_read,
    input        mem_la_write,
    input [31:0] mem_la_addr,
    input [31:0] mem_la_wdata,
    input [ 3:0] mem_la_wstrb
);

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
reg  [31:0] mem_rdata=0;
reg         mem_ready=0;
munpack mu (
    .clk           (clk),
    .mem_packed_fwd(69'd0),
    .mem_packed_ret(mem_packed_ret),
    .mem_wdata (),
    .mem_wstrb (),
    .mem_valid (),
    .mem_addr  (),
    .mem_ready (mem_ready),
    .mem_rdata (mem_rdata)
);
wire [ 7:0] mem_addr_base = mem_la_addr[31:24]; // Which peripheral   (BASE_ADDR)
wire [21:0] mem_addr_reg  = mem_la_addr[23:2];  // Which word

// --------------------------------------------------------------
//  Init the memory and its interface wires
// --------------------------------------------------------------
// Makefile passes -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE) [bytes]
// _BLOCK_RAM_SIZE [32 bit words]
localparam _BLOCK_RAM_SIZE = `BLOCK_RAM_SIZE/4;
integer i;
reg [31:0] memory[0:_BLOCK_RAM_SIZE-1];
initial begin
    for (i=0; i<_BLOCK_RAM_SIZE; i=i+1) memory[i] = 32'h00000000;
    if (MEM_INIT != "") begin
        $readmemh(MEM_INIT, memory);
        $write("memory2_pack: 0x%x words, %s\n", _BLOCK_RAM_SIZE, MEM_INIT);
    end else begin
        $write("memory2_pack: no init file given\n");
    end
    $fflush();
end

// --------------------------------------------------------------
//  Logic for MEM (read and write) access
// --------------------------------------------------------------
always @(posedge clk) begin
    // Initialize status lines operating with single clock wide pulses
    mem_ready <=  1'b0;
    mem_rdata <= 32'h00000000;
    if (mem_addr_base == BASE_ADDR) begin
        if (mem_la_write) begin
            mem_ready <= 1;
            if (mem_la_wstrb[0]) memory[mem_addr_reg][ 7: 0] <= mem_la_wdata[ 7: 0];
            if (mem_la_wstrb[1]) memory[mem_addr_reg][15: 8] <= mem_la_wdata[15: 8];
            if (mem_la_wstrb[2]) memory[mem_addr_reg][23:16] <= mem_la_wdata[23:16];
            if (mem_la_wstrb[3]) memory[mem_addr_reg][31:24] <= mem_la_wdata[31:24];
        end
        if (mem_la_read) begin
            mem_ready <= 1;
            mem_rdata <= memory[mem_addr_reg];
        end
    end
end
endmodule
