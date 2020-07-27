// --------------------------------------------------------------
//  Special function register module
// --------------------------------------------------------------
// provides N_REGS (up to 32) 32 bit registers
// with a pico-pack memory bus interface
//
// Can be addressed word-wise, byte-wise or bit-wise.
// The idea is to utilize this module within the other peripherals which
// require a user configurable register file.
//
// --------------------------------------------------------------
//  Addressing the SFR
// --------------------------------------------------------------
// this shows the meaning of each bit in mem_addr.
//
// _ = BASE_ADDR
// - = BASE2_ADDR
// r = 5 bit register index (0 ... N_REGS-1)
// b = bit index (0 ... 31)
// x = don't care
//
// Word-wise / byte-wise addressing (mem_wdata is used)
// ____ ____ ---- ---- 00xx xxx0 0rrr rrxx
//
// bit-wise addressing, bit is set on write (mem_wdata is ignored)
// ____ ____ ---- ---- 00rr rrr0 1bbb bbxx
//
// bit-wise addressing bit is cleared on write (mem_wdata is ignored)
// ____ ____ ---- ---- 00rr rrr1 0bbb bbxx
//
// both bit-wise addresses will read 31'd1 if bit is set and 31'd0 if bit is clear
//
// Note that the SW instruction has a 12 bit signed immediate. So only the
// lowest 4 registers can be bit-addressed in a single instruction (without LUI)

module sfr_pack #(
    parameter  [7:0]            BASE_ADDR=8'h00,
    parameter  [7:0]            BASE2_ADDR=8'h00,// allows multiple SFR modules on same BASE_ADDR
    parameter                   N_REGS=1,        // [32 bit words]
    parameter  [N_REGS*32-1:0]  INITIAL_STATE = 0
) (
    input                       clk,
    input                       rst,             // Zero initializes regs
    output reg [N_REGS*32-1:0]  sfRegsOut,       // State of internally stored bit
    output reg [N_REGS*32-1:0]  sfRegsWrStr,     // Pulses on picorv memory write
    input      [N_REGS*32-1:0]  sfRegsIn,        // Sampled on picorv memory read

    // PicoRV32 packed MEM Bus interface
    input  [68:0]               mem_packed_fwd,  //CPU > SFR
    output [32:0]               mem_packed_ret   //DEC < SFR
);

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

    .mem_wdata ( mem_wdata    ),
    .mem_wstrb ( mem_wstrb    ),
    .mem_valid ( mem_valid    ),
    .mem_addr  ( mem_addr     ),
    .mem_ready ( mem_ready    ),
    .mem_rdata ( mem_rdata    )
);

// --------------------------------------------------------------
//  Unwrap the mem_addr word
// --------------------------------------------------------------
wire  [17:0] addr_base  = mem_addr[14+:18];    // Which peripheral   (BASE_ADDR)
wire  [ 1:0] addr_mode  = mem_addr[ 7+: 2];    // Which addressing mode
wire  [ 4:0] addr_bit   = mem_addr[ 2+: 5];    // Which bit
wire  [ 4:0] addr_reg_w = mem_addr[ 2+: 5];    // Which register for mode 0
wire  [ 4:0] addr_reg_b = mem_addr[ 9+: 5];    // Which register for mode 1, 2

// --------------------------------------------------------------
//  Read / write the special function register file
// --------------------------------------------------------------
always @(posedge clk) begin
    mem_ready <= 0;
    mem_rdata <= 0;
    // Make all Write strobes pulsed signals
    sfRegsWrStr <= {N_REGS{32'h0}};
    if( rst ) begin         // Copy INITIAL_STATE to registers on reset
        sfRegsOut <= INITIAL_STATE;
    end else if ( mem_valid && !mem_ready && addr_base=={BASE_ADDR,BASE2_ADDR,2'b00} ) begin
        mem_ready <= 1;     // For now, never stall CPU when addressed
        case (addr_mode)
            2'd0: begin     // Word addressing mode
                if (mem_wstrb[0]) begin
                    sfRegsOut[  (addr_reg_w*32+0 )+:8] <= mem_wdata[ 0+:8];
                    sfRegsWrStr[(addr_reg_w*32+0 )+:8] <= 8'hFF;
                end
                if (mem_wstrb[1]) begin
                    sfRegsOut[  (addr_reg_w*32+8 )+:8] <= mem_wdata[ 8+:8];
                    sfRegsWrStr[(addr_reg_w*32+8 )+:8] <= 8'hFF;
                end
                if (mem_wstrb[2]) begin
                    sfRegsOut[  (addr_reg_w*32+16)+:8] <= mem_wdata[16+:8];
                    sfRegsWrStr[(addr_reg_w*32+16)+:8] <= 8'hFF;
                end
                if (mem_wstrb[3]) begin
                    sfRegsOut[  (addr_reg_w*32+24)+:8] <= mem_wdata[24+:8];
                    sfRegsWrStr[(addr_reg_w*32+24)+:8] <= 8'hFF;
                end
                mem_rdata <= sfRegsIn[ addr_reg_w*32 +: 32 ];
            end
            2'd1, 2'd2: begin     // Bit addressing mode (Set & Clear)
                if (|mem_wstrb) begin
                    sfRegsOut[  addr_reg_b*32+addr_bit] <= addr_mode[0];
                    sfRegsWrStr[addr_reg_b*32+addr_bit] <= 1'b1;
                end
                mem_rdata <= { 31'd0, sfRegsIn[addr_reg_b*32+addr_bit] };
            end
            default: begin        // Unimplemented addressing mode
                mem_rdata <= 0;   // Read 0, Ignore writes
            end
        endcase
    end
end

endmodule
