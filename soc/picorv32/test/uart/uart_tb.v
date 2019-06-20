`timescale 1 ns / 1 ns

module uart_tb;

parameter CLK_CYCLE=8; // 125MHz
parameter FRAME_LEN=16;
parameter DW=8;
integer cc;
reg clk = 0;
reg rst = 0;
integer errors=0;
initial begin
    if ($test$plusargs("vcd")) begin
        $dumpfile("uart.vcd");
        $dumpvars(5,uart_tb);
    end
    for (cc=0; cc<25000; cc=cc+1) begin
        clk=0; #(CLK_CYCLE/2);
        clk=1; #(CLK_CYCLE/2);
    end
    $display("%d errors", errors);
    if (errors == 0) begin
        $display("PASS");
        $finish;
    end
    $display("FAIL");
    $stop;
end

// generate reset
always @(posedge clk) rst <= (cc <= 2);

// The prescale input determines the data rate - it should be set to Fclk / (baud * 8).
// baud = 115200, 125e6/(115200*8)= 1085
// reg [15:0] prescale = 1085;
reg [15:0] prescale = 15;
wire [7:0] output_axis_tdata;
wire output_axis_tvalid;

wire tx_tready;
wire [DW-1:0] tx_tdata;
wire tx_tvalid;
wire tx_tlast;
wire [DW-1:0] rx_tdata;
wire [1:0] tx_tkeep;
wire rx_tvalid;
wire rx_tlast;
wire rx_tready;
parameter PATTERN = 128'h0123_3210_2222_3333_4444_5555_beaf_dead;
frame_gen #(
    .PATTERN(PATTERN),
    .FRAME_LEN(FRAME_LEN), .DW(DW)
) gen(
    .clk(clk),
    .reset(rst),
    .link_up(1'b1),
    .stream_tx_tready(tx_tready),
    .stream_tx_tdata(tx_tdata),
    .stream_tx_tvalid(tx_tvalid),
    .stream_tx_tkeep(tx_tkeep),
    .stream_tx_tlast(tx_tlast)
);

wire frame_valid;
frame_check #(
    .PATTERN(PATTERN),
    .FRAME_LEN(FRAME_LEN), .DW(DW)
) check(
    .clk(clk),
    .reset(rst),
    .stream_rx_tdata(rx_tdata),
    .stream_rx_tvalid(rx_tvalid),
    .stream_rx_tlast(rx_tlast),
    .stream_rx_tready(rx_tready),
    .check_valid(frame_valid)
);
wire rxd, txd;
wire tx_busy, rx_busy;

uart_tx #( .DATA_WIDTH(DW)
) uart_tx_inst (
    .clk(clk),
    .rst(rst),
    // axi input
    .input_axis_tdata(tx_tdata),
    .input_axis_tvalid(tx_tvalid),
    .output_axis_tready(tx_tready),
    // output
    .txd(txd),
    // status
    .busy(tx_busy),
    // configuration
    .prescale(prescale)
);

uart_rx #( .DATA_WIDTH(DW)
) uart_rx_inst (
    .clk(clk),
    .rst(rst),
    // axi output
    .output_axis_tdata(rx_tdata),
    .output_axis_tvalid(rx_tvalid),
    .input_axis_tready(rx_tready),
    // input
    .rxd(rxd),
    // status
    .busy(rx_busy),
    .overrun_error(),
    .frame_error(),
    // configuration
    .prescale(prescale)
);

reg [8:0] rx_tlast_cnt=0;
always @(posedge clk) if (rx_tvalid) rx_tlast_cnt <= (rx_tlast_cnt==FRAME_LEN) ? 0 : rx_tlast_cnt + 1;
assign rx_tlast = rx_tvalid && (rx_tlast_cnt==FRAME_LEN);

reg rx_tlast_dly=0;
always @(posedge clk) begin
    rx_tlast_dly <= rx_tlast;
    if (rx_tlast_dly) errors <= errors + !frame_valid;
end

// loop back
assign rxd = txd;

endmodule
