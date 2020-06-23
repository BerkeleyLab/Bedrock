// --------------------------------------------------------------
//  External async SRAM interface
// --------------------------------------------------------------
// designed for IS61WV5128BLL-10BLI (on CMOD A7)
//
// * 32 bit read: 6 cycles, write: 5 cycles
// * Work fine up to 75 MHz

module sram_pack #(
    parameter BASE_ADDR=8'h00
) (
    input             clk,
    // Hardware interface
    inout [7:0]       ram_data_z,
    output reg [23:0] ram_address,
    output            ram_nce,
    output            ram_noe,
    output reg        ram_nwe,

    // PicoRV32 packed MEM Bus interface
    input  [68:0]     mem_packed_fwd,
    output [32:0]     mem_packed_ret
);

assign ram_nce = 0;
assign ram_noe = 0;
initial ram_nwe = 1'b1;

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
reg  [31:0] mem_rdata;
reg         mem_ready;
munpack mu (
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret ),

    .mem_wdata ( mem_wdata ),
    .mem_wstrb ( mem_wstrb ),
    .mem_valid ( mem_valid ),
    .mem_addr  ( mem_addr  ),
    .mem_ready ( mem_ready ),
    .mem_rdata ( mem_rdata )
);

wire isSelected = (mem_addr[31:24] == BASE_ADDR) && mem_valid;
reg [7:0] ram_data = 8'h0;
assign ram_data_z = ram_nwe ? 8'hzz : ram_data;
reg [2:0] cycle = 3'h0;

always @(posedge clk) begin
    mem_ready <= 1'b0;
    ram_nwe <= 1'b1;

    if (isSelected && !mem_ready) begin
        if (mem_wstrb[cycle])
            ram_nwe <= 1'b0;

        mem_rdata[8 * (cycle - 1) +: 8] <= ram_data_z;
        cycle <= cycle + 1;

        // Read is one cycle longer than write. There must be a better way!
        if (|mem_wstrb) begin
            if (cycle == 3'h3)
                mem_ready <= 1'b1;
        end else begin
            if (cycle == 3'h4)
                mem_ready <= 1'b1;
        end
    end else begin
        mem_rdata <= 32'h0;
        cycle <= 3'h0;
    end

    ram_data <= mem_wdata[8 * cycle +: 8];
    ram_address <= mem_addr[23:0] + cycle;
end

endmodule
