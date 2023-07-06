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

localparam SIM_STOP=4000;
localparam cavity_count = 2;
localparam dw = 8;  // not used
localparam aw = 9;
localparam dw_NANC = 32;
localparam aw_NANC = 9;
localparam RAM_SPACE_NANC = 2**aw_NANC;
localparam RAM_SPACE = 2**aw;
integer cc, dd, errors;
integer control_cnt=0;
localparam sr_length = 128;
integer idx; // need integer for loop

`define SLOW_SR_DATA { 128'hdeadbeeffeedf00d0bed123456789abc }

reg lb_clk=0;
reg [7:0] lb_data;
reg [14:0] lb_addr=0;
reg [14:0] lb_addr_NANC=0;
reg lb_write=0, lb_read=0;
reg buf_transferred;


//
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("slow_bridge.vcd");
		$dumpvars(5,slow_bridge_tb);
        for (idx = 0; idx < cavity_count; idx = idx + 1) begin
            $dumpvars(0, slow_bridge_out_NANC[idx]);
            $dumpvars(0, slow_data_NANC[idx]);
        end
	end

	for (cc=0; cc < SIM_STOP; cc=cc+1) begin
		lb_clk=0; #4;
		lb_clk=1; #4;
	end
	$display("PASS");
	$finish();
end


// instantiation of NANC block

wire [dw_NANC-1:0] slow_bridge_out_NANC[0:cavity_count-1];
wire [dw_NANC-1:0] slow_data_NANC[0:cavity_count-1];
wire [dw_NANC-1:0] filler_NANC = 0;

genvar c_n;
generate for (c_n=0; c_n < cavity_count; c_n=c_n+1) begin: cryomodule_cavity
    wire slow_op_NANC;
    wire slow_invalid_NANC;
    reg [sr_length-1:0] slow_read_NANC=0;
    wire [dw_NANC-1:0] slow_out_NANC;

    //
    slow_bridge_NANC #(
        .dw(dw_NANC),
        .aw(aw_NANC)
    ) DUT_NANC(
        .lb_clk(lb_clk),                    // input
        .lb_addr(lb_addr_NANC),            // input
        .lb_out(slow_bridge_out_NANC[c_n]),      //output
        // @slow_clk domain
        .slow_clk(lb_clk),                  // input
        .slow_invalid(slow_invalid_NANC),   //output
        .slow_op(slow_op_NANC),                  //output
        .slow_snap(buf_transferred),   // input
        .slow_out(slow_out_NANC)            // input
    );
    assign slow_data_NANC[c_n] = slow_bridge_out_NANC[c_n];

    always @(posedge lb_clk)
    if (slow_op_NANC) begin
	   slow_read_NANC <= buf_transferred ? `SLOW_SR_DATA : {slow_read_NANC[sr_length-dw_NANC-1:0], filler_NANC};
    end
    assign slow_out_NANC = slow_read_NANC[sr_length-1:sr_length-dw_NANC];

    always @(posedge lb_clk) begin
        if (control_cnt > 150 && ~slow_invalid_NANC) begin // || control_cnt == 750) begin
            if (lb_addr_NANC < RAM_SPACE_NANC) begin
                    lb_addr_NANC <= lb_addr_NANC + 1;
            end
        end
    end
end endgenerate



// instantiation of old 8bit block
wire slow_op;
wire [7:0] slow_bridge_out;
wire slow_invalid;
wire [7:0] slow_out;

slow_bridge DUT(
    .lb_clk(lb_clk),                    // input
    .lb_addr(lb_addr),            // input
    .lb_read(lb_read),
    .lb_out(slow_bridge_out),      //output
    // @slow_clk domain
    .slow_clk(lb_clk),                  // input
    .slow_op(slow_op),                  //output
    .slow_snap(buf_transferred),   // input
    //.slow_invalid(slow_invalid),   //output
    .slow_out(slow_out)            // input
);

reg [sr_length-1:0] slow_read=0;
wire [7:0] filler = 0;

always @(posedge lb_clk)
if (slow_op) begin
    slow_read <= buf_transferred ? `SLOW_SR_DATA : {slow_read[sr_length-9:0], filler};
end

assign slow_out = slow_read[sr_length-1:sr_length-8];
wire [7:0] slow_data = slow_bridge_out;


// TB
always @(posedge lb_clk) begin
    control_cnt <= control_cnt+1;
    buf_transferred <= 0;
    //lb_addr <= 15'h0000;

    if (control_cnt == 100) begin // || control_cnt == 750) begin
        buf_transferred <= 1;
        //lb_data <= 32'hx;
        //lb_addr <= 7'hx;
        //lb_write <= 0;
        //lb_read <= 0;
    end

    if (control_cnt > 150 && ~slow_invalid) begin // || control_cnt == 750) begin
    //if (control_cnt > 150) begin // && ~slow_invalid) begin // || control_cnt == 750) begin
            if (lb_addr < RAM_SPACE) begin
            lb_addr <= lb_addr + 1;
        end
    end
end

endmodule
