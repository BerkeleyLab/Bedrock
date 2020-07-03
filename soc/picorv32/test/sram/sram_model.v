module sram_model (
    input we_n,
    input ce_n,
    input oe_n,
    input [18:0] addr,
    inout [7:0] data
);

specify
    specparam
    Twp = 8,
    Tdw = 6,
    Tdh = 0;
    $width (negedge we_n, Twp);
    $setup (data, posedge we_n, Tdw);
    $hold (posedge we_n, data, Tdh);
endspecify

reg [7:0] sram[1023:0];

integer i;
initial
    for(i=0; i<=1023; i=i+1)
        sram[i] = i;

always@(posedge we_n)
    if (ce_n == 1'b0)
        sram[addr] <= data;

assign #10 data = (we_n & ~ce_n & ~oe_n) ? sram[addr] : 8'hzz;

endmodule
