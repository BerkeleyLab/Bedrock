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
  reg [6:0] bcnt;
  reg shift, r_done, r_start_0, r_start_1;
  wire read = (bcnt == 7'h0) ? 1'b1 : 1'b0;
  wire start_re = (r_start_0 == 1'b1) && (r_start_1 == 1'b0) ? 1'b1 : 1'b0;
  wire din, dout;
  assign done = r_done;

  // HACK! This is a fake "clock", i.e. does not use clock routing resources
  // and has no constraints associated with it.  It will trigger warnings in
  // the timing report.  To avoid, use 'clk' directly and ensure it is
  // <100MHz.
  reg dclk;
  always @(posedge clk) begin
    dclk <= ~dclk;
  end

`ifdef SIMULATE
  assign dna_msb = r_dna[63:32];
  assign dna_lsb = r_dna[31:0];
  //reg [63:0] r_dna = 64'h4b696e7465782d37;
  assign din = dout;
  reg [63:0] r_dna_int = 64'hb4b73a32bc169ba5;
  reg [63:0] r_dout;
  assign dout = r_dout[63];     // Device DNA is 57 bits long
                                // Shifts out MSb-first

  initial begin
    dclk <= 1'b0;
    r_dout <= 64'h0;
    r_dna <= 64'h0;
  end

  always @(posedge dclk) begin
    if (read) begin
      r_dout <= r_dna_int;
    end else if (shift) begin
      r_dout <= {r_dout[62:0], din};
    end
  end

`else
  assign dna_msb = {7'h00, r_dna[63:39]};
  assign dna_lsb = r_dna[38:7];
  assign din = 1'b0;      // Pedantically included
  DNA_PORT #(
    .SIM_DNA_VALUE(57'h000006789998212)  // Specifies a sample 57-bit DNA value for simulation
  ) DNA_PORT_inst (
    .DOUT(dout),   // 1-bit output: DNA output data.
    .CLK(dclk),     // 1-bit input: Clock input.
    .DIN(din),     // 1-bit input: User data input pin.
    .READ(read),   // 1-bit input: Active high load DNA, active low read input.
    .SHIFT(shift)  // 1-bit input: Active high shift enable input.
  );
`endif

  initial begin
    r_done <= 1'b1;
    shift <= 1'b0;
    bcnt <= 7'h0;
    r_start_0 <= 1'b0;
    r_start_1 <= 1'b0;
  end

  always @(posedge dclk) begin
    if (rst) begin
      r_done <= 1'b1;
      bcnt <= 7'h0;
      r_start_0 <= 1'b0;
      r_start_1 <= 1'b0;
      r_dna <= 64'h0;
    end else begin
      r_start_1 <= r_start_0;
      r_start_0 <= start;
      if (r_done) begin
        shift <= 1'b0;
        if (start_re == 1'b1) begin
          r_done <= 1'b0;
        end
      end else begin  // if ~r_done
        shift <= 1'b1;
        r_dna <= {r_dna[62:0], dout};
        if (bcnt == 7'd64) begin
          r_done <= 1'b1;
          bcnt <= 7'h0;
        end else begin
          r_done <= 1'b0;
          bcnt <= bcnt + 1;
        end
      end
    end
  end


endmodule
