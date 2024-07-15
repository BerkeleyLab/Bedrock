`timescale 1ns/1ns
/* A quick and dirty testbench for xadc_tempvoltmon
 */

module xadc_tempvoltmon_tb;

reg clk=1'b0;
always #5 clk <= ~clk;

initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("xadc_tempvoltmon.vcd");
    $dumpvars();
  end
end

wire [15:0] temp_out;
wire [15:0] vccint_out;
wire [15:0] vccaux_out;
wire [15:0] vbram_out;
xadc_tempvoltmon #(
  .SYSCLK_FREQ_HZ(100000000),
  .UPDATE_FREQ_HZ( 20000000)
  ) xadc_tempvoltmon_i (
  .clk(clk),
  .rst(1'b0),
  .temp_out(temp_out),
  .vccint_out(vccint_out),
  .vccaux_out(vccaux_out),
  .vbram_out(vbram_out),
  .read(),
  .otemp()
);

reg ok, fail=0;
initial begin
  #1000;
  //
  ok = temp_out == xadc_tempvoltmon_i.fake_xadc_i.test_temp;
  if (!ok) fail = 1;
  $display("TEMP   0x%x == 0x%x ?  %s", temp_out, xadc_tempvoltmon_i.fake_xadc_i.test_temp, ok?"  OK":"BAD!");
  //
  ok = vccint_out == xadc_tempvoltmon_i.fake_xadc_i.test_vccint;
  if (!ok) fail = 1;
  $display("VCCINT 0x%x == 0x%x ?  %s", vccint_out, xadc_tempvoltmon_i.fake_xadc_i.test_vccint, ok?"  OK":"BAD!");
  //
  ok = vccaux_out == xadc_tempvoltmon_i.fake_xadc_i.test_vccaux;
  if (!ok) fail = 1;
  $display("VCCAUX 0x%x == 0x%x ?  %s", vccaux_out, xadc_tempvoltmon_i.fake_xadc_i.test_vccaux, ok?"  OK":"BAD!");
  //
  ok = vbram_out == xadc_tempvoltmon_i.fake_xadc_i.test_vbram;
  if (!ok) fail = 1;
  $display("VBRAM  0x%x == 0x%x ?  %s", vbram_out, xadc_tempvoltmon_i.fake_xadc_i.test_vbram, ok?"  OK":"BAD!");
  //
  if (fail) $stop(0);
  $display("PASS");
  $finish(0);
end

endmodule
