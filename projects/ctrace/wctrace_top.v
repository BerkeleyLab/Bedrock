// A top-level Verilog interface for a live Verilator simulator

module wctrace_top (
  input clk,
  // client interface with RTEFI, see clients.eps
  input [10:0] len_c,
  input [7:0] idata,
  input raw_l,
  input raw_s,
  output [7:0] odata,
  output [7:0] n_lat_expose  // work around a limitation in Verilator
);

parameter n_lat=10;
assign n_lat_expose = n_lat;

// NOTE: These parameter assignments need to agree with "config.in"
localparam AW = 12;
localparam DW = 20;
localparam TW = 24;

// Bus controller
wire [23:0] addr;
wire [31:0] data_out, data_in;
wire control_strobe, control_rd, control_rd_valid;
mem_gateway #(.n_lat(n_lat)) mem_gateway_i (
  .clk(clk),
  .len_c(len_c), // input [10:0]
  .idata(idata), // input [7:0]
  .raw_l(raw_l), // input
  .raw_s(raw_s), // input
  .odata(odata), // output [7:0]
  .addr(addr), // output [23:0]
  .control_strobe(control_strobe), // output
  .control_rd(control_rd), // output
  .control_rd_valid(control_rd_valid), // output
  .data_out(data_out), // output [31:0]
  .data_in(data_in) // input [31:0]
);

reg [31:0] lb_din=0;
assign data_in = lb_din;

// Configuration ROM (should be at standard LEEP location 0x4000)
wire [15:0] config_rom_out;
config_romx rom (
  .clk(clk), .address(addr[10:0]), .data(config_rom_out)
);

wire [DW-1:0] trace_data;
reg start=1'b0;
wire running;
wire [AW-1:0] pc_mon;
wire [AW-1:0] wctrace_lb_addr = addr[AW-1:0];
wire [31:0] wctrace_lb_out;
wctrace #(
  .AW(AW),
  .DW(DW),
  .TW(TW)
) wctrace_i (
  .clk(clk), // input
  .data(trace_data), // input [DW-1:0]
  .start(start), // input
  .running(running), // output
  .pc_mon(pc_mon), // output [AW-1:0]
  .lb_clk(clk), // input
  .lb_addr(wctrace_lb_addr), // input [AW-1:0]
  .lb_out(wctrace_lb_out) // output [31:0]
);

// Hand-rolled decoder.  This must agree with the hand-written "wctrace_top_regmap.json"
always @(posedge clk) begin
  start <= 1'b0; // strobe
  // Writes (just one strobe in this demo)
  if (control_strobe & (~control_rd)) begin
    casez (addr[15:0])
      16'h1000: start <= data_out[0];
    endcase
  end
  // Reads
  casez (addr[15:0])
    16'b0100_0???_????_????: lb_din <= {16'h0000, config_rom_out};
    16'h1002: lb_din <= {{32-AW{1'b0}}, pc_mon};
    16'h1001: lb_din <= {31'h00000000, running};
    16'h000???: lb_din <= wctrace_lb_out;
  endcase
end

// Fake data for wctrace
reg [DW-5:0] counter=0;
reg [3:0] strobes=4'h0;
always @(posedge clk) begin
  strobes <= 4'h0;
  counter <= counter+1;
  if (counter[3:0] == 4'h0) strobes[0] <= 1'b1;
  if (counter[3:0] == 4'h2) strobes[1] <= 1'b1;
  if (counter[3:0] == 4'h4) strobes[2] <= 1'b1;
  if (counter[3:0] == 4'h8) strobes[3] <= 1'b1;
end

// NOTE: These signal assignments need to agree with "config.in"
assign trace_data[DW-5:0] = counter;
assign trace_data[DW-1-:4] = strobes;

endmodule
