// --------------------------------------------------------------
//  External async SRAM interface with look ahead
// --------------------------------------------------------------
// designed for IS61WV5128BLL-10BLI (on CMOD A7)
//
// * 32 bit read: 5 cycles, write: 4 cycles
// * Work fine up to 83.3 MHz, fails at 93.75 MHz

module sram2_pack #(
    parameter BASE_ADDR=8'h00
) (
    input             clk,

    // SRAM hardware interface
                       inout [7:0]       ram_data_z,
    (* IOB = "TRUE" *) output reg [23:0] ram_address,
    (* IOB = "TRUE" *) output reg        ram_nwe,
                       output            ram_nce,
                       output            ram_noe,

    // PicoRV32 look-ahead mem interface
    input             mem_la_read,
    input             mem_la_write,
    input [31:0]      mem_la_addr,
    input [31:0]      mem_la_wdata,
    input [ 3:0]      mem_la_wstrb,

    // PicoRV32 packed MEM Bus interface
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
reg  [23:0] mem_rdata;
reg         mem_ready;
munpack mu (
    .mem_packed_fwd(69'h0),
    .mem_packed_ret(mem_packed_ret),

    .mem_wdata (),
    .mem_wstrb (),
    .mem_valid (),
    .mem_addr  (),
    .mem_ready (mem_ready),
    // Hack to safe a cycle while keeping r_reg in IOB
    .mem_rdata ({(mem_ready ? r_reg : 8'h0), mem_rdata})
);

reg [2:0] cycle = 3'h0;

// isSelected is high during the entire access cycle (4 or 5 clocks)
wire isSelected = (mem_la_addr[31:24] == BASE_ADDR) &&
                  (mem_la_read | mem_la_write | cycle > 0) &&
                  !mem_ready;

// mem_la_write is a pulse,
// isWrite is valid as long as isSelected is high
reg mem_la_write_ = 1'b0;
wire isWrite = mem_la_write_ | mem_la_write;

always @(posedge clk) begin
    mem_ready <= 1'b0;
    ram_nwe <= 1'b1;

    if (isSelected) begin
        // write enable line for this byte
        if (isWrite && mem_la_wstrb[cycle])
            ram_nwe <= 1'b0;

        // always read when selected, picorv ignores it if it's writing
        r_reg <= ram_data_z;
        mem_rdata[8 * (cycle - 2) +: 8] <= r_reg;

        // latch mem_la_write
        if (mem_la_write)
            mem_la_write_ <= 1'b1;

        // signal end of access cycle
        // read is one clock longer than write. There must be a better way!
        if (cycle >= (isWrite ? 3'h3 : 3'h4))
            mem_ready <= 1'b1;

        cycle <= cycle + 1;
    end else begin
        mem_rdata <= 24'h0;
        cycle <= 3'h0;
        mem_la_write_ <= 1'b0;
    end

    w_reg <= mem_la_wdata[8 * cycle +: 8];
    ram_address <= mem_la_addr[23:0] + cycle;
end

endmodule
