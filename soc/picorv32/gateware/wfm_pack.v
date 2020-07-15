module wfm_pack #(
    parameter N_CH  = 8,
    parameter AW    = 5,
    parameter [7:0] BASE_ADDR  =8'h00,
    parameter [7:0] BASE2_ADDR =8'h00
) (
    input               dsp_clk,
    input [16*N_CH-1:0] adc_out_data,

    // PicoRV32 packed MEM Bus interface
    input               clk,
    input               rst,
    input  [68:0]       mem_packed_fwd,  //CPU > SFR
    output [32:0]       mem_packed_ret   //DEC < SFR
);

/// #define WFM_CFG_ADDR          0x1000
/// #define WFM_CFG_BYTE_WFM_LEN  0
/// #define WFM_CFG_BYTE_CHAN_SEL 2
/// #define WFM_CFG_BYTE_TRIG     3
reg [31:0] config_reg=32'h0010;
localparam [15:0] CONFIG_ADDR = 16'h1000;
wire [15:0] wfm_len= config_reg[ 0+:16];
wire [ 3:0] ch     = config_reg[16+:4];
wire        trig0  = config_reg[24];
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
reg  [31:0] mem_rdata=0;
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

wire mem_addr_hit = mem_valid && mem_addr[31:16]=={BASE_ADDR,BASE2_ADDR};
wire cfg_addr_hit = mem_addr_hit && mem_addr[15:0]==CONFIG_ADDR;
// only react on 32 bit writes
wire mem_read  = !(|mem_wstrb) && mem_addr_hit;

reg ready1=0;
wire [15:0] dpram_dout;
always @(posedge clk) begin
    mem_ready <= 0;
    ready1 <= 0;
    mem_rdata <= 0;
    if (rst)
        config_reg <= 32'h10;
    else begin
        if ( !mem_ready && mem_addr_hit ) begin
            if (cfg_addr_hit) begin
                if (mem_wstrb[0]) config_reg[ 0+:8] <= mem_wdata[ 0+:8];
                if (mem_wstrb[1]) config_reg[ 8+:8] <= mem_wdata[ 8+:8];
                if (mem_wstrb[2]) config_reg[16+:8] <= mem_wdata[16+:8];
                if (mem_wstrb[3]) config_reg[24+:8] <= mem_wdata[24+:8];
                mem_rdata <= config_reg;
            end else begin
                mem_rdata <= dpram_dout;
            end
            ready1 <= 1'b1;
            mem_ready <= ready1;
        end
    end
end
// assign mem_rdata = cfg_addr_hit ? config_reg : {16'h0, dpram_dout};

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
