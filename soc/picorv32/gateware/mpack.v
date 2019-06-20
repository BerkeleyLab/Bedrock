// --------------------------------------------------------------
//  mem_pack.v
//  Concatenate the whole MEM bus over 2 wires. To simplify
//  port definitions
// --------------------------------------------------------------

module mpack (
    // Unpacked wires
    input  [31:0] mem_wdata,    //CPU > MEM
    input  [ 3:0] mem_wstrb,    //CPU > MEM
    input  [31:0] mem_addr,     //CPU > MEM
    input         mem_valid,    //CPU > MEM
    output        mem_ready,    //CPU < MEM (TS)
    output [31:0] mem_rdata,    //CPU < MEM (TS)
    // Packed wires
    output [68:0] mem_packed_fwd,
    input  [32:0] mem_packed_ret
);
assign mem_packed_fwd = { mem_wdata, mem_wstrb, mem_addr, mem_valid };
assign mem_ready      =  mem_packed_ret[  32];
assign mem_rdata      =  mem_packed_ret[31:0];
endmodule
