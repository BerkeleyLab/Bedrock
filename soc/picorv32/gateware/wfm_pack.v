module wfm_pack #(
    parameter N_CH  = 8,
    parameter AW    = 5,
    parameter  [7:0]  BASE_ADDR=8'h00,
    parameter  [7:0]  BASE2_ADDR=8'h20
) (
    input               dsp_clk,
    input [16*N_CH-1:0] adc_out_data,

    // PicoRV32 packed MEM Bus interface
    input               clk,
    input               rst,
    input  [68:0]       mem_packed_fwd,  //CPU > SFR
    output [32:0]       mem_packed_ret   //DEC < SFR
);

/// #define WFM_BASE2_ADDR 0x200000
/// #define WFM_BASE2_SFR  0x100000
localparam [7:0] BASE2_SFR  = 8'h10;

wire [32:0] mem_packed_sfr_ret;
wire [32:0] mem_packed_wfm_ret;
assign mem_packed_ret = mem_packed_sfr_ret | mem_packed_wfm_ret;

wire [31:0] sfRegsOut, sfRegsInp, sfRegsWrt;
sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR      ),
    .BASE2_ADDR     ( BASE2_SFR      ),
    .N_REGS         ( 1              )
) sfrInst (
    .clk            ( clk            ),
    .rst            ( rst            ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_sfr_ret ),
    .sfRegsOut      ( sfRegsOut      ),
    .sfRegsIn       ( sfRegsInp      ),
    .sfRegsWrStr    ( sfRegsWrt      )
);

/// #define SFR_BYTE_WFM_LEN  1
/// #define SFR_BYTE_CHAN_SEL 0
/// #define SFR_WST_BIT_TRIG  7
wire [ 3:0] ch     = sfRegsOut[3:0];
wire [15:0] wfm_len= sfRegsOut[8+:16];
wire        trig0  = sfRegsOut[7];
reg trig1=0;
always @(posedge clk) trig1 <= trig0;
wire trig = trig0 & ~trig1;

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire [31:0] mem_rdata;
reg         mem_ready;
munpack mu (
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_wfm_ret ),
    .mem_wdata ( mem_wdata    ),
    .mem_wstrb ( mem_wstrb    ),
    .mem_valid ( mem_valid    ),
    .mem_addr  ( mem_addr     ),
    .mem_ready ( mem_ready    ),
    .mem_rdata ( mem_rdata    )
);

wire mem_addr_hit = mem_valid && mem_addr[31:16]=={BASE_ADDR,BASE2_ADDR};
// only react on 32 bit writes
wire mem_write = (&mem_wstrb) && mem_addr_hit;
wire mem_read  = !(|mem_wstrb) && mem_addr_hit;

wire [15:0] dpram_dout;
assign mem_rdata = dpram_dout;
always @(posedge clk) begin
    mem_ready <= 0;
    if ( mem_valid && !mem_ready && mem_read) begin
        mem_ready <= 1'b1;
    end
end

wire adc_trigger;
flag_xdomain flag_trig (
    .clk1           (clk),
    .flagin_clk1    (trig),
    .clk2           (dsp_clk),
    .flagout_clk2   (adc_trigger)
);

// generate read pc from dsp_clk domain
reg [AW-1:0] adc_wfm_len=0;
reg counting=0;
reg [AW-1:0] pc=0;
always @(posedge dsp_clk) begin
    adc_wfm_len <= wfm_len;
    if (pc==adc_wfm_len-1) counting <= 0;
    else if (adc_trigger) counting <= 1'b1;
    pc <= counting ? pc + 1'b1: 0;
end

wire [AW-1:0] addr_word = mem_addr[2+:AW];
wire [15:0] adc_din = adc_out_data[16*ch+:16];
dpram #( .aw(AW), .dw(16)) ram (
    .clka       (dsp_clk    ),
    .addra      (pc         ),
    .dina       (adc_din    ),
    .wena       (counting   ),
    .clkb       (clk        ),
    .addrb      (addr_word  ),
    .doutb      (dpram_dout )
);

endmodule
