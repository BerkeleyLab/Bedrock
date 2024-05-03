`timescale 1ns / 1ns

module serializer_multichannel_tb;
   parameter NCHAN = 8;
   parameter DWIDTH = 8;
   parameter L_TO_R = 1; // L_TO_R=1: Channel shifting starts with CH0

   // Testbench controls
   localparam SIM_CYCLES = 5000;
   localparam MAX_ERROR = 10; // Limit error reporting

   // Testbench stimulus
   localparam MAX_DELAY = NCHAN*4;

   reg clk;
   integer cc, errors;
   integer seed_int;
   integer sample_count=0;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("serializer_multichannel.vcd");
         $dumpvars(5,serializer_multichannel_tb);
      end
      if (!$value$plusargs("seed=%d", seed_int))
         seed_int = 12345;

      $display("SEED = %d", seed_int);
      $display("NCHAN=%d, DWIDTH=%d, L_TO_R=%d", NCHAN, DWIDTH, L_TO_R);

      errors = 0;
      for (cc=0; cc< SIM_CYCLES; cc=cc+1) begin
         clk=0; #5;
         clk=1; #5;
      end

      if (sample_count == 0) begin
         $display("ERROR: No input was sampled, nothing was tested.");
         errors = errors + 1;
      end
      $display("%d errors", errors);
      if (errors > 0) begin
        $display("FAIL");
        $stop(0);
      end else begin
        $display("PASS");
        $finish(0);
      end
   end

   // --------------------------
   // Stimulus generation
   // --------------------------
   reg [DWIDTH-1:0] d_in[NCHAN-1:0];
   wire [NCHAN*DWIDTH-1:0] d_in_flat;
   reg sample_in;
   integer count_on=0, count_max=0;

   always @(negedge clk) begin
      if (sample_in) begin
         count_on     <= 1;
         count_max    <= (NCHAN-1) + $urandom(seed_int) % MAX_DELAY;
      end else begin
         count_on <= count_on + 1;
      end

      sample_in <= 1'b0;
      if (sample_count == 0)
         sample_in <= 1'b1;
      else if (count_on == count_max) begin
         sample_in <= 1'b1;
      end
   end

   // Collect DUT input statistics
   always @(posedge clk) if (sample_in) sample_count <= sample_count + 1;

   genvar ch_id;
   generate for (ch_id=0; ch_id < NCHAN; ch_id=ch_id+1) begin : g_channel_data

      always @(negedge clk) begin
         if (sample_in || sample_count == 0) d_in[ch_id] <= $urandom(seed_int) % 2**DWIDTH;
      end

      assign d_in_flat[(ch_id+1)*DWIDTH-1: (ch_id)*DWIDTH] = d_in[ch_id];

   end endgenerate

   // --------------------------
   // Instantiate Device Under Test
   // --------------------------
   wire [DWIDTH-1:0] d_out;
   wire gate_out;

   serializer_multichannel #(
      .n_chan(NCHAN),
      .dw(DWIDTH),
      .l_to_r(L_TO_R))
   dut(
      .clk        (clk),
      .sample_in  (sample_in),
      .data_in    (d_in_flat),
      .gate_out   (gate_out),
      .stream_out (d_out)
   );

   // --------------------------
   // Scoreboard
   // --------------------------
   reg [DWIDTH-1:0] saved_input[NCHAN-1:0];
   integer chan_check=0;

   generate for (ch_id=0; ch_id < NCHAN; ch_id=ch_id+1) begin : g_channel_store
      always @(posedge clk) if (sample_in) saved_input[ch_id] <= d_in[ch_id];
   end endgenerate

   always @(posedge clk) if (errors < MAX_ERROR) begin
      if (chan_check != 0) begin
         if (~gate_out) begin
            $display("%t ERROR: Broken gate_out after input was sampled in", $time);
            errors = errors+1;
         end
         if (L_TO_R == 1) begin
            if (d_out != saved_input[NCHAN-chan_check]) begin
               $display("%t ERROR: Mismatch when reading out channel %d", $time, NCHAN-chan_check);
               errors = errors+1;
            end
         end else begin
            if (L_TO_R == 0) if (d_out != saved_input[chan_check-1]) begin
               $display("%t ERROR: Mismatch when reading out channel %d", $time, chan_check-1);
               errors = errors+1;
            end
         end
         chan_check <= chan_check-1;
      end else begin
         if (gate_out) begin
            $display("%t ERROR: gate_out asserted after all channels were shifted out", $time);
            errors = errors+1;
         end
      end

      if (sample_in) begin
         if (chan_check != 0 && ~gate_out) begin
            $display("%t ERROR: New sample pulse received before all channels were read out", $time);
            errors = errors + 1;
         end
         chan_check  <= NCHAN; // Decrement from max channel
      end
   end

endmodule
