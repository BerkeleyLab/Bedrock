`timescale 1ns / 1ns

`include "cav_mech_auto.vh"

module cav_mech(
  input clk,
  input start_eig,
  input start_outer,
  output signed [17:0] mech_x,
  output signed [17:0] noise_eig_drive,
  input signed [17:0] eig_drive,
  // Output status
  output res_clip,
  `AUTOMATIC_self
);

`AUTOMATIC_decode

parameter n_mech_modes = 7;
parameter n_cycles = n_mech_modes * 2;

// Couple randomness to mechanical drive
wire signed [17:0] environment;  // filled in later
outer_prod noise_couple  // auto
	(.clk(clk), .start(start_outer), .x(environment), .result(noise_eig_drive),
	 `AUTOMATIC_noise_couple
);


// Instantiate the mechanical resonance computer
resonator resonator // auto
  (.clk(clk), .start(start_eig),
	 .drive(eig_drive),
	 .position(mech_x), .clip(res_clip),
	 `AUTOMATIC_resonator
);
// Pseudorandom number subsystem
wire [31:0] rnda, rndb;

prng prng  // auto
  (.clk(clk), .rnda(rnda), .rndb(rndb),
   `AUTOMATIC_prng);

// Create a white noise term for environment
// This is a strangely-scaled CIC filter
// Each iteration adds a variance of 12, consuming 6 bits of PRNG
// Result has variance of n_cycles*12, mean of 0, possible peak n_cycles*7
// e.g. if n_cycles=14, std.dev.=12.96, peak=98, peak/rms=7.56
reg signed [11:0] noise_accum=0, noise_1=0, noise_out=0;
always @(posedge clk) begin
	 noise_accum <= noise_accum + rndb[2:0] - rndb[5:3];
	 if (start_eig) begin
		  noise_1 <= noise_accum;
		  noise_out <= noise_1-noise_accum;
	 end
end
assign environment = noise_out;

endmodule // cav_mech
