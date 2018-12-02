`timescale 1ns / 1ns
`define LB_DECODE_rtsim
`include "rtsim_auto.vh"

module rtsim(
    input clk,
    input iq,
    input signed [17:0] drive, // not counting beam
    input signed [17:0] piezo,
    // Output ADCs at 20 MHz IF
    output signed [15:0] a_field,
    output signed [15:0] a_forward,
    output signed [15:0] a_reflect,
     // Local Bus for simulator configuration
    input [31:0] lb_data,
    input [14:0] lb_addr,
    input lb_write, // single-cycle causes a write
    // Output status
    output [7:0] clips
);

wire lb_clk;
assign lb_clk = clk;

`AUTOMATIC_decode
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
`define UNIFORM(x) ((~|(x)) | &(x))  // All 0's or all 1's

// Beam timing generator
// beam_timing output is limited to [0,phase_step].
wire [11:0] beam_timing;
beam beam  // auto
  (.clk(clk), .ena(iq), .reset(1'b0), .pulse(beam_timing),
   `AUTOMATIC_beam);
// Create start pulses at configured interval
reg start=0;
reg [7:0] mech_cnt=0;
always @(posedge clk) begin
   mech_cnt <= mech_cnt==0 ? n_cycles-1 : mech_cnt-1;
   start <= mech_cnt == 0;
end
wire start_outer;
reg_delay #(.dw(1), .len(0)) start_outer_g(.clk(clk), .gate(1'b1), .reset(1'b0), .din(start), .dout(start_outer));
wire start_eig;
reg_delay #(.dw(1), .len(1)) start_eig_g(.clk(clk), .gate(1'b1), .reset(1'b0), .din(start), .dout(start_eig));

// Configure number of modes processed
// I don't make it host-settable (at least not yet),
// because of its interaction with interp_span.
parameter n_mech_modes = 7;
parameter n_cycles = n_mech_modes * 2;
parameter interp_span = 4;  // ceil(log2(n_cycles))
parameter mode_count = 3;

// Allow tweaks to the cavity electrical eigenmode time scale
parameter mode_shift=18;

// Control how much frequency shifting is possible with mechanical displacement
parameter df_scale=0;     // see cav_freq.v

// Instantiate simulator in clk domain
wire signed [17:0] cav_eig_drive, mech_x;
wire signed [17:0] piezo_eig_drive;
// Parameter settings here should be mirrored in param.py
// Instantiating the Station module here:
station #(.mode_count(mode_count), .mode_shift(mode_shift), .n_mech_modes(n_mech_modes), .df_scale(df_scale)) station // auto
  (.clk(clk),
   .beam_timing(beam_timing), .mech_x(mech_x), .cav_eig_drive(cav_eig_drive),
   .piezo_eig_drive(piezo_eig_drive), .start_outer(start_outer),
   .iq(iq), .drive(drive), .start(start), .piezo(piezo),
   .a_field(a_field), .a_forward(a_forward), .a_reflect(a_reflect),
//   .we_prng_iva(we_station_prng_iva), .we_prng_ivb(we_station_prng_ivb),
   `AUTOMATIC_station
);

reg signed [17:0] eig_drive0=0, eig_drive=0;
wire signed [17:0] noise_eig_drive;
wire res_clip;
cav_mech #(.n_mech_modes(n_mech_modes)) cav_mech // auto
  (.clk(clk),
   .start_eig(start_eig), .noise_eig_drive(noise_eig_drive), .eig_drive(eig_drive),
   .start_outer(start_outer), .mech_x(mech_x), .res_clip(res_clip),
//   .we_prng_iva(we_cav_mech_prng_iva), .we_prng_ivb(we_cav_mech_prng_ivb),
   `AUTOMATIC_cav_mech
);

// Sum these drive terms together
reg signed [18:0] local_eig_drive=0;
wire signed [19:0] sum_eig_drive = cav_eig_drive + local_eig_drive;
reg edrive_clip=0;
always @(posedge clk) begin
  local_eig_drive <= piezo_eig_drive + noise_eig_drive;  // pipeline add just like cav_elec.v
  eig_drive0 <= `SAT(sum_eig_drive,19,17);
  eig_drive <= eig_drive0;
  edrive_clip <= ~`UNIFORM(sum_eig_drive[19:17]);
end

// Reserve space for several possible clipping status signals
// Caller should take care of latching, reporting, and clearing.
assign clips = {6'b0, edrive_clip, res_clip};
endmodule
