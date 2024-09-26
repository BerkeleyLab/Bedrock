module awg_pack #(
    parameter [7:0] BASE_ADDR   = 8'h00,
    parameter [7:0] BASE2_ADDR  = 8'h00,
    parameter integer DW        = 16,
    parameter integer AW        = 5,
    parameter [15:0] CONFIG_ADDR = 16'h8000
) (
    input               dsp_clk,
    output [DW-1:0]     d_out_data,
    output              d_out_valid,

    // PicoRV32 packed MEM Bus interface
    input               clk,
    input               rst,
    input  [68:0]       mem_packed_fwd,  //CPU > SFR
    output [32:0]       mem_packed_ret   //DEC < SFR
);


/// #define AWG_CFG_ADDR          0x8000
/// #define AWG_CFG_BYTE_WFM_LEN  0
/// #define AWG_CFG_BYTE_TRIG     3
reg [31:0] config_reg = (2**AW - 1);
wire [AW-1:0] wfm_len = config_reg[ 0+:AW];
wire trig0 = config_reg[24];
reg trig1=0;
always @(posedge clk) trig1 <= trig0;
wire trig = trig0 & ~trig1;


initial begin
    if (AW > 15) begin
        $display("awg_pack.v: only support AW <= 15, detected %d.", AW);
        $stop();
    end
end

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
reg  [31:0] mem_rdata=0;
reg         mem_ready;
munpack mu (
    .clk           (clk),
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
wire mem_read  = !(|mem_wstrb) && mem_addr_hit;

reg ready1=0;
wire [15:0] dpram_dout;
always @(posedge clk) begin
    mem_ready <= 0;
    ready1 <= 0;
    mem_rdata <= 0;
    if (rst)
        config_reg <= (2**AW - 1);
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

wire dsp_trigger;
flag_xdomain flag_trig (
    .clk1           (clk),
    .flagin_clk1    (trig),
    .clk2           (dsp_clk),
    .flagout_clk2   (dsp_trigger)
);

// generate pc from dsp_clk domain
reg counting=0;
reg counting1=0;
reg [AW-1:0] pc=0;
always @(posedge dsp_clk) begin
    if (pc==wfm_len-1) counting <= 0;
    else if (dsp_trigger) counting <= 1'b1;
    pc <= counting ? pc + 1'b1: 0;
    counting1 <= counting;
end

wire mem_write = mem_addr_hit && mem_addr[15:0]!=CONFIG_ADDR && (|mem_wstrb);
wire [AW-1:0] addr_word = mem_addr[2+:AW];
dpram #( .aw(AW), .dw(DW)) ram (
    .clka       (clk        ),
    .addra      (addr_word  ),
    .dina       (mem_wdata[0+:DW]),
    .douta      (dpram_dout ),
    .wena       (mem_write  ),
    .clkb       (dsp_clk    ),
    .addrb      (pc         ),
    .doutb      (d_out_data )
);
assign d_out_valid = counting1;

endmodule
