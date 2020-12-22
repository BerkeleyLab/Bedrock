// ------------------------------------
// patt_gen.v
//
// Test pattern generator and checker with two operating modes:
// - In counter mode, the pattern generator will output monotonically
//   increasing values, modulo 1<<CNT_WI.
// - In user data mode, the pattern generator outputs the data placed in
//   pgen_usr_data
//
// The checker is enabled by appropriately setting the P_CHECK parameter.
// It shares the counting logic with the generator and tries to lock with
// a sliding window approach. Note that consecutive matches on the same
// data element are allowed. This is essential for protocols that are continuously
// transmitting, even if new data is not available.
//
// rx_match is the latched result of the previous data comparison and
// rx_err_cnt reports how many times a matching sequence has been interrupted.
//
// Asserting pgen_disable will clear both status outputs
// ------------------------------------

module patt_gen #(
   parameter DWI = 32,
   parameter P_CHECK = 0 // P_CHECK = 0: Generate pattern
                         // P_CHECK = 1: Check pattern
) (
   // -------------------
   // Register interface
   // -------------------
   input            lb_clk,
   input            pgen_disable,   // Disable pattern generation

   input  [4:0]     pgen_rate,      // Rate of data generation; 0=32 (1/32), 1=1 (full rate)
   input            pgen_test_mode, // test_mode = 0: Counter
                                    // test_mode = 1: User data
   input  [2:0]     pgen_inc_step,  // Increment step for counter; 0=8, 1=1
   input  [DWI-1:0] pgen_usr_data,

   // -------------------
   // Test Data interface
   // -------------------
   input            clk,
   // Pattern TX
   output           tx_valid,
   output [DWI-1:0] tx_data,
   // Pattern RX
   input            rx_valid,
   input  [DWI-1:0] rx_data,

   // In lb_clk domain
   output           rx_match,
   output [15:0]    rx_err_cnt // Increments whenever a matching run is interrupted
);
   localparam TMODE_CNT = 0, TMODE_USR = 1;
   localparam CNT_WI = 7;
   localparam ERR_WI = 16;

   // -------------------
   // Register interface
   // -------------------
   // All registers are quasi-static so just register in target domain
   reg           pgen_disable_x;
   reg [4:0]     pgen_rate_x;
   reg           pgen_tmode_x;
   reg [2:0]     pgen_inc_x;
   reg [DWI-1:0] pgen_usr_data_x;

   always @(posedge clk) begin
      pgen_disable_x  <= pgen_disable;
      pgen_rate_x     <= pgen_rate;
      pgen_tmode_x    <= pgen_test_mode;
      pgen_inc_x      <= pgen_inc_step;
      pgen_usr_data_x <= pgen_usr_data;
   end

   // Re-encode and align registers
   reg [5:0] pgen_rate_enc;
   reg [3:0] pgen_inc_enc;
   reg       pgen_disable_r;

   always @(posedge clk) begin
      pgen_rate_enc  <= pgen_rate_x==0 ? 1<<5 : pgen_rate_x;
      pgen_inc_enc   <= pgen_inc_x==0 ? 1<<3 : pgen_inc_x;
      pgen_disable_r <= pgen_disable_x;
   end

   reg [CNT_WI-1:0] data_cnt = 0;
   wire [CNT_WI+1-1:0] data_cnt_ext;
   wire cnt_enable;
   wire cnt_reset;

   assign data_cnt_ext = {1'b0, data_cnt} + pgen_inc_enc;

   // Common data counter
   always @(posedge clk) begin
      if (cnt_reset || pgen_disable_r)
         data_cnt <= 0;
      else if (cnt_enable) begin
         if (data_cnt_ext[CNT_WI])
            data_cnt <= 0;
         else
            data_cnt <= data_cnt_ext;
      end
   end

   generate if (P_CHECK == 0) begin : G_PGEN

      // -------------------
      // Pattern generation
      // -------------------
      wire pgen_clken;

      multi_sampler #(
         .sample_period_wi (6))
      i_multi_sampler (
         .clk             (clk),
         .ext_trig        (~pgen_disable_r),
         .sample_period   (pgen_rate_enc),
         .dsample0_period (8'b0),
         .dsample1_period (8'b0),
         .dsample2_period (8'b0),
         .sample_out      (pgen_clken),
         .dsample0_stb    (),
         .dsample1_stb    (),
         .dsample2_stb    ()
      );

      reg [DWI-1:0]    tx_data_r;
      reg              tx_valid_r;
      always @(posedge clk) begin
         tx_valid_r <= 0;
         if (pgen_clken) begin
            tx_valid_r <= 1;
            tx_data_r  <= (pgen_tmode_x == TMODE_CNT) ? data_cnt : pgen_usr_data_x;
         end
      end

      assign cnt_reset = 0;
      assign cnt_enable = tx_valid_r;

      assign tx_valid = tx_valid_r;
      assign tx_data  = tx_data_r;

   end else begin

      // -------------------
      // Pattern checking
      // -------------------
      wire              data_match_next, data_match_cur, data_iseq;
      reg               data_match=0;

      reg  [DWI-1:0]    data_cur_r;
      wire [DWI-1:0]    data_ref_cur, data_ref_next;
      reg  [ERR_WI-1:0] rx_err_cnt_r=0;

      assign data_match_cur = (pgen_tmode_x==TMODE_CNT) ? (data_ref_cur==rx_data):
                                                          (pgen_usr_data_x==rx_data);
      assign data_match_next = (data_ref_next==rx_data);

      assign data_iseq = data_match_cur|data_match_next;

      always @(posedge clk) begin
         if (pgen_disable_r) begin
            rx_err_cnt_r <= 0;
            data_match   <= 0;
         end

         if (rx_valid) begin
            data_match <= data_iseq;

            // Update local data if matched incremented value;
            // else hold and allow multiple matches on same element
            if (data_match_next)
               data_cur_r <= data_cnt;

            if (data_match && ~data_iseq)
               rx_err_cnt_r <= rx_err_cnt_r + 1;
         end
      end

      assign cnt_reset = ~data_iseq&&rx_valid;
      assign cnt_enable = data_match_next&&rx_valid;

      // Extend to full data width
      assign data_ref_cur = data_cur_r;
      assign data_ref_next = data_cnt;

      // Cross quasi-static status output to lb_clk
      reg              rx_match_x;
      reg [ERR_WI-1:0] rx_err_cnt_x;

      always @(posedge lb_clk) begin
         rx_match_x   <= data_match;
         rx_err_cnt_x <= rx_err_cnt_r;
      end

      assign rx_match   = rx_match_x;
      assign rx_err_cnt = rx_err_cnt_x;

   end endgenerate

endmodule
