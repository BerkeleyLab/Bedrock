// ------------------------------------
// SF_USER_WRAP
// Convenience wrapper over sf_user, allowing its parameters to be set via:
// - Memory interface (sf_user_pmem)
// - Parallel register interface (sf_user_preg)
//
// Care must be taken when updating parameters while data is flowing as it
// may result in sf_user sampling an incoherent parameter set and producing
// incorrect results. Examples of such situations are:
// - When using the memory interface, the parameter set can't be updated atomically
// - The use of distinct host_clk and sf_clk domains may lead to temporary
//   meta-stability affecting the reading of the parameters
//
// It is up to the user to prevent or mitigate these scenarios.
//
// ------------------------------------

`define SF_USER_PARAM parameter pw = 18,\
                      parameter extra = 4,\
                      parameter mw = 18,\
                      parameter data_len = 6,\
                      parameter consts_len = 4,\
                      parameter const_aw = 2

`define SF_USER_PORTS input sf_clk,\
                      input ce,\
                      input signed [pw-1:0] meas,\
                      input trigger,\
                      output                 ab_update,\
                      output signed [pw-1:0] a_o,\
                      output signed [pw-1:0] b_o,\
                      output                 cd_update,\
                      output signed [pw-1:0] c_o,\
                      output signed [pw-1:0] d_o,\
                      output signed [pw+extra-1:0] trace,\
                      output [6:0] trace_addr,\
                      output trace_strobe,\
                      output [6:0] sat_count,

module sf_user_pmem #(
        `SF_USER_PARAM
) (
        `SF_USER_PORTS
        // Host port to set parameters in DPRAM
        input                 h_clk,
        input                 h_write,
        input  [const_aw-1:0] h_addr,
        input signed [pw-1:0] h_data
);

wire signed [pw-1:0]       rd_data;
wire        [const_aw-1:0] rd_addr;

// DPRAM written by the host, read by the state machine
sf_dpram #(.aw(const_aw), .dw(pw)) i_const_mem (
        .clka(h_clk), .clkb(sf_clk),
        .addra(h_addr), .dina(h_data), .wena(ce & h_write),
        .addrb(rd_addr), .doutb(rd_data));

sf_user #(.pw(pw), .extra(extra), .mw(mw), .data_len(data_len),
        .consts_len(consts_len), .const_aw(const_aw))
sf_user (
        .clk(sf_clk), .ce(ce), .meas(meas), .trigger(trigger),
        .h_addr(rd_addr), .h_data(rd_data),
        .ab_update(ab_update), .a_o(a_o), .b_o(b_o),
        .cd_update(cd_update), .c_o(c_o), .d_o(d_o),
        .trace(trace), .trace_addr(trace_addr), .trace_strobe(trace_strobe),
        .sat_count(sat_count));

endmodule


module sf_user_preg #(
        `SF_USER_PARAM
) (
        `SF_USER_PORTS
        // Flattened input to parameter register bank
        input [pw*consts_len-1:0] param_in
);

wire signed [pw-1:0]       rd_data;
wire        [const_aw-1:0] rd_addr;
reg         [pw-1:0]       p_regbank[consts_len-1:0];

// Register bank written by the host, read by state machine.
// Input parameters (param_in) might come from a different clock domain;
// this assumes that the parameters are quasi-static and can be simply
// re-timed in the sf_clk domain
genvar r;
generate for (r=0; r<consts_len; r=r+1) begin : G_P_REGBANK
        always @(posedge sf_clk) begin // Retime
                p_regbank[r] <= param_in[(r+1)*pw-1: r*pw];
        end
end endgenerate

// Delay addrb to match dpram latency
reg [const_aw-1:0] rd_addr_r;
always @(posedge sf_clk) rd_addr_r <= rd_addr;

assign rd_data = p_regbank[rd_addr_r];  // This is a multiplexer


sf_user #(.pw(pw), .extra(extra), .mw(mw), .data_len(data_len),
        .consts_len(consts_len), .const_aw(const_aw))
sf_user (
        .clk(sf_clk), .ce(ce), .meas(meas), .trigger(trigger),
        .h_addr(rd_addr), .h_data(rd_data),
        .ab_update(ab_update), .a_o(a_o), .b_o(b_o),
        .cd_update(cd_update), .c_o(c_o), .d_o(d_o),
        .trace(trace), .trace_addr(trace_addr), .trace_strobe(trace_strobe),
        .sat_count(sat_count));

endmodule
