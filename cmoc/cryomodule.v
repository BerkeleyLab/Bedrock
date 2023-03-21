`timescale 1ns / 1ns

`define LB_DECODE_cryomodule

`define AUTOMATIC_decode
`define AUTOMATIC_map
`define AUTOMATIC_beam
`define AUTOMATIC_cavity
`define AUTOMATIC_llrf
`define AUTOMATIC_cav_mech
`define AUTOMATIC_tgen
`include "cryomodule_auto.vh"

// Combination of LLRF controller and cavity emulator.
// Portable Verilog, interfaces to a host via an abstract local bus.

// Three clock domains, with the three clocks passed to this module:
//   lb_clk  e.g., 125 MHz Ethernet
//   clk1x   ADC clock of controller, e.g., 94 MHz for LCLS-2
//   clk2x   double-speed clock used by cavity simulator
// Proper data hand-off between clock domains is handled here.

// In an XC7A part, synthesizes to 18132 LUT, 10 RAMB36E1, 9 RAMB18E1, 51 DSP48E1
// Has some "issues" making reasonable timing in the clk2x domain

// 16-bit (0 to 7fff) address map
// write:
//      0 to 3fff   LLRF controller 1, see llrf_shell.v
//        (use addresses in llrf_shell block of addr_map.vh,
//        and maybe the registers listed in fgen.v and tgen.v)
//   3800           Trigger changeover to next circle_buf_0
//   3801           Trigger changeover to next circle_buf_0
//   4000 to 7fff   LLRF controller 2, see llrf_shell.v
//        (use addresses in llrf_shell block of addr_map.vh,
//        and maybe the registers listed in fgen.v and tgen.v)
//   8000 to ffff   Simulator, see vmod1.v
//        (add 4000 to addresses in vmod1 block of addr_map.vh)
// read:
//  10000 to 1003f   Configuration and parameter ROM, and circle buffer ready flag
//        (see config_romx.v makefile target for bits [7:0]; the ready
//        flag is bit 8)
//  12000 to 121ff   Slow readout, see slow_bridge.v
//        (see slow_larger.list makefile target for the contents)
//  12200 to 123ff   Slow readout, see slow_bridge.v
//        (see slow_larger.list makefile target for the contents)
//  14000 to 15fff   Circular buffer
//        (16-bit signed, usually 8 channels per time step and 1024 time
//        steps, when ch_keep has 8 of 12 bits set)
//  16000 to 17fff   Circular buffer
//        (16-bit signed, usually 8 channels per time step and 1024 time
//        steps, when ch_keep has 8 of 12 bits set)
// Reads are generally passive; the exception is address 5fff, which
// signals that the reading of one buffer is complete so the double-buffer
// logic and flip and make the next one available.

// `define SIMPLE_DEMO  // Used to get a 5-minute bitfile build
module cryomodule(
	input clk1x,
	input clk2x,
	// Local Bus drives both simulator and controller
	// Simulator is in the upper 16K, controller in the lower 16K words.
	input lb_clk,
	input [31:0] lb_data,
	input [16:0] lb_addr,
	input lb_write,  // single-cycle causes a write
	input lb_read,
	output [31:0] lb_out
);
wire [31:0] clk1x_data;
wire [16:0] clk1x_addr;
wire clk1x_write;
wire clk1x_clk;
wire [31:0] clk2x_data;
wire [16:0] clk2x_addr;
wire clk2x_write;
wire clk2x_clk, clk;
assign clk2x_clk = clk2x;
assign clk=clk2x;
wire [31:0] lb2_data[0:cavity_count];
wire [16:0] lb2_addr[0:cavity_count];
wire lb2_write[0:cavity_count];

wire [31:0] lb1_data[0:cavity_count];
wire [16:0] lb1_addr[0:cavity_count];
wire lb1_write[0:cavity_count];
wire lb2_clk = clk1x;
`AUTOMATIC_decode
`AUTOMATIC_map
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
`define UNIFORM(x) ((~|(x)) | &(x))  // All 0's or all 1's

// Note that the following five parameters should all be in the range 0 to 255,
// in order to be properly read out via config_data0, below.
parameter circle_aw = 13; // each half of ping-pong buffer is 8K words
// .. but also allows for testing
// The next four parameters are all passed to vmod1
parameter mode_count = 3;  // drives generate loop in cav_elec.v
parameter mode_shift = 9;
parameter n_mech_modes = 7;
parameter df_scale = 9;
parameter cavity_count = 2;
parameter cavity_ln = 1;  // ceil(log2(cavity_count))

parameter n_cycles = n_mech_modes * 2;
parameter interp_span = 4;  // ceil(log2(n_cycles))
`define SLOW_SR_LEN 4*8
parameter sr_length = `SLOW_SR_LEN;

`ifndef SIMPLE_DEMO
// Transfer local bus to clk2x domain
data_xdomain #(.size(32+17)) lb_to_2x(
.clk_in(lb_clk), .gate_in(lb_write), .data_in({lb_addr,lb_data}),
.clk_out(clk2x), .gate_out(clk2x_write), .data_out({clk2x_addr,clk2x_data}));
// Transfer local bus to clk1x domain
data_xdomain #(.size(32+17)) lb_to_1x(
.clk_in(lb_clk), .gate_in(lb_write), .data_in({lb_addr,lb_data}),
.clk_out(clk1x), .gate_out(clk1x_write), .data_out({clk1x_addr,clk1x_data}));
`endif // SIMPLE_DEMO

// Create start pulses at configured interval
reg start=0;
reg [7:0] mech_cnt=0;
always @(posedge clk2x) begin
   mech_cnt <= mech_cnt==0 ? n_cycles-1 : mech_cnt-1;
   start <= mech_cnt == 0;
end
wire start_outer;
reg_delay #(.dw(1), .len(0))
	start_outer_g(.clk(clk2x), .reset(1'b0), .gate(1'b1), .din(start), .dout(start_outer));
wire start_eig;
reg_delay #(.dw(1), .len(1))
	start_eig_g(.clk(clk2x), .reset(1'b0), .gate(1'b1), .din(start), .dout(start_eig));

// Arrays for the generate loop
wire signed [17+cavity_ln:0] cav_eig_drive_acc[0:cavity_count];
assign cav_eig_drive_acc[0]=0;
wire signed [17+cavity_ln:0] piezo_eig_drive_acc[0:cavity_count];
assign piezo_eig_drive_acc[0]=0;
wire signed [15:0] circle_out[0:cavity_count];
wire [7:0] slow_bridge_out[0:cavity_count];
wire [cavity_count-1:0]circle_data_ready;
wire [cavity_count-1:0]slow_data_ready;

wire [7:0] clips;  // XXX decide on a way to read this out
wire signed [17:0] mech_x;
wire simple_demo_flag;
// decode this address by hand
reg [2:0] cbuf_mode=0;
// XXX cbuf_mode should really be generated in clk1x domain, but it doesn't
// actually change that often
//always @(posedge lb_clk) if (lb_write & (lb_addr == 554)) cbuf_mode <= lb_data;
always @(posedge lb_clk) if (lb_write & (lb_addr == 17'h1022a)) cbuf_mode <= lb_data;

genvar cavity_n;
generate for (cavity_n=0; cavity_n < cavity_count; cavity_n=cavity_n+1) begin: cryomodule_cavity
   reg signed [17:0] drive2=0; reg iq2=1;  // computed later
   //wire [3:0] beam_timing=0;  // XXX for simulator
   wire signed [17:0] piezo_ctl;  // controller output
   wire signed [15:0] a2_field, a2_forward, a2_reflect;  // simulator output

   reg signed [15:0] a_field=0, a_forward=0, a_reflect=0;
   wire signed [17:0] drive; wire iq;
   // Waveform data from llrf
   wire [19:0] mon_result;
   wire mon_strobe, mon_boundary;
   wire buf_sync; // temporarily route to llrf_shell trig
   reg [15:0] buf_data=0;
   reg buf_strobe=0, buf_bound=0;
`ifndef SIMPLE_DEMO
   // Beam timing generator
   // beam_timing output is limited to [0,phase_step].
   wire [11:0] beam_timing;
   (* lb_automatic, gvar="cavity_n", gcnt=2, cd="clk2x" *)
   beam beam  // auto(cavity_n,2) clk2x
     (.clk(clk2x), .ena(iq), .reset(1'b0), .pulse(beam_timing),
      `AUTOMATIC_beam);
   // Instantiate simulator in clk2x domain
   wire signed [17:0] cav_eig_drive;
   wire signed [17:0] piezo_eig_drive;
   // Parameter settings here should be mirrored in param.py
   // Instantiating the Station module here:
   (* lb_automatic, gvar="cavity_n", gcnt=2, cd="clk2x" *)
   station #(.mode_count(mode_count), .mode_shift(mode_shift), .n_mech_modes(n_mech_modes), .df_scale(df_scale)) cavity // auto(cavity_n,2) clk2x
     (.clk(clk2x),
      .beam_timing(beam_timing), .mech_x(mech_x), .cav_eig_drive(cav_eig_drive),
      .piezo_eig_drive(piezo_eig_drive), .start_outer(start_outer),
      .iq(iq2), .drive(drive2), .start(start), .piezo(piezo_ctl),
      .a_field(a2_field), .a_forward(a2_forward), .a_reflect(a2_reflect),
      // TODO: These `we_*` wires below, are taken from the decode signals that are auto generated
      //.we_prng_iva(we_cavity_0_prng_iva), .we_prng_ivb(we_cavity_0_prng_ivb),
      `AUTOMATIC_cavity
      );

   assign cav_eig_drive_acc[cavity_n+1] = cav_eig_drive_acc[cavity_n] + cav_eig_drive;
   assign piezo_eig_drive_acc[cavity_n+1] = piezo_eig_drive_acc[cavity_n] + piezo_eig_drive;

   // Transfer ADCs to clk1x domain
   always @(posedge clk1x) begin
      a_field <= a2_field;
      a_forward <= a2_forward;
      a_reflect <= a2_reflect;
   end
   // Instantiate circular buffer
   // Reading from 0xfff is magic, says we are done reading a bank
   wire [15:0] circle_count, circle_stat;
   wire circle_stop=0; // not used
   //wire circle_stb = lb_read & lb_addr[14:13]==2'b10;
   wire buf_transferred;

   // 0x4000 to 0x5fff for cavity 0
   // 0x6000 to 0x7fff for cavity 1
   // TODO: To be modified for cavity_count > 2
   wire buf_read = lb_read & (lb_addr[16:14] == 3'b101) & (lb_addr[13]==cavity_n);
   wire buf_flip = lb_write & (lb_addr == (17'h13800 + cavity_n));  // in lb_clk domain
   circle_buf #(.aw(circle_aw), .auto_flip(0)) circle(
	.iclk(clk1x),
	.d_in(buf_data), .stb_in(buf_strobe), .boundary(buf_bound),
	.stop(circle_stop), .buf_sync(buf_sync),
	.buf_transferred(buf_transferred),
	.oclk(lb_clk), .enable(circle_data_ready[cavity_n]),
	.read_addr(lb_addr[circle_aw-1:0]), // .read_strobe(buf_read),
	.d_out(circle_out[cavity_n]), .stb_out(buf_flip),
	.buf_count(circle_count), .buf_stat(circle_stat));

   // Bridge slow readout subsystem to the local bus
   wire slow_op, slow_invalid;
   reg slow_snap=0; always @(posedge clk1x) slow_snap<=buf_sync;
   wire [7:0] slow_out;
   // 0x2000 to 0x21ff for cavity 0
   // 0x2200 to 0x23ff for cavity 1
   // Should be good upto 16 cavities
   wire lb_slow_read = lb_read & (lb_addr[16:9] == 'b10010000 + cavity_n);
   slow_bridge slow_bridge(.lb_clk(lb_clk), .lb_addr(lb_addr[14:0]),
			   .lb_read(lb_slow_read), .lb_out(slow_bridge_out[cavity_n]),
			   .invalid(slow_invalid),
			   .slow_clk(clk1x), .slow_op(slow_op), .slow_snap(buf_transferred),
			   .slow_out(slow_out));
   assign slow_data_ready[cavity_n] = circle_data_ready[cavity_n] & ~slow_invalid;  // XXX mixes domains, simulate to make sure it's glitch-free
   // Make our own additions to slow shift register
   // equivalence circle_stat: circle_fault 1, circle_wrap 1, circle_addr 14
`define SLOW_SR_DATA { circle_count, circle_stat }
   // TODO: These `we_*` wires below, are taken from the decode signals that are auto generated
   wire [7:0] slow_shell_out;

   reg [sr_length-1:0] slow_read=0;
   always @(posedge clk1x) if (slow_op) begin
      slow_read <= slow_snap ? `SLOW_SR_DATA : {slow_read[sr_length-9:0],slow_shell_out};
   end
   assign slow_out = slow_read[sr_length-1:sr_length-8];

   assign simple_demo_flag = 0;
   // Instantiate controller in clk domain
   wire ext_trig=buf_sync;


   // Timing generator, interposes on local bus
   wire collision, collision1;

`define USE_TGEN
`ifdef USE_TGEN
   (* lb_automatic, gvar="cavity_n", gcnt=2, cd="lb2", cd_indexed *)
   tgen tgen // auto(cavity_n,2) lb2[cavity_n]
     (.clk(clk1x), .trig(ext_trig), .collision(collision1),
      .lb_data(clk1x_data), .lb_write(clk1x_write), .lb_addr(clk1x_addr),
      .addr_padding(1'b0),
      .lbo_data(lb1_data[cavity_n]), .lbo_write(lb1_write[cavity_n]), .lbo_addr(lb1_addr[cavity_n]),
      // TODO: This is hard-coded to the tgen_0
      //.delay_pc_addr_hit(`ADDR_HIT_tgen_0_delay_pc_XXX & (cavity_n == 0)),
      .dests_write(we_tgen_0_delay_pc_XXX & (cavity_n == 0)),
      `AUTOMATIC_tgen
      );
`else
   assign lb1_data[cavity_n] = clk1x_data;
   assign lb1_addr[cavity_n] = clk1x_addr;
   assign lb1_write[cavity_n] = clk1x_write;
   assign collision1 = 0;
`endif

   // Function generator, interposes on local bus
   //`define USE_FGEN
`ifdef USE_FGEN
   fgen #(.addr_hi(0)) fgen(.clk(clk1x), .trig(ext_trig), .collision(collision),
			    .lb_data(lb1_data[cavity_n]), .lb_write(lb1_write[cavity_n]), .lb_addr(lb1_addr[cavity_n]),
			    .lbo_data(lb2_data[cavity_n]), .lbo_write(lb2_write[cavity_n]), .lbo_addr(lb2_addr[cavity_n])
			    );
`else
   assign lb2_data[cavity_n] = lb1_data[cavity_n];
   assign lb2_addr[cavity_n] = lb1_addr[cavity_n];
   assign lb2_write[cavity_n] = lb1_write[cavity_n];
   assign collision = 0;
`endif

   (* lb_automatic, gvar="cavity_n", gcnt=2, cd="lb2", cd_indexed *)
   llrf_shell llrf // auto(cavity_n,2) lb2[cavity_n]
     (.clk(clk1x),
      .a_field(a_field), .a_forward(a_forward), .a_reflect(a_reflect),
      .iq(iq), .drive(drive), .piezo_ctl(piezo_ctl),
      .iq_recv(17'b0), .qsync_rx(1'b0), .tag_rx(8'b0),
      .ext_trig(ext_trig), .master_cic_tick(1'b0),
      .mon_result(mon_result), .mon_strobe(mon_strobe), .mon_boundary(mon_boundary),
      .slow_op(slow_op), .slow_snap(slow_snap), .slow_out(slow_shell_out),
      //.lbi_data(lb2_data), .lbi_addr(lb2_addr), .lbi_write(lb2_write),
      `AUTOMATIC_llrf
      );

   // Setup for clock phasing hack
   reg clk1x_div2=0;
   always @(posedge clk1x) clk1x_div2 <= ~clk1x_div2;

   // Clock phasing hack suggested by Eric, to avoid the old
   // (and non-working in Vivado 2020.2) iq2 <= ~clk1x;
   // Passes testbench, but still ugly and possibly fragile.
   reg clk1x_div2_r=0, clk1x_div2_rr=0;
   reg iq2_bogus=0;
   always @(posedge clk2x) begin
      clk1x_div2_r <= clk1x_div2;  // traditional CDC
      clk1x_div2_rr <= clk1x_div2_r;
      iq2 <= (clk1x_div2_r ^ clk1x_div2_rr) ? 1'b1 : ~iq2;
`ifdef SIMULATE
      iq2_bogus <= ~clk1x;
`endif
   end

   // Move iq and drive to clk2x domain unchanged
   reg signed [17:0] drive2x=0;
   reg iq2x=0;
   always @(posedge clk2x) begin
      drive2x <= drive;
      iq2x <= iq;
   end

   // Now take care of iq and drive semantics in clk2x domain
   reg signed [17:0] drive2_d=0;
   reg iq2x_d=0;
   always @(posedge clk2x) begin
      iq2x_d <= iq2x;
      drive2 <= iq2x_d ? drive2x: drive2_d;
      drive2_d <= drive2;
   end

`else
   assign simple_demo_flag = 1;
   reg simple_iq=0; always @(posedge clk1x) simple_iq <= ~simple_iq;
   assign iq=simple_iq;
   assign drive=0;
   assign mon_result=20'hdead0;
   assign mon_strobe=0;
   assign mon_boundary=0;
   wire [2:0] cbuf_mode=1;  // hard-code simple mode
`endif  // SIMPLE_DEMO

   reg [15:0] simple_cnt=0;
   always @(posedge clk1x) simple_cnt <= buf_sync ? 0 : simple_cnt+1;
   wire [15:0] sim_result = simple_cnt;
   wire sim_strobe = simple_cnt[3] == 1;
   wire sim_boundary = ~sim_strobe;

   always @(posedge clk1x) case (cbuf_mode)
	0: begin buf_data <= mon_result[19:4]; buf_strobe <= mon_strobe; buf_bound <= mon_boundary; end
	1: begin buf_data <= sim_result; buf_strobe <= sim_strobe; buf_bound <= sim_boundary; end
	2: begin buf_data <= a_field; buf_strobe <= 1; buf_bound <= 1; end
	3: begin buf_data <= a_forward; buf_strobe <= 1; buf_bound <= 1; end
	4: begin buf_data <= a_reflect; buf_strobe <= 1; buf_bound <= 1; end
	5: begin buf_data <= drive[17:2]; buf_strobe <= 1; buf_bound <= iq; end
	default: begin buf_data <= 0; buf_strobe <= 0; buf_bound <= 0; end
   endcase

end endgenerate

reg signed [17:0] eig_drive0=0, total_eig_drive=0;
wire signed [17:0] noise_eig_drive;
wire res_clip;
(* lb_automatic, cd="clk2x" *)
cav_mech #(.n_mech_modes(n_mech_modes)) cav_mech // auto clk2x
  (.clk(clk2x),
   .start_eig(start_eig), .noise_eig_drive(noise_eig_drive), .eig_drive(total_eig_drive),
   .start_outer(start_outer), .mech_x(mech_x), .res_clip(res_clip),
   //.we_prng_iva(we_cav_mech_prng_iva), .we_prng_ivb(we_cav_mech_prng_ivb),
   `AUTOMATIC_cav_mech
);

// Sum these drive terms together
reg signed [18:0] local_eig_drive=0;
wire signed [19:0] sum_eig_drive = cav_eig_drive_acc[cavity_count] + local_eig_drive;
reg edrive_clip=0;
always @(posedge clk2x) begin
   local_eig_drive <= piezo_eig_drive_acc[cavity_count] + noise_eig_drive;  // pipeline add just like cav_elec.v
   eig_drive0 <= `SAT(sum_eig_drive,19,17);
   total_eig_drive <= eig_drive0;
   edrive_clip <= ~`UNIFORM(sum_eig_drive[19:17]);
end

// Reserve space for several possible clipping status signals
// Caller should take care of latching, reporting, and clearing.
assign clips = {6'b0, edrive_clip, res_clip};

// Configuration and parameter ROM
wire [7:0] rom_data0;
parameter use_config_rom = 1; //

generate if (use_config_rom == 1)
     config_romx rom(.address(lb_addr[4:0]), .data(rom_data0));
endgenerate

reg [7:0] config_data0=0;
always @(lb_addr[4:0]) case(lb_addr[4:0])
	5'h00: config_data0 = 8'haa;
	5'h01: config_data0 = circle_aw;
	5'h02: config_data0 = mode_count;
	5'h03: config_data0 = mode_shift;
	5'h04: config_data0 = n_mech_modes;
	5'h05: config_data0 = df_scale;
	5'h06: config_data0 = simple_demo_flag;
	5'h07: config_data0 = cavity_count;
	default: config_data0 = 0;
endcase
reg [cavity_count*2+9:0] rom_data=0;  // add two extra padding bits on left to work around Xilinx synthesizer bug
integer ix;
always @(posedge lb_clk) begin
	rom_data[7:0] <= lb_addr[5] ? config_data0 : rom_data0;
	for (ix=0; ix<cavity_count; ix=ix+1)
		rom_data[9+2*ix +: 2] <= {slow_data_ready[ix], circle_data_ready[ix]};
end

// This will only get more complex ...
//   control register mirror memory
//   frequency counter
// Configuration has one stage of pipeline circle_buf, slow_bridge, and rom.
// One more here, making read_pipe = 2
reg [16:0] lb_addr_d1=0;
reg [31:0] lb_out_r=0;
always @(posedge lb_clk) begin
	lb_addr_d1 <= lb_addr;
	lb_out_r <= (lb_addr_d1[16:14] == 3'b101) ? circle_out[lb_addr_d1[13]] : ((lb_addr_d1[16:14] == 3'b100) & lb_addr_d1[13]) ? slow_bridge_out[lb_addr_d1[9]] : lb_addr_d1[16]? rom_data: mirror_out_0;
end
assign lb_out = lb_out_r;

endmodule
