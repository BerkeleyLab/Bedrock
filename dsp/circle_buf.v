`timescale 1ns / 1ns

module circle_buf #(
	parameter dw=16,
	parameter aw=13,
	parameter stat_w=16, // Width of buffer statistics
	// For each half of the double-buffered memory, the default is to use a read of the last
	// memory location as acknowledgement that the buffer read is complete,
	// and read cycles need the stb_out signal set high to register.
	// Set this parameter to 0 to disable that feature, in which case you
	// need to construct the stb_out signal as a simple explicit flip command.
	parameter auto_flip = 1
) (
	// source side
	input          iclk,
	input [dw-1:0] d_in,
	input          stb_in,          // d_in is valid
	input          boundary,        // between blocks of input strobes
	input          stop,            // single-cycle
	                                // assume stop happens a programmable number of samples
	                                // after a fault event, and we will save 1024 samples
	                                // before the stop signal
	output         buf_sync,        // single-cycle when buffer starts/ends
	output         buf_transferred, // single-cycle when a buffer has been
	                                // handed over for reading;
	                                // one cycle delayed from buf_sync

	// readout side
	input                 oclk,
	output                enable,
	input  [aw-1:0]       read_addr, // nominally 8192 locations
	output [dw-1:0]       d_out,
	input                 stb_out,
	output [stat_w-1:0]   buf_count, // number of full buffer writes
	output [aw-1:0]       buf_stat2, // last valid location
	output [stat_w-1:0]   buf_stat,  // includes fault bit, and (if set) the last valid location
	output [aw+4:0]       debug_stat // {stb_in, boundary, btest, wbank, rbank, wr_addr}
);

`define MIN(a,b) a < b ? a : b

// parameterized to improve testability

// 8192 words of 16 bits, double buffered
// maybe subdivided into 1024 time samples of 4 RF waveforms,
// each with an I and Q component

// readout side state
reg rbank=0;  // really complement

// source side control logic
// Flow control is opposite that in decay_buf: the pacing happens
// from the readout side
wire flag_return;   // buffer request from readout side
wire flag_return_x;  // and converted to the iclk domain
reg_tech_cdc flag_return_cdc(.I(flag_return), .C(iclk), .O(flag_return_x));
reg [aw-1:0] write_addr=0, save_addr=0, save_addr0=0;
reg pend=0, run=1, wbank=0;
wire change_req = wbank ^ flag_return_x;
wire end_write_addr = &write_addr;
reg record_type=1;
reg boundary_ok=1;
reg [1:0] done_read = 2'b0;
wire stop_write=pend & boundary;
wire eval_done_read = stb_in & boundary_ok & end_write_addr;
wire eval_block=eval_done_read & change_req;
reg buff_wrap=0;
reg buf_transferred_r=0;
wire btest= boundary | ( stb_in & end_write_addr );
assign buf_transferred = buf_transferred_r;
always @(posedge iclk) begin
	if (eval_done_read) done_read[wbank] <= change_req;
	//if (boundary|(stb_in&end_write_addr)) boundary_ok <= boundary;
	if (btest) boundary_ok <= boundary;
	if (stb_in & boundary_ok) write_addr <= write_addr+1; //wbank==rbank ? 0 : write_addr+1;
	if (eval_block) begin
		run <= 1;
		wbank <= ~wbank;
		record_type <= run;  // fault (0) vs. comfort display (1)
		save_addr0 <= run ? {aw{1'b0}} : save_addr;
	end
	buf_transferred_r <= eval_block;
	if ((stop & run)| boundary) pend <= stop & run;  // ignore double stops
	if (stop_write) begin
		run <= 0;
		save_addr <= write_addr;
		buff_wrap <= ~done_read[wbank];
	end
end
wire flag_send=wbank;  // says "I want to write bank foo"
assign debug_stat={stb_in,boundary,btest,wbank,rbank,write_addr};
// Handshake means "OK, I won't read bank foo"

// readout side control logic
wire flag_send_x;
reg_tech_cdc flag_send_cdc(.I(flag_send), .C(oclk), .O(flag_send_x));
wire [aw-1:0] read0_addr = read_addr;  // cut down to current width
wire end_read_addr = &read0_addr;
assign enable = ~flag_send_x ^ rbank;
wire flip_buffer = stb_out & enable & (end_read_addr | ~auto_flip);
always @(posedge oclk) begin
	if (flip_buffer) rbank <= ~rbank;
end
assign flag_return = rbank;

// in iclk domain
wire [stat_w-2-1:0] save_addr0_ext = save_addr0[`MIN(stat_w-2,aw)-1:0]; // truncate or pad MSBs
assign buf_stat = {record_type, buff_wrap, save_addr0_ext};

assign buf_stat2 = save_addr0;
wire write_en= stb_in & boundary_ok & run;

// Count of how many buffers we have acquired
reg [stat_w-1:0] buf_count_r=0;
always @(posedge iclk) if (eval_done_read) buf_count_r <= buf_count_r+1;
assign buf_count=buf_count_r;
assign buf_sync=eval_done_read;

// data path is simply a dual-port RAM
dpram #(.aw(aw+1), .dw(dw)) cbuf(.clka(iclk), .clkb(oclk),
	.addra({wbank,write_addr}), .dina(d_in), .wena(write_en),
	.addrb({~rbank,read0_addr}), .doutb(d_out)
);

endmodule
