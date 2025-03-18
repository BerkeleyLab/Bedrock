// Simulator for a GTX (or similar) that has its input disconnected
// White noise, yes, but this covers the 16-bit data case where
// 8b/10b decoding has been enabled.
`timescale 1ns / 1ns
module gtx_noise(
	input clk,
	output [15:0] gtx_d,  // data
	output [1:0] gtx_k,  // charisk
	output [1:0] gtx_e,  // disperr
	output [1:0] gtx_n   // notintable
);
reg [9:0] white_noise=0;
reg white_disp=0;  // disparity
wire white_disp_loop;
// This is for simulation, and we want to send data through dec_8b10b twice
// per clock cycle to get 16 bits of data, so processing on both edges of cc_clk is fine.
always @(clk) begin
	white_noise <= $urandom;
	white_disp <= white_disp_loop;
end
wire [8:0] x_data;
wire x_code_err, x_disp_err;
dec_8b10b dec_8b10b_(.datain(white_noise), .dispin(white_disp),
	.dataout(x_data), .dispout(white_disp_loop),
	.code_err(x_code_err), .disp_err(x_disp_err));

// Need a half-cycle of history
reg [8:0] x_data_r=0;
reg x_code_err_r=0, x_disp_err_r=0;
always @(clk) begin
	x_data_r <= x_data;
	x_code_err_r <= x_code_err;
	x_disp_err_r <= x_disp_err;
end

// Rearrange and capture with GTX-friendly labels
reg [15:0] gtx_d_r=0;
reg [1:0] gtx_k_r=0, gtx_e_r=0, gtx_n_r=0;
always @(posedge clk) begin
	// I don't know if I have the two halves in the right order.
	// It probably doesn't matter.
	gtx_d_r <= {x_data_r[7:0], x_data[7:0]};
	gtx_k_r <= {x_data_r[8], x_data[8]};
	gtx_e_r <= {x_disp_err_r, x_disp_err};
	gtx_n_r <= {x_code_err_r, x_code_err};
end
assign gtx_d = gtx_d_r;
assign gtx_k = gtx_k_r;
assign gtx_e = gtx_e_r;
assign gtx_n = gtx_n_r;

endmodule
