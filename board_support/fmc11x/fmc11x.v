module fmc11x #(
    parameter N_IC = 3,
    localparam N_CH = N_IC*4,
    parameter [7:0] BASE_ADDR = 8'h05
) (
    // Hardware pins
    inout [7:0]         CTRL,
    input               CLK_TO_FPGA_P,
    input               CLK_TO_FPGA_N,
    input [N_CH-1:0]    OUTA_P,
    input [N_CH-1:0]    OUTA_N,
    input [N_CH-1:0]    OUTB_P,
    input [N_CH-1:0]    OUTB_N,
    input [N_IC-1:0]    DCO_P,
    input [N_IC-1:0]    DCO_N,
    input               PG_M2C,
    input               PRSNT_M2C_L,

    // Data interface
    output         clk_to_fpga_out,
    output [N_IC-1:0]     clk_div_out,
    output [N_CH-1:0]     adc_out_clk,
    output [16*N_CH-1:0]  adc_out_data,

    // PicoRV32 packed MEM Bus interface
    input  clk,
    input  rst,
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret
);

wire [32:0] mem_packed_rets [N_CH-1:0];
wire [32:0] mem_packed_ret_spi;
wire [32:0] mem_packed_ret_sfr;
reg  [32:0] mem_packed_ret_r=0;
integer jx;
always @(*) begin
    mem_packed_ret_r = 0;
    for (jx=0; jx < N_CH; jx=jx+1)
        mem_packed_ret_r = mem_packed_ret_r | mem_packed_rets[jx];
end
assign mem_packed_ret = mem_packed_ret_r | mem_packed_ret_sfr | mem_packed_ret_spi;

//--------------------------------------------------------------
// BASE2 Address offsets
//--------------------------------------------------------------
localparam [7:0] BASE_ADC = 8'h00;
localparam [7:0] BASE_SFR = 8'h20;
localparam [7:0] BASE_SPI = 8'h21;

//--------------------------------------------------------------
// PicoRV SPI master
//--------------------------------------------------------------
wire spi_sck = CTRL[0];  // output
wire spi_ss  = CTRL[1];  // output
wire spi_dio = CTRL[2];  // inout

spi_dio_pack #(
    .BASE_ADDR      ( BASE_ADDR ),
    .BASE2_ADDR     ( BASE_SPI  )
) spi_master (
    .clk            ( clk      ),
    .rst            ( rst      ),
    .spi_ss         ( spi_ss   ),
    .spi_sck        ( spi_sck  ),
    .spi_dio        ( spi_dio  ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd (mem_packed_fwd ),
    .mem_packed_ret (mem_packed_ret_spi)
);

//--------------------------------------------------------------
// PicoRV SFR (GPIO output pins)
//--------------------------------------------------------------
wire [31:0] sfRegsWrStr;
wire [31:0] sfRegsOut, sfRegsInp;

sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR ),
    .BASE2_ADDR     ( BASE_SFR)
) sfr_reset (
    .clk            ( clk        ),
    .rst            ( rst        ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_ret_sfr ),
    .sfRegsOut      ( sfRegsOut ),
    .sfRegsIn       ( sfRegsInp ),
    .sfRegsWrStr    ( sfRegsWrStr )
);

/// #define SFR_BYTE_DAT_MUX    0
wire [3:0] dat_mux = sfRegsOut[3:0];
/// #define SFR_BYTE_BUFR_MUX   1
wire [3:0] bufr_mux = sfRegsOut[11:8];
/// #define SFR_BIT_BUFR_RESET  16
// Binary decoder to provide an individual reset signal to each bufr
wire [N_IC-1:0] bufr_reset = sfRegsWrStr[16] << bufr_mux;

reg [15:0] dat_mon [15:0];
integer k=0;
initial for (k=0;k<16;k=k+1) dat_mon[k] = 16'h0;

wire [15:0] dat_mon_mux = dat_mon[dat_mux];
/// #define  SFR_BYTE_DAT_MON     0
/// #define  SFR_BIT_PRSNT_M2C_L  24
/// #define  SFR_BIT_PG_M2C       25
assign sfRegsInp = {6'h0, PG_M2C, PRSNT_M2C_L, 8'h0, dat_mon_mux};

//--------------------------------------------------------------
// ADC
//--------------------------------------------------------------
wire clk_to_fpga_i;
IBUFDS #(
    .DIFF_TERM("TRUE")
) ibuf_clk(
    .I      (CLK_TO_FPGA_P),
    .IB     (CLK_TO_FPGA_N),
    .O      (clk_to_fpga_i)
);

BUFG bufg_i (
    .I      (clk_to_fpga_i),
    .O      (clk_to_fpga_out)
);

wire [N_IC-1:0] clk_dco_buf;
wire [N_IC-1:0] clk_div;
wire [N_IC-1:0] clk_div_buf;
wire [N_IC-1:0] clk_dco_frame;
wire [N_IC-1:0] clk_div_frame;
wire [N_CH-1:0] clk_dco_data;
wire [N_CH-1:0] clk_div_data;

wire [1:0] in_p [N_CH-1:0];
wire [1:0] in_n [N_CH-1:0];

fmc11x_clk_map #(
    .N_IC       (N_IC)
) clk_map_i (
    .clk_dco_in     (clk_dco_buf),
    .clk_div_in     (clk_div),
    .clk_dco_frame  (clk_dco_frame),        // not used
    .clk_div_frame  (clk_div_frame),        // not used
    .clk_dco_data   (clk_dco_data),
    .clk_div_data   (clk_div_data)
);

wire [15:0] serdes_out [15:0];
wire [15:0] adc_out [15:0];

genvar ix;
generate for (ix=0; ix<N_IC; ix=ix+1) begin: ic_map
    dco_buf dco_buf_i (
        .clk_reset    (bufr_reset[ix]),
        .dco_p        (DCO_P[ix]),
        .dco_n        (DCO_N[ix]),
        .clk_div      (clk_div[ix]),
        .clk_dco_buf  (clk_dco_buf[ix]),
        .clk_div_buf  (clk_div_buf[ix])
    );
end endgenerate

genvar ch;
generate for (ch=0; ch<N_CH; ch=ch+1) begin: ch_map
    assign in_p[ch] = {OUTA_P[ch], OUTB_P[ch]};
    assign in_n[ch] = {OUTA_N[ch], OUTB_N[ch]};

    iserdes_pack #(
        .DW            (2),
        .BASE_ADDR     (BASE_ADDR),
        .BASE2_ADDR    (BASE_ADC + ch)
    ) ltc2175 (
        // Hardware interface
        .clk_dco       ( clk_dco_data[ch] ),
        .clk_div       ( clk_div_data[ch] ),
        .in_p          ( in_p[ch]         ),
        .in_n          ( in_n[ch]         ),
        .dout          ( serdes_out[ch]   ),

        // PicoRV32 packed MEM Bus interface
        .clk            ( clk            ),
        .rst            ( rst            ),
        .mem_packed_fwd ( mem_packed_fwd ),
        .mem_packed_ret ( mem_packed_rets[ch] )
    );

	// XXX cross domains, data has to be a static training pattern
	always @(posedge clk) begin
	   dat_mon[ch] <= adc_out[ch];
	end

    // 2-Lane Output Mode, 16-Bit Serializaiton
    // Lane B
    assign adc_out[ch][ 0] = serdes_out[ch][0];
    assign adc_out[ch][ 2] = serdes_out[ch][1];
    assign adc_out[ch][ 4] = serdes_out[ch][2];
    assign adc_out[ch][ 6] = serdes_out[ch][3];
    assign adc_out[ch][ 8] = serdes_out[ch][4];
    assign adc_out[ch][10] = serdes_out[ch][5];
    assign adc_out[ch][12] = serdes_out[ch][6];
    assign adc_out[ch][14] = serdes_out[ch][7];
    // Lane A
    assign adc_out[ch][ 1] = serdes_out[ch][ 8];
    assign adc_out[ch][ 3] = serdes_out[ch][ 9];
    assign adc_out[ch][ 5] = serdes_out[ch][10];
    assign adc_out[ch][ 7] = serdes_out[ch][11];
    assign adc_out[ch][ 9] = serdes_out[ch][12];
    assign adc_out[ch][11] = serdes_out[ch][13];
    assign adc_out[ch][13] = serdes_out[ch][14];
    assign adc_out[ch][15] = serdes_out[ch][15];

    assign adc_out_data[16*ch+15: 16*ch] = adc_out[ch];
end endgenerate

assign adc_out_clk = clk_div_data;
assign clk_div_out = clk_div;

endmodule
