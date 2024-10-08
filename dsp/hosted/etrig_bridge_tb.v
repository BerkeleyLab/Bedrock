// etrig_bridge_tb.v

`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module etrig_bridge_tb;

    reg j5_24v = 1, j4_24v = 1, de9_rxd = 1, de9_dsr = 1; // Active-low
    reg [1:0] etrig_sel = 0;
    reg [25:0] etrig_period = 26'h0000ff;
    reg [25:0] etrig_delay = 26'h000000;
    wire [15:0] etrig_pulse_cnt;
    wire etrig_pulse;
    wire etrig_pulse_delayed;

    // Testbench parameters and clocking
    reg fail = 0;
    integer seed_int=123;
    localparam SIM_TIME = 50000; // ns
    localparam period_lb_clk = 20;
    localparam period_adc_clk = 10;

    reg free_lb_clk=0;
    wire lb_clk;
    always begin free_lb_clk = ~free_lb_clk; #(period_lb_clk/2);  end

    reg free_adc_clk=0;
    wire adc_clk;
    always begin free_adc_clk = ~free_adc_clk; #(period_adc_clk/2);  end

    reg pll_lock_emu=0;

    // Testbench control
    initial begin
      if ($test$plusargs("vcd")) begin
       $dumpfile("etrig_bridge.vcd");
       $dumpvars(5, etrig_bridge_tb);
      end

      while ($time < SIM_TIME) @(posedge lb_clk);
      if (!fail) begin
       $display("WARNING: Not a self-checking testbench. Will always PASS.");
       $finish(0);
      end else begin
       $display("FAIL");
       $stop(0);
      end
    end

    etrig_bridge UUT (
      .lb_clk(lb_clk), .adc_clk(adc_clk),
      .trign_0(j5_24v),
      .trign_1(j4_24v),
      .trign_2(de9_rxd&de9_dsr),
      .sel(etrig_sel), .period(etrig_period), .delay(etrig_delay),
      .etrig_pulse_cnt(etrig_pulse_cnt), .etrig_pulse(etrig_pulse),
      .etrig_pulse_delayed(etrig_pulse_delayed)
      );

// trigger loop
always begin
  if (!pll_lock_emu) begin
    #(($urandom(seed_int)%20)*period_lb_clk);
    pll_lock_emu <= 1'b1;
  end

  #(($urandom(seed_int)%20)*20);
  {j4_24v, j5_24v, de9_rxd, de9_dsr} <= $urandom(seed_int)%16;
  @(posedge adc_clk);

  #(($urandom(seed_int)%20)*200);
  {j4_24v, j5_24v, de9_rxd, de9_dsr} <= (1<<4)-1;
  etrig_delay <= etrig_delay + 1;
  @(posedge adc_clk);
end

always @(posedge adc_clk)
  etrig_sel <= etrig_sel + etrig_pulse;

// clocking
assign lb_clk = (pll_lock_emu) ? free_lb_clk : 1'b0;
assign adc_clk = (pll_lock_emu) ? free_adc_clk : 1'b0;

endmodule
