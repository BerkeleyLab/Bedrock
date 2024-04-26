`timescale 1ns / 1ns

// Experiment to fix CDC in lcls2_llrf application_top.v
// Preload a 16x32 dpram with the output of a mux running in the app_clk domain
// Do that in response to a lb_prefill request, that has to be provided
// some 300 ns before the actual lb_clk read cycles.
// In our network-gatewayed localbus context, that would come at
// the beginning of a packet.  Test versions of both badger/mem_gateway
// and bmb7_kintex/jxj_gate have such an output.

module jit_rad_gateway #(
	parameter passthrough = 1
) (
	// basic localbus hookup
	input lb_clk,
	input [3:0] lb_addr,
	input lb_strobe,
	output [31:0] lb_odata,
	// control
	input lb_prefill,
	output lb_error,
	input app_clk,
	// to application mux
	output xfer_clk,
	output xfer_snap,
	output xfer_strobe,
	output [3:0] xfer_addr,
	input [31:0] xfer_odata
);

generate if (passthrough) begin : thru
	// Zero-footprint option, that doesn't solve CDC problems
	assign xfer_clk = lb_clk;
	assign xfer_strobe = lb_strobe;
	assign xfer_addr = lb_addr;
	assign lb_odata = xfer_odata;
	assign lb_error = 0;
	assign xfer_snap = 1;  // doesn't really work
end else begin : buffer
	// Actually separate lb_clk domain from xfer_clk domain
	// Takes a bit more than 17 xfer_clk cycles to fill the
	// dpram with a snapshot of the mux results, after which
	// the lb_clk read process can just grab data from the dpram.
	assign xfer_clk = app_clk;
	wire app_prefill;
	flag_xdomain trig(
		.clk1(lb_clk), .flagin_clk1(lb_prefill),
		.clk2(app_clk), .flagout_clk2(app_prefill));
	assign xfer_snap = app_prefill;
	//
	reg buff_we=0;
	reg [3:0] addr1=0, addr2=0;
	wire app_running = |addr1;
	reg app_running_r=0;
	assign xfer_strobe = app_prefill | app_running;
	always @(posedge app_clk) begin
		if (app_prefill | app_running) addr1 <= addr1 + 1;
		buff_we <= xfer_strobe;
		addr2 <= addr1;
		app_running_r <= app_running;
	end
	assign xfer_addr = addr1;
	dpram #(.aw(4), .dw(32)) buff(
		.clka(app_clk), .addra(addr2), .wena(buff_we), .dina(xfer_odata),
		.clkb(lb_clk), .addrb(lb_addr), .doutb(lb_odata));
	//
	reg lb_pending=0, lb_running=0;
	always @(posedge lb_clk) lb_running <= app_running_r;  // CDC
	always @(posedge lb_clk) begin
		if (lb_prefill) lb_pending <= 1;
		if (lb_running) lb_pending <= 0;
	end
	assign lb_error = (lb_prefill | lb_strobe) & (lb_pending | lb_running);
end endgenerate

endmodule
