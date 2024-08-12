// verilog tasks for simulations
// see (Memory gateway timing)[]bedrock/badger/doc/mem_gateway.svg]

// requires defining:
// localparam LB_READ_DELAY = 3;

reg lb_write=0, lb_read=0, lb_prefill=0;
reg [17:0] lb_addr=0;
reg [31:0] lb_wdata=0;
wire [31:0] lb_rdata;
reg lb_rvalid=0;

task lb_write_task (
    input [23:0] addr,
    input [31:0] data
);
    begin
        @ (posedge lb_clk);
        lb_addr  = addr;
        lb_wdata = data;
        lb_write = 1'b1;
        @ (posedge lb_clk);
        lb_write = 1'b0;
    end
endtask

task lb_read_task (
    input [17:0] addr,
    output [31:0] data
);
    begin
        @ (posedge lb_clk);
        lb_addr = addr;
        lb_read = 1'b1;
        // repeat (4 + LB_READ_DELAY) @ (posedge lb_clk);    // badger timing
        repeat (0 + LB_READ_DELAY) @ (posedge lb_clk);
        lb_rvalid = 1'b1;
        data = lb_rdata;
        // $display("time: %g Read ack: ADDR 0x%x DATA 0x%x", $time, addr, lb_rdata);
        @ (posedge lb_clk);
        lb_read = 1'b0;
        lb_rvalid = 1'b0;
    end
endtask
