module debug_console #(
    parameter BASE_ADDR=8'h00
)(
    input clk,
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
wire [23:0] mem_addr_local  = mem_addr[23:0];      // [bytes] Clip off the uppermost byte, which is the base address
wire [21:0] word_addr_local = mem_addr_local[23:2];// [words] Addressing 4 byte words
reg  [31:0] mem_rdata=0;

reg mem_ready = 0;
reg mem_ready_ = 0;
wire ready_sum = mem_ready || mem_ready_;

munpack mu (
    .clk           (clk),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret ),

    .mem_wdata ( mem_wdata  ),
    .mem_wstrb ( mem_wstrb  ),
    .mem_valid ( mem_valid  ),
    .mem_addr  ( mem_addr   ),
    .mem_ready ( mem_ready  ),
    .mem_rdata ( mem_rdata  )
);

wire mine = mem_addr[31:24]==BASE_ADDR;
always @(posedge clk) begin
    mem_ready <= 0;
    mem_rdata <= 0;
    if (mem_valid && !ready_sum && mine) begin
        mem_ready <= 1;  // no stalling
        if (mem_wstrb[0]) begin
            // Sure was a lot of work to get to the one line that
            // actually does something.
            $write("%c", mem_wdata[7:0]);
        end
    end
    mem_ready_ <= mem_ready;
end
endmodule
