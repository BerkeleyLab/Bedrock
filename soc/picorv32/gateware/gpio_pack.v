// --------------------------------------------------------------
//  gpio_pack.v
// --------------------------------------------------------------
// General purpose 32 bit input output port.
// uses the addressing scheme described in sfr_pack.v

module gpio_pack #(
    parameter BASE_ADDR=8'h00
) (
    input  wire        clk,
    input  wire        reset,
    // Hardware interface
    output wire [31:0] gpio_out,
    output wire [31:0] gpio_oe,
    input       [31:0] gpio_in,
    // PicoRV32 packed MEM Bus interface
    input  [68:0] mem_packed_fwd,  //DEC > GPO
    output [32:0] mem_packed_ret   //DEC < GPO
);

localparam GPIO_OUT_REG  =  0;
localparam GPIO_OE_REG   =  1;
localparam GPIO_IN_REG   =  2;

wire [3*32-1:0] sfRegsOut;
wire [3*32-1:0] sfRegsIn;
sfr_pack #(
    .BASE_ADDR      ( BASE_ADDR ),
    .N_REGS         ( 3 )
) sfrInst (
    .clk            ( clk ),
    .rst            ( reset ),
    .mem_packed_fwd ( mem_packed_fwd ),
    .mem_packed_ret ( mem_packed_ret ),
    .sfRegsOut      ( sfRegsOut ),
    .sfRegsIn       ( sfRegsIn ),
    .sfRegsWrStr    ()
);

// allow gpio_out and gpio_oe to be written
assign gpio_out = sfRegsOut[GPIO_OUT_REG*32+:32];
assign gpio_oe  = sfRegsOut[GPIO_OE_REG *32+:32];
// allow gpio_out and gpio_oe to be read back
assign sfRegsIn[GPIO_OUT_REG*32+:32] = sfRegsOut[GPIO_OUT_REG*32+:32];
assign sfRegsIn[GPIO_OE_REG *32+:32] = sfRegsOut[GPIO_OE_REG *32+:32];
// allow gpio_in to be read
assign sfRegsIn[GPIO_IN_REG *32+:32] = gpio_in;

endmodule
