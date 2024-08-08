/* A dummy localbus peripheral for testing localbus host schemes
 * Register-addressable memory (each memory address is a unique register), not
 * byte-addressable.
 * 256 r/w registers spanning addresses 0x00-0xff
 * Registers are initialized with 0x100 | addr (i.e. 0x100-0x1ff)
 */

module lb_dummy #(
   parameter LB_AW = 16
  ,parameter LB_DW = 32
) (
   input  lb_clk
  ,input  reset
  ,input  [LB_AW-1:0] lb_addr
  ,input  [LB_DW-1:0] lb_din
  ,output [LB_DW-1:0] lb_dout
  ,input  lb_wen
);

localparam integer HA_REG_AW = 8; // 256 registers
localparam integer NUM_HA_REGS = (1 << HA_REG_AW);
reg [LB_DW-1:0] ha_ram [0:NUM_HA_REGS-1];

integer N;
initial begin
  for (N = 0; N<NUM_HA_REGS; N=N+1) begin
    ha_ram[N] = {{LB_DW-9{1'b0}}, 1'b1, N[7:0]};
  end
end

wire ha_region = lb_addr[LB_AW-1:HA_REG_AW] == {LB_AW-HA_REG_AW{1'b0}};

reg [LB_DW-1:0] dout={LB_DW{1'b0}};
assign lb_dout = dout;

always @(posedge lb_clk) begin
  if (reset) begin
    dout <= {LB_DW{1'b0}};
    for (N = 0; N<NUM_HA_REGS; N=N+1) begin
      ha_ram[N] = {{LB_DW-9{1'b0}}, 1'b1, N[7:0]};
    end
  end else begin
    // writes
    if (lb_wen) begin
      if (ha_region) begin
        ha_ram[lb_addr[HA_REG_AW-1:0]] <= lb_din;
      end
    end
    // reads
    if (ha_region) begin
      dout <= ha_ram[lb_addr[HA_REG_AW-1:0]];
    end else begin
      dout <= {LB_DW{1'b0}};
    end
  end
end

endmodule
