`timescale 1ns / 1ns

// 2.5 MHz max clk (400 ns period)
// DP83865 samples data on rising edge (+/- 10 ns) of MDC, and changes
// output state at (or up to 300 ns after) rising edge of MDC.
//
// 32-bit hi-Z preamble
// 01 start
// 10 read
// AAAAA phy address
// RRRRR reg address
// zz turnaround
// dddddddddddddddd  read data
// zz minimum idle/turnaround
//
// 01 start
// 01 write
// AAAAA phy address
// RRRRR reg address
// 10 pad
// dddddddddddddddd  write data
// zz minimum idle/turnaround
//
// We want to, in order:
//   1.  Sample MDIO
//   2.  wait 1 clock
//   3.  Rising edge MDC
//   4.  wait 2 clocks
//   5.  New value and driver state for MDIO
//
// Every 64 ticks, 40.96 microseconds, get a new value
// Two modules, producing 32 bits every 40.96 microseconds, avg 0.097 MB/s

module mii(
	input clk,
	output MDC,
	inout MDIO,
	output strobe,
	output [4:0] addr,
	output [15:0] data,
	output led,
	input do_write
);

reg [5:0] div=0;
reg tick=0, mdio_in=0;
reg force_write=1'b0;
always @(posedge clk) begin
	div <= div+1;
	tick <= &div;
	mdio_in <= MDIO;
	if(do_write | write_done_pos) force_write <= do_write;
end

reg [15:0] shift_rd=0, recv=0;
reg shift_wr=1'b0;
reg mdio_drive_wr=0, mdio_drive_rd=0;

wire [4:0] phy_addr = 5'b00111;
wire [4:0] config_reg_addr_22 = 5'b10110;  // Register 22 (lower 4 bits indicate page number of the control register, set to 1 for fiber)
wire [4:0] config_reg_addr_01 = 5'b00000;  // Control register (address=0). If register 22 is set to 1, then control corresponds to fiber link
reg [4:0] reg_addr = 0, reg_outr=0;

reg [5:0] rvd_reg_01=6'b0;   // Reserved bits in register 0 (control) page 1 (fiber link)
reg rvd_reg_01_read_done=1'b0;

wire [15:0] send_read  = {2'b01, 2'b10, phy_addr, reg_addr, 2'b00};       // Read configuration register @ (reg_addr)
wire [15:0] config_reg_22 = 16'b0001;                                     // Configuration word for register 22 (1=set control to fiber link)
wire [15:0] config_reg_01 =  {1'b0, 6'b0, 1'b1, 1'b0, 1'b1, rvd_reg_01};  // Disable fiber Auto-Negotiation (write 0 on bit 20.3)

wire [31:0] send_write1 = {2'b01, 2'b01, phy_addr, config_reg_addr_22, 2'b10,config_reg_22};
wire [31:0] send_write2 = {2'b01, 2'b01, phy_addr, config_reg_addr_01, 2'b10,config_reg_01};

reg [5:0] state=0;
wire state_33 = (state==6'd33);
wire state_0 = (state==0);
reg rd_wr=1'b0;         // 1=write, 0=read
reg config_cntl=1'b0;   // 1=config, 0=control
reg write_done_r=1'b0, write_done_d=1'b0, write_done_pos=1'b0, force_write_tick=1'b0;
always @(posedge clk) if (tick) begin
	state <= state + 1'b1;
	mdio_drive_wr <= state<31;
	mdio_drive_rd <= state<14;
	shift_rd <= state_0 ? send_read : {shift_rd[14:0], mdio_in};
	shift_wr <= (state<32) ? (~config_cntl ? send_write1[31-state] : send_write2[31-state]) : 1'b0;
	force_write_tick <= force_write;
	write_done_d <= write_done_r;
	write_done_pos <= write_done_r & ~write_done_d;
	if (state_33) recv <= shift_rd;
	// Read reserved bits in register 0 (control) page 1 (fiber link), and use to over-write that register
	// Re-writing configuration word with different values for the reserved bits may alter PHY's behavior
	if(state_33 & (reg_addr==0)) begin
		rvd_reg_01 <= shift_rd[5:0];
		rvd_reg_01_read_done <= 1'b1;
	end
	// Sweep address to read all configuration registers
	if (state_33) reg_outr <= reg_addr;
	if (state_33) reg_addr <= reg_addr+1;
	if ((state==63) & (reg_addr==31)) begin
		rd_wr <= ~rd_wr;    // Alternate read and write
	// When read is forced (pulse on do_write input) writes are done on configuration 22 to set page to 1 (see config_reg_22),
	// and disable Auto-negotiation (see config_reg_01)
		if(force_write_tick & ~rd_wr) begin
			write_done_r <= 1'b1;
			config_cntl <= 1'b1;
		end
		if((rd_wr==1'b1) & (config_cntl==1'b1)) begin
			config_cntl <= 1'b0;
			write_done_r <= 1'b0;
		end
	end
end

reg strobe_r=0, mdio_state=0, mdio_drive2=0;
always @(posedge clk) begin
	strobe_r <= tick & (state==34) & ~rd_wr;
	mdio_state <= rd_wr ? shift_wr : shift_rd[15];
	mdio_drive2 <= rd_wr ? mdio_drive_wr : mdio_drive_rd;
end
assign strobe = strobe_r;
assign MDC  = ~div[5];  // XXX doesn't scale
assign MDIO = mdio_drive2 ? mdio_state : 1'bz;

assign data = recv;
assign addr = reg_outr;

assign led=state_33;

endmodule
