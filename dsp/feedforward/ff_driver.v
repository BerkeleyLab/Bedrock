/* F(eed)F(orward) Driver
   Plays back a feed-forward waveform that has been host-loaded into
   a local memory. Memory contents run through the integrator side of
   a 4-stage CIC before being supplied to an SRF cavity model.

   The cavity model produces a predicted cavity signal based on the input
   drive waveform, that is suitable to be used in a feedback loop.

   The waveform memory is read in blocks of 4, with the option of repeating
   each block N times, determined by 2**MEM_REP.

   Output updates every 4 clock cycles.

   NOTE: cav_ddrive expects to be down-shifted at instantiation-site. This
         is deliberately not done here to avoid unnecessary loss of precision.
*/

module ff_driver # (
   parameter CAV_SHIFT = 1,
   parameter CIC_SHIFT = 1,
   parameter MEM_REP = 1,
   parameter MEM_AW = 11,
   parameter squelch = 0  // maybe useful to set to 1 in simulation, see cic_bankx.v
) (
   input clk,
   input start,  // Reset state and start reading FF waveform

   // Cavity model parameters
   input signed  [17:0] coeff,      // external
   output        [1:0]  coeff_addr, // external address for coeff
                                    // [0] - Drive coupling
                                    // [1] - Cavity decay
                                    // [3:2] - Unused

   // Feedforward memory
   input signed  [17:0] mem,        // external
   output        [10:0] mem_addr,   // external address for FF memory

   output signed [17:0] cav_drive,  // Drive; expect to use one of drive or ddrive
   output signed [17:0] cav_ddrive, // Drive derivative.
                                    // NOTE: Expects (>>> CIC_SHIFT) at instantiation site
   output signed [17:0] cav_mag,    // Cavity model magnitude
   output signed [17:0] cav_ph,     // Cavity model phase
   output        [1:0]  error       // 0 - cav model error; 1 - cic bank error
);

   // -----------
   // FeedForward memory addressing
   // -----------
   reg [MEM_AW+MEM_REP-1:0] cycle=0;
   reg running=0, running_r;
   reg [MEM_AW-1:0] mem_addr_end=0;
   wire [1:0] subcycle;
   reg  [1:0] subcycle_r=0;
   wire [MEM_AW-2-1:0] cycle_u;
   wire cic_init;
   reg  cic_init_r=0;

   always @(posedge clk) begin
      if (start) running <= 1;
      if (mem_addr==mem_addr_end) running <= 0;

      running_r <= running;
      cycle <= cycle+1; // Free-running so that cavity model is not stopped at end of table
      if (running) begin
         if (!running_r)
            cycle <= 0;
         else if (cycle_u==0 && subcycle==3)
            // First 4 entries containing FF table size plus reserved entries are not repeated
            cycle <= 1<<(2+MEM_REP);
      end

      // Delay subcycle and cic_init to align with incoming memory
      subcycle_r <= subcycle;
      cic_init_r <= cic_init;

      if (cycle_u==0 && subcycle_r==0) mem_addr_end <= mem[MEM_AW-1:0];
   end

   assign subcycle = cycle[1:0]; // Read in increments of 4
   assign cycle_u = cycle[MEM_AW+MEM_REP-1:MEM_REP+2];
   assign mem_addr = running ? {cycle_u, subcycle} : 0;
   assign cic_init = (cycle_u == 1) & running; // Init cic_bankx during first read cycles

   // -----------
   // CIC bank
   // -----------
   wire [1:0] error_l;
   wire signed [17:0] drive_delta, drive;

   wire [17:0] mem_l = (running_r && cycle_u!=0) ? mem : 0;

   cic_bankx #(
      .squelch(squelch),
      .shift(CIC_SHIFT))
   i_cic_bankx (
      .clk         (clk),
      .subcycle    (subcycle_r),
      .init        (cic_init_r),
      .mem_v       (mem_l),
      .drive_delta (drive_delta),
      .drive       (drive),
      .error       (error_l[1]));

   // -----------
   // Cavity model
   // -----------
   // a_model consumes coefficients on subcycle 2 and 3; read from
   // external memory starting from 0x0 and delay coeff
   assign coeff_addr = subcycle_r;
   reg signed [17:0] coeff_r=0;
   always @(posedge clk) coeff_r <= coeff;

   wire signed [17:0] cav_mag_l;

   a_model #(.shift(CAV_SHIFT)) i_a_model (
      .clk      (clk),
      .subcycle (subcycle_r),
      .coeff    (coeff_r),
      .drive    (drive),
      .cavity   (cav_mag_l),
      .error    (error_l[0]));

   // Time-align all outputs by latching onto valid cycles; this simplifies
   // downstream connections
   reg signed [17:0] drive_delta_r=0, drive_r=0;
   reg signed [17:0] cav_mag_r=0, cav_ddrive_r=0, cav_drive_r=0;

   always @(posedge clk) begin // Only update when FF is running
      if (subcycle_r == 1) drive_delta_r <= drive_delta;
      if (subcycle_r == 2) drive_r <= drive;
      if (subcycle_r == 0) begin
         cav_drive_r  <= drive_r;
         cav_ddrive_r <= drive_delta_r;
         cav_mag_r    <= cav_mag_l;
      end
   end

   assign cav_drive  = cav_drive_r;
   assign cav_ddrive = cav_ddrive_r;
   assign cav_mag    = cav_mag_r;
   assign error      = error_l & running;

   // No phase model yet
   assign cav_ph = 0;

endmodule
