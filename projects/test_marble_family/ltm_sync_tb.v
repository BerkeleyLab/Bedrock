`timescale 1ns / 1ns

module ltm_sync_tb;

integer cc;
reg clk, fail=0;
initial begin
        if ($test$plusargs("vcd")) begin
                $dumpfile("ltm_sync.vcd");
                $dumpvars(5, ltm_sync_tb);
        end
        $display("Non-checking testbench.  Will always PASS");
        for (cc=0; cc<800; cc=cc+1) begin
                clk=0; #4;
                clk=1; #4;
        end
        if (fail) begin
                $display("FAIL");
                $stop(0);
        end else begin
                $display("PASS");
                $finish(0);
        end
end

reg [4:0] ps_config = 21;
wire [2:0] ps_sync;
ltm_sync dut(.clk(clk), .ps_config(ps_config), .ps_sync(ps_sync));

endmodule
