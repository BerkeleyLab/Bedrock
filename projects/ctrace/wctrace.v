// A version of ctrace with parameterized width which always reads out
// as 32-bit
// DW = Data width (number of bits of signal to log)
// TW = Time width (width of the time counter; sets overflow period)
// Limited to DW+TW <= 256

module wctrace #(
   parameter AW = 10  // width of address, sets depth of memory
  ,parameter DW = 40
  ,parameter TW = 24
) (
  input clk,
  input [DW-1:0] data,
  // Control in clk domain
  input start,  // single-cycle
  output running,
  output [AW-1:0] pc_mon,
  // Readout in lb_clk domain
  input lb_clk,
  input [AW-1:0] lb_addr,
  output [31:0] lb_out
);

localparam MEM_SHIFT = (DW+TW) > 128 ? 3 :
                       (DW+TW) >  64 ? 2 :
                       (DW+TW) >  32 ? 1 : 0;
localparam MEM_AW = AW - MEM_SHIFT;

reg [MEM_AW-1:0] pc=0, lb_addr_d=0;
reg running_r = 0;
assign running = running_r;
assign pc_mon = pc;

reg [TW-1:0] count = 0;

reg [DW-1:0] data1 = 0, data2 = 0; // pipeline
reg diff = 0;
reg of = 0;  // counter overflow
wire wen = running_r & (diff | of);
always @(posedge clk) begin
  lb_addr_d <= lb_addr;
  data1 <= data;
  data2 <= data1;
  diff <= data1 != data;
  if (start) begin
    pc <= 0;
    running_r <= 1;
    count <= 1;
    of <= 0;
  end else if (wen) begin
    count <= 1;
    pc <= pc + 1;
    if (&pc) running_r <= 0;
    of <= 0;
  end else begin
    {of,count} <= count + 1;
  end
end

wire [DW+TW-1:0] saveme = {count, data2};
wire [DW+TW-1:0] doutb_exact;
wire [MEM_AW-1:0] addrb = lb_addr[AW-1:MEM_SHIFT];

wire [255:0] doutb = {{256-DW-TW{1'b0}}, doutb_exact};  // stretch to widest useful form, left-padding with 0

generate
if ((DW+TW) > 256) begin: toowide
  initial begin
    $display("ERROR (wctrace.v): DW+TW = %d. Must be <= 256", DW+TW);
    $stop(0);
  end
end else if ((DW+TW) > 128) begin: wide3
  assign lb_out = lb_addr_d[2:0] == 3'b111 ? doutb[255:224] :
                  lb_addr_d[2:0] == 3'b110 ? doutb[223:192] :
                  lb_addr_d[2:0] == 3'b101 ? doutb[191:160] :
                  lb_addr_d[2:0] == 3'b100 ? doutb[159:128] :
                  lb_addr_d[2:0] == 3'b011 ? doutb[127:96] :
                  lb_addr_d[2:0] == 3'b010 ? doutb[95:64] :
                  lb_addr_d[2:0] == 3'b001 ? doutb[63:32] : doutb[31:0];
end else if ((DW+TW) > 64) begin: wide2
  assign lb_out = lb_addr_d[1:0] == 2'b11 ? doutb[127:96] :
                  lb_addr_d[1:0] == 2'b10 ? doutb[95:64] :
                  lb_addr_d[1:0] == 2'b01 ? doutb[63:32] : doutb[31:0];
end else if ((DW+TW) > 32) begin: wide1
  assign lb_out = lb_addr_d[0] ? doutb[63:32] : doutb[31:0];
end else begin: normal
  assign lb_out = doutb[31:0];
end
endgenerate

// Trace memory
dpram #(.dw(DW+TW), .aw(MEM_AW)) xmem (
  .clka(clk), .clkb(lb_clk),
  .addra(pc), .dina(saveme), .wena(wen),
  .addrb(addrb), .doutb(doutb_exact)
);

endmodule
