// --------------------------------------------------------------
//  GPIO module with 32 bit tristate inout port
// --------------------------------------------------------------
// uses the addressing scheme described in sfr_pack.v

module gpioz_pack #(
    parameter BASE_ADDR=8'h00,
    parameter BASE2_ADDR=8'h00
) (
    input  wire        clk,
    input  wire        reset,
    // Hardware interface
    inout  wire [31:0] gpio_z,
    // PicoRV32 packed MEM Bus interface
    input  [68:0] mem_packed_fwd,  //DEC > GPO
    output [32:0] mem_packed_ret   //DEC < GPO
);

// --------------------------------------------------------------
//  GPIO module
// --------------------------------------------------------------
wire [31:0] gpio_out;
wire [31:0] gpio_oe;
gpio_pack #(
    .BASE_ADDR     ( BASE_ADDR      ),
    .BASE2_ADDR    ( BASE2_ADDR     )
) gpioInst (
    // Hardware interface
    .clk           ( clk            ),
    .reset         ( reset          ),
    // PicoRV32 packed MEM Bus interface
    .mem_packed_fwd( mem_packed_fwd ), //CPU > GPIO
    .mem_packed_ret( mem_packed_ret ), //CPU < GPIO
    // Hardware interface
    .gpio_out      ( gpio_out       ),
    .gpio_oe       ( gpio_oe        ),
    .gpio_in       ( gpio_z         )
);

generate
    genvar i;
    for (i=0; i<=31; i=i+1) begin
        assign gpio_z[i] = gpio_oe[i] ? gpio_out[i] : 1'bz;
    end
endgenerate

endmodule
