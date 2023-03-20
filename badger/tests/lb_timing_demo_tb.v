`timescale 1ns / 1ns
module lb_timing_demo_tb;

localparam CLK_CYCLE    = 8; // 125MHz
localparam LB_READ_DELAY= 3;
localparam LB_ADW       = 20;
localparam MAX_SIM      = 8200;   // ns

// include "_autogen/regmap.vh"
// Automatically generated register map of the local bus
localparam [19:0] TEST_REG1 = 20'h00100;
localparam [19:0] TEST_REG2 = 20'h00200;

reg lb_clk = 0;
initial begin
    $display("Non-checking testbench.  Will always PASS");
    if ($test$plusargs("vcd")) begin
        $dumpfile("lb_timing_demo.vcd");
        $dumpvars(6, lb_timing_demo_tb);
    end
    #MAX_SIM;
    $display("PASS");
    $finish();
end

always #(CLK_CYCLE/2) lb_clk = ~lb_clk;

// --------------------------------------------------------------
//  local bus functions
// --------------------------------------------------------------
reg lb_write=0, lb_read=0;
reg [LB_ADW-1:0] lb_addr=0;
reg [31:0] lb_wdata=0;
reg [31:0] lb_rdata=0;
reg lb_pre_rvalid=0;
reg lb_rvalid=0;

task lb_write_task;
    input [LB_ADW-1:0] addr;
    input [31:0] data;
    begin
        @ (posedge lb_clk);
        lb_addr  = addr;
        lb_wdata = data;
        lb_write = 1'b1;
        @ (posedge lb_clk);
        lb_write = 1'b0;
    end
endtask

task lb_read_task;
    input [LB_ADW-1:0] addr;
    begin
        @ (posedge lb_clk);
        lb_addr = addr;
        lb_read = 1'b1;
        repeat (0+LB_READ_DELAY-1) @ (posedge lb_clk);
        lb_rvalid = 1'b1;
        $display("time: %g Read ack: ADDR: 0x%x DATA: %s", $time, addr, lb_rdata);
        @ (posedge lb_clk);
        lb_read = 1'b0;
        lb_rvalid = 1'b0;
    end
endtask

// master
always @(posedge lb_clk) begin
    #20;
    $display("---- Write Cycle ----\n");
    lb_write_task(TEST_REG1, "wdat");
    #20;
    $display("---- Read Cycle ----\n");
    lb_read_task(TEST_REG2);
    #20;
    $display("PASS");
    $finish();
end

// slave
always @(posedge lb_clk) begin
    #1 if (lb_write) begin
        $display("time: %g Wrote   : ADDR: 0x%x DATA: %s", $time, lb_addr, lb_wdata);
    end
    if (lb_read) lb_rdata <= "rdat";
end

endmodule
