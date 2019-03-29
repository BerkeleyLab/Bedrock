// 8b9b receiver based on an SDR ISERDES implementation
// First it is sync, then 8 data, if first bit is 1'b0 then another byte,
	// is present in the frame.
	// e.g.
	// 1111111 [0]XXXXXXXX [0]XXXXXXXX [1]
	// Would be a two-byte frame
	//

module oversampling_rx_8b9b (async_reset,enable, clk, clk_4x, serdes_strobe, data_in, word_out, word_write,frame_complete);
parameter dbg="true";
parameter DEVICE="KINTEX 7";
parameter WORD_WIDTH=8;
// mark async_reset as inout for compatibility with ISERDES pulldown
inout async_reset;// Async reset for ISERDES
input enable;// Enable input
(* mark_debug = dbg *)
input clk;// Output clock rate
input clk_4x;// Receive SDR clock rate (x4)
input serdes_strobe;
input data_in;// Serial data in
output reg [WORD_WIDTH-1:0] word_out=0;// Parallel data out
output reg word_write=0;
output reg frame_complete=0;

reg int_bit=1'b0;
wire sync_reset;
wire inv_clk_4x;
reg n_start_detect=0;
//reg [3:0] pre_int_data=4'b1111,
reg [3:0] r_int_data=4'b1111, int_data=4'b1111;
wire [3:0] pre_int_data;// r_int_data, int_data;
parameter IDLE=2'b00,ONCE=2'b01,RECEIVE=2'b10,COMMIT=2'b11;
reg [1:0] state=IDLE;
reg [1:0] int_latch_point=0, latch_point=0;
reg [WORD_WIDTH-1:0] int_result=0;
reg [2:0] bit_counter=0;
assign  inv_clk_4x = ~(clk_4x);
`ifdef SIMULATE
	// Bare-bones model of 1:4 SerDes retimed to parallel clk
	reg [3:0] d_in, d_out;
	always @(clk_4x or async_reset) begin
		if (async_reset)
			d_in <= 0;
		else
			d_in <= {d_in[2:0], data_in};
	end
        always @(clk or async_reset) begin
		if (async_reset)
			d_out <= 0;
		else if (serdes_strobe)
			d_out <= d_in;
	end

	assign pre_int_data[0] = d_out[3];
	assign pre_int_data[1] = d_out[2];
	assign pre_int_data[2] = d_out[1];
	assign pre_int_data[3] = d_out[0];
`else
generate
if (DEVICE == "SPARTAN 6") begin // ISERDES2 receiver
	wire bitslip=0;
	ISERDES2 #(.BITSLIP_ENABLE("FALSE"),.DATA_RATE("SDR"),.DATA_WIDTH(4),.INTERFACE_TYPE("RETIMED"),.SERDES_MODE("NONE") )
	inst_iserdes(.CE0(1'b1),.CLKDIV(clk),.CLK0(clk_4x),.D(data_in),.RST(async_reset),.Q4(pre_int_data[3]),.Q3(pre_int_data[2]),.Q2(pre_int_data[1]),.Q1(pre_int_data[0]),.BITSLIP(bitslip),.CFB0(),.CFB1(),.CLK1(1'b0),.DFB(),.FABRICOUT(),.INCDEC(),.IOCE(serdes_strobe),.SHIFTIN(1'b0),.SHIFTOUT(),.VALID());
end
else  if (DEVICE == "KINTEX 7") begin// ISERDESE2 receiver
	ISERDESE2 #(.DATA_RATE("SDR"),.DATA_WIDTH(4),.INTERFACE_TYPE("NETWORKING"),.IOBDELAY("NONE"),.NUM_CE(1'b1)
	,.INIT_Q1(0)
	,.INIT_Q2(0)
	,.INIT_Q3(0)
	,.INIT_Q4(0)
	,.SRVAL_Q1(0)
	,.SRVAL_Q2(0)
	,.SRVAL_Q3(0)
	,.SRVAL_Q4(0)
)
	inst_iserdes (.CLK(clk_4x),.CLKB(inv_clk_4x),.CLKDIV(clk),.D(data_in),.Q4(pre_int_data[0]),.Q3(pre_int_data[1]),.Q2(pre_int_data[2]),.Q1(pre_int_data[3]),.RST(async_reset),.CLKDIVP(1'b0),.CE1(1'b1),.CE2(1'b0),.OCLK(1'b0),.OCLKB(1'b0),.BITSLIP(1'b0),.SHIFTIN1(1'b0),.SHIFTIN2(1'b0),.OFB(1'b0),.DYNCLKSEL(1'b0),.DYNCLKDIVSEL(1'b0),.DDLY(1'b0),.O());
end
endgenerate
`endif
// int_data(0) is first to arrive, int_data(3) is last
always @(posedge clk) begin
	int_data <= pre_int_data;
	// Start is when the line goes low
	n_start_detect <= int_data[0]& int_data[1]&int_data[2]&int_data[3];
	// Based on the start detect point we step one cycle later in time and latch
	// there...
	int_latch_point <= ~int_data[0] ? 2'b01:
	~int_data[1] ? 2'b10:
	~int_data[2] ? 2'b11:
	2'b00;
// Retime to 'flatten' data into a single cycle as latch point "00" is a
// cycle out of time relative to the other three
r_int_data <= int_data ;
int_bit    <= latch_point==2'b00 ? int_data[0]:
	latch_point==2'b01 ? r_int_data[1]:
	latch_point==2'b10 ? r_int_data[2]:
	r_int_data[3];
end
// Hold the reset for the receiver after the ISERDES is reset for a
// few cycles to allow it to initialise
async_to_sync_reset_shift #(.LENGTH(4))
inst_sync_reset_gen (.clk(clk),.Pinput(async_reset),.Poutput(sync_reset));

always @(posedge clk)
begin
	if (sync_reset)  begin
		word_write <= 1'b0;
	end
	else begin
		word_write     <= 1'b0;
		frame_complete <= 1'b0;

		case (state)
			IDLE : begin// Check for start bit
				if ((enable) & (~n_start_detect)) begin
					latch_point <= int_latch_point;
					bit_counter <= $unsigned(WORD_WIDTH-1);//, next_highest_power_of_two(WORD_WIDTH));
					state       <= ONCE;
				end
			end
			ONCE: begin
				state <= RECEIVE;
			end
			RECEIVE: begin// Copy the bits into the receive register and shift// More efficient than using a counter index
				bit_counter <= bit_counter - 1;
				int_result  <= {int_bit , int_result[WORD_WIDTH-1:1]};
				if (bit_counter==0) begin
					state <= COMMIT;
				end
			end
			COMMIT:begin// Check to see if the frame is complete
				word_out   <= int_result;
				word_write <= 1'b1;// If the 9th bit is 1'b0 then the frame isn't complete
				bit_counter <= $unsigned(WORD_WIDTH-1);//, next_highest_power_of_two(WORD_WIDTH));
				state       <= RECEIVE;
				if (int_bit) begin
					state          <= IDLE;
					frame_complete <= 1'b1;
				end
			end
			default:
				state <= IDLE;
		endcase
	end
end
endmodule
