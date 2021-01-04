module i2c_prog(
	input clk,
	// attachment to i2c_bit
	output [1:0] bit_cmd,
	input bit_adv,
	input sda_h,
	// attachment to program memory
	output [9:0] p_addr,
	input [7:0] p_data,
	// Result port
	output [7:0] result,
	output [9:0] result_addr,
	output result_stb,
	// other control and status
	input run_cmd,
	output run_stat,
	output [3:0] hw_config,
	output buffer_flip,
	output trig_analyz
);

parameter q1 = 2;  // o_p1 ticks are 2^(q1+1) * bit_adv
parameter q2 = 7;  // o_p2 ticks are 2^(q2+1) * bit_adv

// Most fundamental state bit: are we running or not?
reg run_stat_r=0, run_cmd_d1=0, run_cmd_d2=0;
wire start_me_up = run_cmd_d1 & ~run_cmd_d2;
wire ok_to_stop, natural_stop;  // defined later
wire stop_now = ~run_cmd_d1 & ok_to_stop | natural_stop;
always @(posedge clk) if (bit_adv) begin
	run_cmd_d1 <= run_cmd;  // remove all doubt about clock domains
	run_cmd_d2 <= run_cmd_d1;
	if (start_me_up) run_stat_r <= 1;
	if (stop_now) run_stat_r <= 0;
end
assign run_stat = run_stat_r;

// State variable
reg [2:0] state=0;
localparam s_idle  = 0;
localparam s_start = 1;  // start bit for data transfer instructions, idle for others
localparam s_data  = 2;
localparam s_ack   = 3;
localparam s_pad   = 4;
localparam s_stop  = 5;

// Opcode and encoding
reg [2:0] opcode=0;
reg [4:0] stream_cnt=0;
wire o_oo = opcode==0;  // special functions, including sleep
wire o_rd = opcode==1;  // read
wire o_wr = opcode==2;  // write
wire o_wx = opcode==3;  // write followed by repeated start
wire o_p1 = opcode==4;  // pause (time quantum 1)
wire o_p2 = opcode==5;  // pause (time quantum 2)
wire o_jp = opcode==6;  // jump
wire o_sx = opcode==7;  // set result address

wire op_r = opcode==1;
wire op_w = ~opcode[2] & opcode[1];
wire op_xf = o_rd | o_wr | o_wx;
wire op_pw = o_p1 | o_p2;  // any pause command
wire op_zz = o_oo & (stream_cnt==0);  // sleep
wire op_bf = o_oo & (stream_cnt==2);  // buffer flip
wire op_ta = o_oo & (stream_cnt==3);  // trigger logic analyzer
wire op_hw = o_oo & (stream_cnt[4]);  // hardware config
wire op_ia = op_pw | o_jp | op_zz;  // any interrupt-able command

// Base state machine
wire bit_end, stream_end;
always @(posedge clk) if (bit_adv) case(state)
	s_idle:  if (start_me_up) state <= s_start;
	s_start: state <= stop_now ? s_idle : op_xf ? s_data : s_start;
	s_data:  if (bit_end) state <= s_ack;
	s_ack:   state <= s_pad;
	s_pad:   if (stream_end) state <= o_wx ? s_start : s_stop; else state <= s_data;
	s_stop:  state <= s_start;
endcase
//
assign ok_to_stop = op_ia & (state==s_start);
assign natural_stop = op_zz & (state==s_idle);


// Manipulate secondary state, notably bit_cnt, opcode, and stream_cnt
reg [2:0] bit_cnt=0;
assign bit_end = bit_cnt == 0;
assign stream_end = stream_cnt == 0;
reg stream0=0, stream1=0;
wire rd_cycle = o_rd & ~stream1;
wire wr_cycle = op_w | (o_rd & stream1);  // during data transfers
wire wr_cycle0 = op_w | (o_rd & stream0);  // during initial start pulse
reg [9:0] pc=0;  // program counter
reg [7:0] sr=0;  // data shift register
wire next_data =
	((state==s_start) & op_xf) |
	((state==s_pad) & ~stream_end);
wire next_op =
	((state==s_pad) &  stream_end & o_wx) |
	((state==s_stop)) |
	((state==s_idle)) |
	((state==s_start) & op_pw & stream_end) |
	((state==s_start) & o_jp) |
	((state==s_start) & o_sx) |
	((state==s_start) & op_bf) |
	((state==s_start) & op_ta) |
	((state==s_start) & op_hw);
wire [7:0] next_sr = (sr << 1) | sda_h;
reg [7:0] pause_cnt=0;
reg [9:0] next_pc=0;
reg pause1_tick=0, pause2_tick=0;
always @(posedge clk) if (bit_adv) begin
	pause_cnt <= pause_cnt+1;  // free-running
	pause1_tick <= &pause_cnt[q1:0];
	pause2_tick <= &pause_cnt[q2:0];
	if (next_data) begin
		bit_cnt <= 7;
		stream_cnt <= stream_cnt - 1;
		stream0 <= 0;
		stream1 <= stream0;
		if (wr_cycle0) begin
			sr <= p_data;
			pc <= next_pc;
		end
	end
	//if ((state==s_data) & ~bit_end) begin
	if (state==s_data) begin
		sr <= next_sr;
		bit_cnt <= bit_cnt - 1;
	end
	if (o_p1 & pause1_tick | o_p2 & pause2_tick) begin
		stream_cnt <= stream_cnt - 1;
	end
	if (next_op) begin
		opcode <= p_data[7:5];
		stream_cnt <= p_data[4:0];
		stream0 <= 1;
		stream1 <= 0;
		pc <= next_pc;
	end
end

// Special cases
reg [9:0] result_addr_r=0;
reg [3:0] hw_config_r=0;
reg result_incr_pend=0;
wire result_incr_sel = (state==s_ack) & rd_cycle;
always @(posedge clk) begin
	next_pc <= ~run_stat_r ? 10'b0 : o_jp ? {stream_cnt, 5'b0} : pc + 1;
	if (bit_adv) result_incr_pend <= result_incr_sel;
	if (bit_adv & result_incr_pend) result_addr_r <= result_addr + 1;
	if (bit_adv & o_sx) result_addr_r <= {stream_cnt, 5'b0};
	if (bit_adv & op_hw) hw_config_r <= stream_cnt[3:0];
end

// Decoder; see i2c_bit.v
//  bit_cmd semantics    0: Tx0   1: Tx1   2: L   3: H
wire data_bit = rd_cycle ? 1'b1 : sr[7];
wire ack_bit = rd_cycle ? stream_end : 1'b1;
wire [1:0] pad_wr = stream_end ? 2'b00 : 2'b11;
wire [1:0] pad_wx = stream_end ? 2'b01 : 2'b11;
wire [1:0] pad_rd = stream_end ? 2'b00 : 2'b10;
reg [1:0] bc;
always @(posedge clk) case(state)
	s_idle:  bc <= 2'b11;  // H
	s_start: bc <= op_xf ? 2'b10 : 2'b11;  // L or H
	s_data:  bc <= {1'b0, data_bit};
	s_ack:   bc <= {1'b0, ack_bit};
	s_pad:   bc <= o_rd ? pad_rd : o_wx ? pad_wx : pad_wr;
	s_stop:  bc <= 2'b11;  // H
endcase

assign p_addr = next_pc;
assign bit_cmd = bc;
assign result_stb = bit_adv & result_incr_sel;
assign result = next_sr;  // result_stb ? next_sr : 8'bx;
assign result_addr = result_addr_r;
assign buffer_flip = op_bf & bit_adv;
assign trig_analyz = op_ta & bit_adv;
assign hw_config = hw_config_r;

// Future additions?
//  Raw send (4)
//  Skip on interrupt
//  PDP-5 opcodes?
//    000  and  Logical AND
//    001  tad  Twos complement add
//    010  isz  Index and skip if zero
//    011  dca  Deposit and clear accumulator
//    100  jms  Jump to subroutine
//    101  jmp  Jump
//    110  iot  Input/output transfer
//    111  opr  Operate: rotate, clear, increment, conditional skip, halt

endmodule
