// Bridge between general SPI interface to 4DSP FMC11X CPLD interface
// which sets DIO direction on 9th bit
// CPOL=1, CPHA=1

module cpld_bridge #(
    parameter BIT_RW = 9  // read/write control bit
) (
    input clk,     // mem_clk
    input [5:0] cfg_nbits,
    input ss,
    input sck,
    input mosi,
    output miso,
    inout  dio
);

// last byte dir control
reg oe = 1'b1;

reg [5:0] cnt=0;
reg sck1=0;

wire sck_f_edge = sck1 & ~sck;
wire sck_r_edge = ~sck1 & sck;

always @(posedge clk) if (ss) begin
    cnt <= 6'h0;
    oe <= 1'b1;
end else begin
    sck1 <= sck;
    cnt <= cnt + sck_f_edge;
    if (sck_r_edge && cnt==BIT_RW) oe <= !mosi;
end

wire [5:0] bit_dat = cfg_nbits - 7;
// take care of last cycle
wire oe1 = (cnt==bit_dat-1) && sck_f_edge;
wire oe_out = (cnt < bit_dat && ~oe1) || oe;

assign dio = oe_out ? mosi : 1'bz;
assign miso = dio;
// assign miso = oe_out ? 1'bz : dio;

endmodule
