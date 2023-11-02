`timescale 1ns / 1ns

/** MULTI SAMPLER
    Multi-purpose sampling signal generation with the following features:
    - Arbitrary base sampling period, defined as a fraction of input clock
      qualified with external trigger (ext_trig)
    - Main sampling signal
    - Three configurable downsampling strobes, defined w.r.t base sampling period
    - Downsampling strobe generation can be disabled to save HW if not required
**/

module multi_sampler #(
   parameter sample_period_wi=8,
   parameter dsample0_en=0,
   parameter dsample0_wi=8,
   parameter dsample1_en=0,
   parameter dsample1_wi=8,
   parameter dsample2_en=0,
   parameter dsample2_wi=8
) (
   input                        clk,
   input                        reset,
   input                        ext_trig,
   input [sample_period_wi-1:0] sample_period,
   input [dsample0_wi-1:0]      dsample0_period,
   input [dsample1_wi-1:0]      dsample1_period,
   input [dsample2_wi-1:0]      dsample2_period,
   output                       sample_out,
   output                       dsample0_stb,
   output                       dsample1_stb,
   output                       dsample2_stb
);

`ifdef SIMULATE
   localparam INITVAL=1;
`else
   localparam INITVAL=0; // Longer startup
`endif

   reg [sample_period_wi-1:0] samp_per_r = 0;
   reg [sample_period_wi-1:0] base_count = 0;
   reg [dsample0_wi-1:0]      ds0_count = INITVAL;
   reg [dsample1_wi-1:0]      ds1_count = INITVAL;
   reg [dsample2_wi-1:0]      ds2_count = INITVAL;
   reg sample_out_l = 0;

   // Base-timing generation
   always @(posedge clk) begin
      sample_out_l <= 0;
      if (reset) begin
        samp_per_r <= 0;
        base_count <= 0;
      end else if (ext_trig) begin
         samp_per_r <= sample_period;

         base_count <= (base_count == (sample_period-1)) ? 0 : base_count+1;

         // Restart count on sample_period change
         if ((sample_period != samp_per_r) && |base_count) base_count <= 0;

         sample_out_l <= (base_count == 0);
      end
   end
   assign sample_out = sample_out_l;

   generate if (dsample0_en) begin : g_dsample0
      always @(posedge clk) begin
         if (sample_out_l)
            ds0_count <= (ds0_count == 1) ? dsample0_period : ds0_count-1;
      end
      assign dsample0_stb = ds0_count==1;
   end else begin : ng_dsample0
      assign dsample0_stb = 0;
   end endgenerate

   generate if (dsample1_en) begin : g_dsample1
      always @(posedge clk) begin
         if (sample_out_l)
            ds1_count <= (ds1_count == 1) ? dsample1_period : ds1_count-1;
      end
      assign dsample1_stb = ds1_count==1;
   end else begin : ng_dsample1
      assign dsample1_stb = 0;
   end endgenerate

   generate if (dsample2_en) begin : g_dsample2
      always @(posedge clk) begin
         if (sample_out_l)
            ds2_count <= (ds2_count == 1) ? dsample2_period : ds2_count-1;
      end
      assign dsample2_stb = ds2_count==1;
   end else begin : ng_dsample2
      assign dsample2_stb = 0;
   end endgenerate

endmodule
