// Instantiates i2c_prog and i2c_bit,
// multiplexes access to a dpram
module i2c_chunk(
	// Single clock domain, slave to the local bus
	// hard-coded read/write 4K address space,
	// subdivided into quarters as shown below
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input [11:0] lb_addr,  // Local bus address
	input [7:0] lb_din,  // Data from local bus master
	input lb_write,  // memory space only
	output [7:0] lb_dout,  // Data made available to local bus master
	// Auxiliary control and status
	input run_cmd,  // Command sequencer to run
	input freeze,  // Keep output buffer from changing
	output run_stat,  // Reports if sequencer is running
	output updated,  // New data is available in output buffer
	output err_flag,  // Error condition detected
	output [3:0] hw_config,  // Can be used to select between I2C busses
	// Hardware pins: TWI (almost I2C) bus
	output scl,  // Direct drive of SCL pin
	output sda_drive,  // Low value should operate pull-down of SDA pin
	input  sda_sense,  // SDA pin
	input  rst,  // not yet used
	input  intp  // not yet used
);

parameter tick_scale = 6;
// transparently passed to i2c_prog
parameter q1 = 2;  // o_p1 ticks are 2^(q1+1) * bit_adv
parameter q2 = 7;  // o_p2 ticks are 2^(q2+1) * bit_adv

// Minor comment on the "freeze" input.  It's OK to play fast
// and loose with its clock domain, and even ignore it for a
// few cycles.  As long as it takes effect before a following
// read returns data, the sequence of reads that follows will
// stay self-consistent.  If the von Neumann machine that creates
// this command wants to be super-conservative, it's free to insert
// a bus cycle of some kind between the freeze command and the
// subsequent data read.

// Goal for tick is 5.6 MHz or slightly slower; i2c_bit builds in
// divide-by-14, and 5.6 MHz / 14 = 400 kHz bit rate.
// 125 MHz / 32 = 3.9 MHz yields 280 kHz bit rate.
reg tick=0;
reg [tick_scale-1:0] access=0;
always @(posedge clk) begin
	access <= access+1;
	tick <= &access;
end

// Main instantiation of programmable engine
wire bit_adv, sda_h;
wire [1:0] bit_cmd;
wire [9:0] p_addr;
reg  [7:0] p_data;
wire [7:0] result;
wire result_stb;
wire [9:0] result_p;
wire buffer_flip, trig_analyz;  // from i2c_prog
i2c_prog #(.q1(q1), .q2(q2)) prog (.clk(clk),
	.bit_cmd(bit_cmd), .bit_adv(bit_adv), .sda_h(sda_h),
	.p_addr(p_addr), .p_data(p_data),
	.result(result), .result_stb(result_stb), .result_addr(result_p),
	.run_cmd(run_cmd), .run_stat(run_stat), .hw_config(hw_config),
	.buffer_flip(buffer_flip), .trig_analyz(trig_analyz)
);

// That engine delegates pin driving to i2c_bit
wire scl_o;
i2c_bit ibit (.clk(clk),
	.tick(tick), .advance(bit_adv),
	.command(bit_cmd),
	.scl_o(scl_o), .sda_o(sda_drive), .sda_v(sda_sense), .sda_h(sda_h)
);

// Then i2c_analyze observes the pin levels
wire [7:0] trace;
wire trace_push;
reg trace_run=0;
i2c_analyze analyze(.clk(clk), .tick(tick),
	.scl(scl), .sda(sda_h), .intp(intp), .rst(rst),
	.bit_adv(bit_adv), .bit_cmd(bit_cmd),
	.trace(trace), .trace_push(trace_push), .run(trace_run)
);

reg [9:0] trace_a=0;  // Trace buffer counter, might be OK to stay here
reg [7:0] trace_h=0;  // analyze module doesn't buffer this
reg trace_k=0;
always @(posedge clk) begin
	if (trig_analyz) trace_run <= 1;
	if (&trace_a) trace_run <= 0;
end

// Logic governing ping-pong result buffer
// Updated flag can be read along with data during a freeze
reg pingpong=0, freeze_r=0, freeze_d=0, updated_r=0;
always @(posedge clk) begin
	freeze_r <= freeze;  // Just in case freeze comes from another domain
	freeze_d <= freeze_r;
	if (buffer_flip & ~freeze_d) begin
		pingpong <= ~pingpong;
		updated_r <= 1;
	end
	if (~freeze_r & freeze_d) updated_r <= 0;
end

// no need for a data buffer, result is static for many cycles
reg result_k=0;

// Collate write requests
// Output is the "X-bus" signals xbd (data), xba(address), and xbs (strobe)
// Memory is subdivided into quarters:
//   0x000 - 0x3ff   program
//   0x400 - 0x7ff   logic analyzer
//   0x800 - 0xbff   results
//   0xc00 - 0xfff   result buffer in progress (not meant for host access)
// The local bus side can read and write all of it.
reg [7:0] lb_wbufd=0, xbd=0;
reg [11:0] lb_wbufa=0, xba=0;
reg lb_wpend=0, err=0, xbs=0;
wire [11:0] result_addr = {1'b1, pingpong, result_p};
always @(posedge clk) begin
	// Write bus multiplex
	casez (access[3:0])
		4'b???0: begin xbd <= lb_wbufd; xba <= lb_wbufa; xbs <= lb_wpend; lb_wpend <= 0; end
		4'b0001: begin xbd <= trace_h;  xba <= {2'd1, trace_a};  xbs <= trace_k; trace_k <= 0;  if (trace_k) trace_a <= trace_a+1; end
		4'b0011: begin xbd <= result;   xba <= result_addr; xbs <= result_k; result_k <= 0; end
		4'b0101: begin xbd <= 8'bx;     xba <= {2'd0, p_addr};   xbs <= 0; end
		default: begin xbd <= 8'bx;     xba <= 12'bx; xbs <= 0; end
	endcase
	if (access[3:0]==7) p_data <= xbo;  // two cycles after p_addr presented on xba
	// Capture write cycles
	if (lb_write) begin
		lb_wbufd <= lb_din;
		lb_wbufa <= lb_addr;
		lb_wpend <= 1;
		if (lb_wpend) err <= 1;
	end
	// Capture results
	if (result_stb) result_k <= 1;
	// Capture trace events
	if (trace_push) begin
		trace_h <= trace;
		trace_k <= 1;
	end
end

// Special attention to support atomic buffer flip
wire lb_flip = lb_addr[11] & ~pingpong;
wire [11:0] lb_addr1 = lb_addr ^ {1'b0, lb_flip, 10'b0};

wire [7:0] xbo;  // local read data
wire [7:0] lb_dout0;
dpram #(.aw(12), .dw(8)) dpram(
	.clka(clk), .addra(xba), .dina(xbd), .wena(xbs), .douta(xbo),
	.clkb(clk), .addrb(lb_addr1), .doutb(lb_dout0)
);
assign lb_dout = lb_dout0;

// Eric Norum suggests true active drive for SCL, since it's edge sensitive
assign scl = scl_o;
assign err_flag = err;
assign updated = updated_r;

endmodule
