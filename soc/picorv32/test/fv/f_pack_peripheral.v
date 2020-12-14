// formal verification rules for a picorv bus peripheral
// instantiate this inside the peripheral and connect it to the bus
//
// we look at the bus from the point of view of the CPU
// assume for peripheral inputs (mem_addr, mem_wstrb, mem_valid)
// assert for peripheral outputs (mem_ready, mem_rdata)

module f_pack_peripheral #(
    parameter [7:0] BASE_ADDR=8'h00,
    parameter [7:0] BASE2_ADDR=8'h00,
    parameter [31:0] F_MAX_STALL_CYCLES=32'h3
) (
    input clk,
    input rst,
    // PicoRV32 packed MEM Bus interface
    input [68:0] mem_packed_fwd,  // CPU > SFR
    input [32:0] mem_packed_ret,  // DEC < SFR

    output f_past_valid
);

// --------------------------------------------------------------
//  Unpack the MEM bus (proxy for mpack.v)
// --------------------------------------------------------------
wire [31:0] mem_wdata = mem_packed_fwd[68:37];
wire [3:0] mem_wstrb = mem_packed_fwd[36:33];
wire [31:0] mem_addr = mem_packed_fwd[32:1];
wire mem_valid = mem_packed_fwd[0];
wire [31:0] mem_rdata = mem_packed_ret[31:0];
wire mem_ready = mem_packed_ret[32];

reg f_past_valid = 0;

wire [67:0] f_write_req = {mem_addr, mem_wstrb, mem_wdata};
// wire [67:0] f_read_req = {mem_addr, mem_wstrb, mem_wdata};

initial assume(!mem_valid);
initial assert(!mem_ready);
initial assert(mem_rdata == 0);

reg [31:0] f_stall_count = 0;
wire f_is_addr = mem_addr[31:14] == {BASE_ADDR, BASE2_ADDR, 2'b00};

always @(*)
    assume(rst == !f_past_valid);

always @(posedge clk) begin
    f_past_valid <= 1;

    if (rst)
        assume(!mem_valid);

    // cannot have ready without valid
    if (!mem_valid) begin
        assert(!mem_ready);
        assert(mem_rdata == 32'h0);
    end

    // Max. number of stall cycles
    assert(f_stall_count <= F_MAX_STALL_CYCLES);

    // if the peer does not assert mem_ready, the valid signal stays high
    if (f_past_valid && $past(mem_valid) && !$past(mem_ready))
        assume(mem_valid);

    // if the peer does assert mem_ready, the valid signal goes low
    if (f_past_valid && $past(mem_ready))
        assume(!mem_valid);

    // when mem_valid is high, mem_addr, mem_wstrb and mem_wdata will not change
    if (f_past_valid && $past(mem_valid)) begin
        assume($stable(f_write_req));
        // test only valid addresses (dangerous?)
        // assume(f_is_addr);
    end

    // count number of stall cycles
    // the bus is expected to stall when not addressed
    if (!rst && mem_valid && !mem_ready && f_is_addr)
        f_stall_count <= f_stall_count + 1;
    else
        f_stall_count <= 0;
end

endmodule
