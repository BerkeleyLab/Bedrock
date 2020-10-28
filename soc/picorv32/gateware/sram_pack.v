// --------------------------------------------------------------
//  External async SRAM interface
// --------------------------------------------------------------
// designed for IS61WV5128BLL-10BLI (on CMOD A7)
//
// * 32 bit read: 6 cycles, write: 5 cycles
// * Works fine up to 75 MHz

module sram_pack #(
    parameter BASE_ADDR=8'h00
) (
    input             clk,

    // SRAM hardware interface
                       inout [7:0]       ram_data_z,
    (* IOB = "TRUE" *) output reg [23:0] ram_address,
    (* IOB = "TRUE" *) output reg        ram_nwe,
                       output            ram_nce,
                       output            ram_noe,

    // PicoRV32 packed MEM Bus interface
    input  [68:0]     mem_packed_fwd,
    output [32:0]     mem_packed_ret
);

assign ram_nce = 0;
assign ram_noe = 0;
initial ram_nwe = 1'b1;

(* IOB = "TRUE" *) reg [7:0] w_reg = 8'h0;
(* IOB = "TRUE" *) reg [7:0] r_reg = 8'h0;

assign ram_data_z = ram_nwe ? 8'hzz : w_reg;

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
reg  [23:0] mem_rdata;
reg         mem_ready;
munpack mu (
    .clk           (clk),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret ),

    .mem_wdata ( mem_wdata ),
    .mem_wstrb ( mem_wstrb ),
    .mem_valid ( mem_valid ),
    .mem_addr  ( mem_addr  ),
    .mem_ready ( mem_ready ),
    // Hack to safe a cycle while keeping r_reg in IOB
    .mem_rdata ({(mem_ready ? r_reg : 8'h0), mem_rdata})
);

wire isSelected = (mem_addr[31:24] == BASE_ADDR) && mem_valid;
reg [2:0] cycle = 3'h0;

always @(posedge clk) begin
    mem_ready <= 1'b0;
    ram_nwe <= 1'b1;

    if (isSelected && !mem_ready) begin
        if (mem_wstrb[cycle])
            ram_nwe <= 1'b0;

        // always read when selected, picorv ignores it if it's writing
        r_reg <= ram_data_z;
        mem_rdata[8 * (cycle - 2) +: 8] <= r_reg;


        // signal end of access cycle
        // read is one clock longer than write because of addr. latch cycle
        if (cycle >= (|mem_wstrb ? 3'h3 : 3'h4))
            mem_ready <= 1'b1;

        cycle <= cycle + 1;
    end else begin
        mem_rdata <= 24'h0;
        cycle <= 3'h0;
    end

    w_reg <= mem_wdata[8 * cycle +: 8];
    ram_address <= mem_addr[23:0] + cycle;
end

endmodule
