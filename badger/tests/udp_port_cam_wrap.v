// Synthesis wrapper, only useful for checking synthesizability
// and resource usage
module udp_port_cam_wrap(
	input clk,
	input port_s,
	input [7:0] data,
	// Write-only access to config memory
	input pno_ws,  // write-strobe
	input [3:0] pno_wa,
	input [7:0] pno_wd,
	// Results - a port pointer
	output [naw-1:0] port_p,
	output port_h,  // port_p is meaningful (hit)
	output port_v  // timing only: above two results are in
);

// Module under investigation
localparam naw=3;
wire [naw:0] pno_a;
reg [7:0] pno_d=0;
udp_port_cam #(.naw(naw)) dut(.clk(clk),
	.port_s(port_s), .data(data),
	.pno_a(pno_a), .pno_d(pno_d),
	.port_p(port_p), .port_h(port_h), .port_v(port_v)
);

// Memory for UDP port numbers
reg [7:0] number_mem[0:15];
always @(posedge clk) begin
	pno_d <= number_mem[pno_a];
	if (pno_ws) number_mem[pno_wa] <= pno_wd;
end

endmodule
