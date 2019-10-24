// --------------------------------------------------------------
//  mem_unpack.v
//  Restore the whole MEM bus from the 2 packed wires.
//  To simplify port definitions.
// --------------------------------------------------------------

module munpack (
    // Packed wires
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret,
    // Unpacked wires
    output [31:0] mem_wdata,    //CPU > MEM
    output [ 3:0] mem_wstrb,    //CPU > MEM
    output        mem_valid,    //CPU > MEM
    output [31:0] mem_addr,     //CPU > MEM
    input         mem_ready,    //CPU < MEM (TS)
    input  [31:0] mem_rdata     //CPU < MEM (TS)
);
assign mem_wdata      = mem_packed_fwd[68:37];
assign mem_wstrb      = mem_packed_fwd[36:33];
assign mem_addr       = mem_packed_fwd[32: 1];
assign mem_valid      = mem_packed_fwd[    0];
// only response when asked.
wire [31:0] rdata = mem_ready ? mem_rdata : 0;
assign mem_packed_ret = { mem_ready, rdata };
//assign mem_packed_ret = { mem_ready, mem_rdata };

endmodule
