`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 06/26/2023 01:17:25 PM
// Design Name:
// Module Name: slow_bridge_tb
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module slow_bridge_tb;

localparam SIM_STOP=14000;
localparam cavity_count = 1;
localparam dw = 32;
localparam aw = 4;

integer cc, errors;
integer control_cnt=0;

reg lb_clk=0;
reg [dw-1:0] lb_data;
reg [aw-1:0] lb_addr;
reg lb_write=0, lb_read=0;
reg buf_transferred;
wire [dw-1:0] slow_bridge_out;
wire slow_op;
wire slow_invalid;
wire [dw-1:0] slow_out;

wire [dw-1:0] slow_data;

//
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("slow_bridge.vcd");
		$dumpvars(5,slow_bridge_tb);
	end

	for (cc=0; cc < SIM_STOP; cc=cc+1) begin
		lb_clk=0; #4;
		lb_clk=1; #4;
	end
	$display("PASS");
	$finish();
end

always @(posedge lb_clk) begin
    control_cnt <= control_cnt+1;
    buf_transferred <= 0;
    lb_addr <= 9'h00;

    if (control_cnt == 680) begin // || control_cnt == 750) begin
        buf_transferred <= 1;
        //lb_data <= 32'hx;
        //lb_addr <= 7'hx;
        //lb_write <= 0;
        //lb_read <= 0;
    end
end

    slow_bridge_NANC #(
        .dw(dw),
        .aw(aw)
    ) DUT(
        .lb_clk(lb_clk),                    // input
        .lb_addr(lb_addr),            // input
        .lb_out(slow_bridge_out),      //output
        // @slow_clk domain
        .slow_clk(lb_clk),                  // input
        .slow_op(slow_op),                  //output
        .slow_snap(buf_transferred),   // input
        .slow_invalid(slow_invalid),   //output
        .slow_out(slow_out)            // input
        );


    assign slow_data = slow_bridge_out;
    //assign slow_data_ready[c_n] = circle_data_ready[c_n] & ~slow_invalid_lb[c_n];
    `define SLOW_SR_DATA { 128'hdeadbeeffeedf00d0bed123456789abc }
    localparam sr_length = 128;
    reg [sr_length-1:0] slow_read=0;
    wire [dw-1:0] filler = 0;
    always @(posedge lb_clk)
    if (slow_op) begin
	   slow_read <= buf_transferred ? `SLOW_SR_DATA : {slow_read[sr_length-dw-1:0],filler};
    end

assign slow_out = slow_read[sr_length-1:sr_length-dw];
endmodule
