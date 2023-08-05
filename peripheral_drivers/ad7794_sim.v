module ad7794_sim (
   input  CLK,
   input  CS,
   input  DIN,
   output DOUT_RDY,
   input  SCLK
);

   reg [31:0] value=0;
   reg [31:0] value_sr=0;
   always @(negedge SCLK or posedge CS) begin
      if (CS) begin
         value <= value + 1;
         value_sr <= value;
      end else if (!CS) value_sr <= {value_sr[30:0], 1'b0};
   end
   reg [31:0] shifter;
   always @(posedge SCLK or posedge CS) begin
      if (CS)
         shifter <= {32{1'bx}};
      else
         shifter <= {shifter, DIN};
   end

   always @(posedge CS) $display("AD7794 simulator received word %8x", shifter);
   assign DOUT_RDY = CS ? 1'bz : value_sr[31];

endmodule
