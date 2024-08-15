`timescale 1ns/1ns

module axi_channel_xdomain_tb;

localparam CLKA_HALFPERIOD = 5;
localparam CLKB_HALFPERIOD = 2;
localparam TICK = 2*CLKA_HALFPERIOD;
reg clka=1'b1;
always #CLKA_HALFPERIOD clka <= ~clka;
reg clkb=1'b1;
always #CLKB_HALFPERIOD clkb <= ~clkb;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("axi_channel_xdomain.vcd");
    $dumpvars();
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] r_timeout=0;
always @(posedge clka) begin
  if (r_timeout > 0) r_timeout <= r_timeout - 1;
end
wire to = ~(|r_timeout);
`define wait_timeout(sig) r_timeout = TOSET; #TICK wait ((to) || sig)

localparam WIDTH = 16;

wire [WIDTH-1:0] dataa, datab, datac, datad;
wire valida, validb, validc, validd;
wire readya, readyb, readyc, readyd;

reg [WIDTH-1:0] send_data=0;
reg send=1'b0;
channel_producer #(
  .WIDTH(WIDTH)
) channel_producer_a (
  .clk(clka), // input
  .data(dataa), // output [WIDTH-1:0]
  .valid(valida), // output
  .ready(readya), // input
  .send_data(send_data), // input [WIDTH-1:0]
  .send(send) // input
);

axi_channel_xdomain #(
  .WIDTH(WIDTH)
) axi_channel_xdomain_atob (
  .clka(clka), // input
  .dataa(dataa), // input [WIDTH-1:0]
  .valida(valida), // input
  .readya(readya), // output
  .clkb(clkb), // input
  .datab(datab), // output [WIDTH-1:0]
  .validb(validb), // output
  .readyb(readyb) // input
);

wire [WIDTH-1:0] datab_latched, dataa_latched;
wire datab_latched_valid, dataa_latched_valid;
channel_consumer #(
  .WIDTH(WIDTH)
) channel_consumer_b (
  .clk(clkb), // input
  .data(datab), // input [WIDTH-1:0]
  .valid(validb), // input
  .ready_first(1'b0), // input
  .ready(readyb), // output
  .data_latched(datab_latched), // output [WIDTH-1:0]
  .data_latched_valid(datab_latched_valid) // output
);

channel_producer #(
  .WIDTH(WIDTH)
) channel_producer_b (
  .clk(clkb), // input
  .data(datac), // output [WIDTH-1:0]
  .valid(validc), // output
  .ready(readyc), // input
  .send_data(datab_latched), // input [WIDTH-1:0]
  .send(datab_latched_valid) // input
);

axi_channel_xdomain #(
  .WIDTH(WIDTH)
) axi_channel_xdomain_btoa (
  .clka(clkb), // input
  .dataa(datac), // input [WIDTH-1:0]
  .valida(validc), // input
  .readya(readyc), // output
  .clkb(clka), // input
  .datab(datad), // output [WIDTH-1:0]
  .validb(validd), // output
  .readyb(readyd) // input
);

channel_consumer #(
  .WIDTH(WIDTH)
) channel_consumer_a (
  .clk(clka), // input
  .data(datad), // input [WIDTH-1:0]
  .valid(validd), // input
  .ready_first(1'b1), // input
  .ready(readyd), // output
  .data_latched(dataa_latched), // output [WIDTH-1:0]
  .data_latched_valid(dataa_latched_valid) // output
);

reg [WIDTH-1:0] send_list [0:3];
integer N;
initial begin
  send_list[0] <= 'hbeef;
  send_list[1] <= 'h2345;
  send_list[2] <= 'h794c;
  send_list[3] <= 'hdff3;
end
// =========== Stimulus =============
initial begin
  for (N=0; N<4; N=N+1) begin
  @(posedge clka) send <= 1'b0;
  @(posedge clka) send_data <= send_list[N];
        send <= 1'b1;
  @(posedge clka) send <= 1'b0;
        `wait_timeout(datab_latched_valid);
        if (to) begin
          $display("Timeout waiting for datab_latched_valid");
          $stop(0);
        end else begin
          if (datab_latched != send_data) begin
            $display("datab_latched mismatch: 0x%x != 0x%x", datab_latched, send_data);
            $stop(0);
          end
        end
        `wait_timeout(dataa_latched_valid);
        if (to) begin
          $display("Timeout waiting for dataa_latched_valid");
          $stop(0);
        end else begin
          if (dataa_latched != send_data) begin
            $display("dataa_latched mismatch: 0x%x != 0x%x", dataa_latched, send_data);
            $stop(0);
          end
        end
  end
  $display("PASS");
  $finish(0);
end

endmodule
