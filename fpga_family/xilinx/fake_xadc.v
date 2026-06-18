/* A very limited fake XADC core just to test the xadc_tempvoltmon module
 */

module fake_xadc (
  input RESET,                 // 1-bit input: Active-high reset
  output DRDY,                 // 1-bit output: DRP data ready
  // DRP Interface
  input DCLK,                  // 1-bit input: DRP clock
  output [15:0] DO,            // 16-bit output: DRP output data bus
  input [6:0] DADDR,           // 7-bit input: DRP address bus
  input DEN,                   // 1-bit input: DRP enable signal
  input [15:0] DI,             // 16-bit input: DRP input data bus
  input DWE                    // 1-bit input: DRP write enable
);

wire clk = DCLK;

localparam MEM_SIZE = (1 << 7);

localparam ADDR_INT_TEMP = 7'h0;
localparam ADDR_VCCINT = 7'h1;
localparam ADDR_VCCAUX = 7'h2;
localparam ADDR_VBRAM = 7'h6;

wire [15:0] test_temp   = 16'h9773; // ~25degC
wire [15:0] test_vccint = 16'h0123;
wire [15:0] test_vccaux = 16'h4567;
wire [15:0] test_vbram  = 16'h89ab;
reg [15:0] mem [0:MEM_SIZE-1];
integer N;
initial begin
  // Get rid of 'X's
  for (N=0; N<MEM_SIZE; N=N+1) begin
    mem[N] = 16'h0000;
  end
  // Assign some dummy values to known slots
  mem[ADDR_INT_TEMP] = test_temp;
  mem[ADDR_VCCINT]   = test_vccint;
  mem[ADDR_VCCAUX]   = test_vccaux;
  mem[ADDR_VBRAM]    = test_vbram;
end

reg [15:0] dout=0;
assign DO = dout;
reg drdy=1'b0;
assign DRDY = drdy;

always @(posedge clk) begin
  drdy <= 1'b0;
  if (RESET) begin
    dout <= 0;
  end else if (DWE) begin
    mem[DADDR] <= DI;
  end else if (DEN) begin
    dout <= mem[DADDR];
    drdy <= 1'b1;
  end
end

endmodule
