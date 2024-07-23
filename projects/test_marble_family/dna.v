`timescale 1ns / 1ns

/* Read Device DNA from Xilinx 7-series FPGA via "DNA_PORT" IP.
 * NOTE!!!! There is a (apparently undocumented) requirement that the clock
 *          provided to the DNA_PORT module is <100MHz (10ns min period).
 */

module dna (
  input wire clk,
  input wire rst,
  input wire start,
  output wire done,
  output wire [31:0] dna_msb,
  output wire [31:0] dna_lsb
  );

  reg [63:0] r_dna;
  reg shift=0;
  wire read, din, dout;

  // generate a slowed-down "clock" for the benefit of the DNA_PORT primitive
  reg [1:0] clk_div=0;
  always @(posedge clk) clk_div <= clk_div+1;
  wire dna_clk = clk_div[1];  // 1/4 the rate

`ifdef SIMULATE
  assign din = dout;
  reg [63:0] r_dna_int = 64'hb4b73a32bc169ba5;
  reg [63:0] r_dout;
  assign dout = r_dout[63];     // Device DNA is 57 bits long
                                // Shifts out MSb-first

  initial begin
    r_dout = 64'h0;
    r_dna = 64'h0;
  end

  always @(posedge dna_clk) begin
    if (read) begin
      r_dout <= r_dna_int;
    end else if (shift) begin
      r_dout <= {r_dout[62:0], din};
    end
  end

`else
  assign din = 0;      // Pedantically included
  DNA_PORT #(
    .SIM_DNA_VALUE(57'h000006789998212)  // Specifies a sample 57-bit DNA value for simulation
  ) DNA_PORT_inst (
    .DOUT(dout),   // 1-bit output: DNA output data.
    .CLK(dna_clk), // 1-bit input: Clock input (output of a DFF)
    .DIN(din),     // 1-bit input: User data input pin.
    .READ(read),   // 1-bit input: Active high load DNA, active low read input.
    .SHIFT(shift)  // 1-bit input: Active high shift enable input.
  );
`endif

  reg [6:0] bcnt=0;
  assign read = bcnt == 7'h0;
  reg r_done=1, r_start_0=0, r_start_1=0;
  wire start_re = r_start_0 && ~r_start_1;

  always @(posedge clk) begin
    if (rst) begin
      bcnt <= 7'h0;
      r_start_0 <= 0;
      r_start_1 <= 0;
      r_dna <= 64'h0;
    end else if (clk_div==2'b11) begin
      r_start_1 <= r_start_0;
      r_start_0 <= start;
      if (r_done) begin
        shift <= 0;
        if (start_re) begin
          r_done <= 0;
        end
      end else begin  // if ~r_done
        shift <= 1;
        r_dna <= {r_dna[62:0], dout};
        if (bcnt == 7'd63) begin
          r_done <= 1;
          bcnt <= 7'h0;
        end else begin
          r_done <= 0;
          bcnt <= bcnt + 1;
        end
      end
    end
  end

/*
localparam DXSIZE = 57;
wire [DXSIZE-1:0] dna_dclk = r_dna[63:7];
assign dna_msb = {7'h00, dna_dclk[56:32]};
assign dna_lsb = dna_dclk[31:0];
*/
assign dna_msb = {7'h00, r_dna[63:39]};
assign dna_lsb = r_dna[38:7];
assign done = r_done;

endmodule
