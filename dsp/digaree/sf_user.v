module sf_user #(
	parameter pw = 18,  // port width
	parameter extra = 4,  // see sf_main
	parameter mw = 18,  // multiplier width, pw + extra >= mw
	parameter data_len = 6,
	parameter consts_len = 4,
	parameter const_aw = 2
) (
	input clk,
	input ce,  // clock enable
	input signed [pw-1:0] meas,  // measurements from radio
	input trigger,   // high for one cycle, just before meas stream starts
`ifdef PARAM_REGBANK
	// Flattened input to parameter register bank
	input [pw*(2**const_aw)-1:0] param_in,
`else
	// Host port to set parameters in DPRAM
	input h_write,
	input [const_aw-1:0] h_addr,
	input signed [pw-1:0] h_data,
`endif
	// Results
	output signed [pw-1:0] a_o,
	output signed [pw-1:0] b_o,
	output signed [pw-1:0] c_o,
	output signed [pw-1:0] d_o,
	// Debug output
	output signed [pw+extra-1:0] trace,
	output trace_strobe,
	output [6:0] sat_count
);

// PC stalls at 127, resets to 0 on trigger
reg [6:0] pc=127;
wire step=~(&pc);
reg run=0, run1=0;
always @(posedge clk) if (ce) begin
	pc <= trigger ? 0 : pc + step;
	if (~step) run <= 0;
	if (trigger) run <= 1;
	run1 <= run;
end
assign trace_strobe = run1;

wire signed [pw-1:0] const_val;
wire [const_aw-1:0] addrb = pc + 1 - data_len;

`ifdef PARAM_REGBANK
// Register bank written by the host, read by state machine
reg [pw-1:0] p_regbank[2**const_aw-1:0];

genvar r;
generate for (r=0; r<2**const_aw; r=r+1) begin : G_P_REGBANK
	always @(posedge clk) begin // Retime
		p_regbank[r] <= param_in[(r+1)*pw-1: r*pw];
	end
end endgenerate

// Delay addrb to match dpram latency
reg [const_aw-1:0] addrb_r;
always @(posedge clk) addrb_r <= addrb;

assign const_val = p_regbank[addrb_r];

`else

// DPRAM written by the host, read by the state machine
sf_dpram #(.aw(const_aw), .dw(pw)) consts(
	.clka(clk), .clkb(clk),
	.addra(h_addr), .dina(h_data), .wena(ce & h_write),
	.addrb(addrb), .doutb(const_val));

`endif

// Measurements stream in during first data_len cycles,
// host-settable parameters during next consts_len cycles.
wire choose_const = pc>=data_len && pc<(data_len+consts_len);
reg signed [pw-1:0] meas_mux=0;
always @(posedge clk) if (ce) meas_mux <= choose_const ? const_val : meas;

// Create the instruction ROM, using generated code.
// It would be easy to make this memory writable, but I don't
// think I will want to change the program at run time.
(* rom_style = "distributed" *) reg [20:0] inst;
always @(posedge clk) if (ce) case (pc)
`include "ops.vh"
endcase

// reg [20:0] inst1=0;
// always @(posedge clk) if (ce) inst1 <= inst;  // pipeline for speed with S3 BRAM

// Instantiate the compute engine
wire sat_happened;
sf_main #(.pw(pw), .extra(extra), .mw(mw)) cpu(.clk(clk), .ce(ce),
	.inst(inst), .meas(meas_mux),
	.a_o(a_o), .b_o(b_o),
	.c_o(c_o), .d_o(d_o),
	.trace(trace), .sat_happened(sat_happened));

// Count saturation events
reg [6:0] sat_cnt=0, sat_report=0;
always @(posedge clk) if (ce) begin
	sat_cnt <= trigger ? 0 : sat_cnt + sat_happened;
	if (trigger) sat_report <= sat_cnt;
end
assign sat_count = sat_report;

endmodule
