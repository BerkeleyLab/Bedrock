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

xadc_tempvoltmon #(
  .SYSCLK_FREQ_HZ(100000000),
  .UPDATE_FREQ_HZ( 20000000)
  ) xadc_tempvoltmon_i (
  .clk(clk),
  .rst(1'b0),
  .temp_out(),
  .vccint_out(),
  .vccaux_out(),
  .vbram_out(),
  .read(),
  .otemp()
);

initial begin
  #1000 $display("DONE");
        $finish(0);
end

endmodule
