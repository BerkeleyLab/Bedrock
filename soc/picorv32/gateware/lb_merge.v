// Conflict merging table:
//  A  B  Merged  Policy
//
//  w  w  B_w     A will retry after B finish
//  r  r  B_r     A will retry after B finish
//  r  w  B_w     A will retry after B finish
//  w  r  B_r     A will hold

module lb_merge #(
	parameter READ_DELAY=3,
	parameter ADW=20
) (
	input clk,
	output collision,
    output busy,
	// Controlling bus A (CPU)
	input            lb_write_a,
	input            lb_read_a,
	input  [31:0]    lb_wdata_a,
	input  [ADW-1:0] lb_addr_a,
	output [31:0]    lb_rdata_a,
    input            lb_rvalid_a,
	// Controlling bus B (LB)
	input            lb_write_b,
	input            lb_read_b,
	input  [31:0]    lb_wdata_b,
	input  [ADW-1:0] lb_addr_b,
	output [31:0]    lb_rdata_b,
    input            lb_rvalid_b,
	// Controlled bus
	output           lb_merge_write,
	output           lb_merge_read,
	output [31:0]    lb_merge_wdata,
	output [ADW-1:0] lb_merge_addr,
	input  [31:0]    lb_merge_rdata,
    output           lb_merge_rvalid
);

assign lb_merge_read = lb_read_a | lb_read_b;
assign lb_merge_write = lb_write_a | lb_write_b;

wire select_write_a = lb_write_a & ~lb_write_b & ~lb_merge_read;
wire select_read_a  = lb_read_a  & ~lb_read_b & ~lb_merge_write;

wire lb_strobe_a = lb_write_a | lb_read_a;
wire lb_strobe_b = lb_write_b | lb_read_b;

assign collision = lb_strobe_a & lb_strobe_b;
assign busy = lb_strobe_b;
assign lb_merge_addr  = (select_write_a | select_read_a) ? lb_addr_a : lb_addr_b;
assign lb_merge_wdata = select_write_a ? lb_wdata_a : lb_wdata_b;

assign lb_rdata_a = lb_merge_rdata;
assign lb_rdata_b = lb_merge_rdata;
assign lb_merge_rvalid = lb_rvalid_a | lb_rvalid_b;

endmodule
