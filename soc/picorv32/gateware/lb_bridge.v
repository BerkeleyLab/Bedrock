// bridge to local bus
// only support 32 bit write
module lb_bridge #(
	parameter ADW=20,
	parameter READ_DELAY=3,
    parameter BASE_ADDR=8'h00
) (
    input clk,
    // PicoRV32 packed MEM Bus interface
    input  [68:0] mem_packed_fwd,
    output [32:0] mem_packed_ret,
	// local bus master
    input busy,
	output lb_write,
	output lb_read,
    output lb_rvalid,
	output [ADW-1:0] lb_addr,
	output [31:0] lb_wdata,
	input [31:0] lb_rdata
);

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire [31:0] mem_rdata;
wire mem_ready;
munpack mu (
    .clk           (clk),
    .mem_packed_fwd( mem_packed_fwd ),
    .mem_packed_ret( mem_packed_ret ),
    .mem_wdata ( mem_wdata ),
    .mem_wstrb ( mem_wstrb ),
    .mem_valid ( mem_valid ),
    .mem_addr  ( mem_addr  ),
    .mem_ready ( mem_ready ),
    .mem_rdata ( mem_rdata )
);

wire  [7:0] mem_addr_base = mem_addr[31:24];// Which peripheral   (BASE_ADDR)

assign lb_wdata = mem_wdata;
// only react on 32 bit writes
wire mem_write = mem_valid &&  (&mem_wstrb) && (mem_addr_base==BASE_ADDR);
wire mem_read  = mem_valid && !(|mem_wstrb) && (mem_addr_base==BASE_ADDR);

assign lb_write = mem_write & ~busy;
assign lb_read = mem_read & ~busy;
assign lb_addr = mem_addr[ADW+1:2];

// match mem_gateway.v
lb_reading #(.READ_DELAY(READ_DELAY)) reading (
	.clk        (clk),
	.reset      (busy),
	.lb_read    (lb_read),
	.lb_rvalid  (lb_rvalid)
);

wire lb_write_ready = mem_write & ~busy;
assign mem_ready = lb_write_ready | lb_rvalid;
// assign mem_rdata = lb_rdata;
assign mem_rdata = lb_rvalid ? lb_rdata : 32'd0;

endmodule
