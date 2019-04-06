// Simple wrapper from mem_gatway.v to the compatibilities of:
// - newad.py
// - picorv32 memory bus bridge
// - xilinx DRP bridge
// - potential axi-lite/wishbone bridge
module lb_gateway #(
    parameter n_lat        =8,
    parameter READ_PIPE_LEN=3
) (
    input         clk,   // timespec 6.8 ns
    // client interface with RTEFI, see clients.eps
    input  [10:0] len_c,
    input  [ 7:0] idata,
    input         raw_l,
    input         raw_s,
    output [ 7:0] odata,
    // local bus master
    output        lb_clk,
    output [23:0] lb_addr,
    output        lb_write,
    output        lb_read,
    output        lb_rvalid,
    output        lb_pre_rvalid,
    output [31:0] lb_wdata,
    input  [31:0] lb_rdata
);

wire control_strobe, control_rd;

mem_gateway #(
    .n_lat          (n_lat),
    .read_pipe_len  (READ_PIPE_LEN)
) mem_gateway_i (
    .clk             (clk),
    .len_c           (len_c),
    .idata           (idata),
    .raw_l           (raw_l),
    .raw_s           (raw_s),
    .odata           (odata),
    .addr            (lb_addr),
    .control_strobe  (control_strobe),
    .control_rd      (control_rd),
    .control_rd_valid(lb_rvalid),
    .data_out        (lb_wdata),
    .data_in         (lb_rdata)
);

assign lb_clk    = clk;
assign lb_write  = control_strobe && !control_rd;
assign lb_read   = control_rd;

reg_delay #(.len(READ_PIPE_LEN-1), .dw(1)) sync (
    .clk(lb_clk), .gate(1'b1), .reset(1'b0),
	.din(lb_read), .dout(lb_pre_rvalid)
);
endmodule
