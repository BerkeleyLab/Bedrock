// ------------------------------------
// patt_gen_tb
//
// Simple testbench to demonstrate and test functionality of patt_gen.
// It works by randomly generating a setup and waiting for X number of
// matches before moving on to the next setup. If a match is not achieved
// in MATCH_TIMEOUT cycles, an error is flagged.
// ------------------------------------

module patt_gen_tb;

   localparam SIM_TIME = 300000; // ns
   localparam CC_CLK_PERIOD = 10;
   localparam TX_CLK_PERIOD = 8;

   localparam DELAY_REG  = 1;
   localparam DELAY_DATA = 10;

   localparam MATCH_TIMEOUT = 1<<16; // clock cycles
   localparam MATCH_THRES = 10;

   reg cc_clk = 0;
   reg tx_clk = 0;
   reg fail=0;

   integer SEED;
   integer tx_cnt=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("patt_gen.vcd");
         $dumpvars(5, patt_gen_tb);
      end
      if (!$value$plusargs("seed=%d", SEED)) SEED = 123;

      while ($time < SIM_TIME) @(posedge cc_clk);

      // Check that status can be cleared
      pgen_disable <= 1;
      #1000;
      pgen_disable <= 0;
      #1000;
      $display("%d successfully matched patterns", tx_cnt);
      if (fail || tx_cnt < 80) begin
         $display("FAIL");
         $stop(0);
      end else begin
         $display("PASS");
         $finish;
      end
   end

   always begin cc_clk = ~cc_clk; #(CC_CLK_PERIOD/2); end
   always begin tx_clk = ~tx_clk; #(TX_CLK_PERIOD/2); end

   // ----------------------
   // Generate stimulus
   // ----------------------
   reg         pgen_disable = 1;
   wire [4:0]  pgen_rate;
   wire        pgen_test_mode;
   wire [2:0]  pgen_inc_step;
   wire [15:0] pgen_usr_data;

   wire        rx_valid, rx_valid_x;

   integer match_cnt = 0;
   integer match_tout = 0;
   integer rand_setup;

   // Generate a random setup and wait for match
   always @(posedge cc_clk) begin
      if (match_tout==0 || (match_cnt >= MATCH_THRES)) begin
         if (match_tout==0 && pgen_disable==0) begin
            $display("Timed out without a successful match");
            fail <= 1;
         end else if (rx_match) begin
            tx_cnt   <= tx_cnt + 1;
         end

         match_tout   <= MATCH_TIMEOUT;
         rand_setup   <= $urandom(SEED);
         pgen_disable <= 0;
         match_cnt    <= 0; // Wait for a certain match count
      end else begin
         match_tout <= match_tout - 1;
         if (rx_match && rx_valid_x) match_cnt <= match_cnt + 1;
      end
   end

   assign {pgen_rate, pgen_test_mode, pgen_inc_step, pgen_usr_data} = rand_setup;

   flag_xdomain i_flag_xdomain (
      .clk1 (tx_clk), .flagin_clk1 (rx_valid),
      .clk2 (cc_clk), .flagout_clk2 (rx_valid_x));

   // ----------------------
   // Instantiate DUT
   // ----------------------
   wire        tx_valid;
   wire [15:0] tx_data;
   wire [15:0] rx_data;
   wire        rx_match;
   wire [15:0] rx_err_cnt;

   patt_gen #(
      .DWI     (16),
      .P_CHECK (0))
   i_dut_gen (
      .lb_clk         (cc_clk),
      .pgen_disable   (pgen_disable),
      .pgen_rate      (pgen_rate),
      .pgen_test_mode (pgen_test_mode),
      .pgen_inc_step  (pgen_inc_step),
      .pgen_usr_data  (pgen_usr_data),
      .clk            (tx_clk),
      .tx_valid       (tx_valid),
      .tx_data        (tx_data),
      .rx_valid       (1'b0),
      .rx_data        (16'b0),
      .rx_match       (),
      .rx_err_cnt     ()
   );

   // Delay register configuration and data lines to emulate decoupled endpoints
   reg        pgen_disable_dly   [DELAY_REG-1:0];
   reg [4:0]  pgen_rate_dly      [DELAY_REG-1:0];
   reg        pgen_test_mode_dly [DELAY_REG-1:0];
   reg [2:0]  pgen_inc_step_dly  [DELAY_REG-1:0];
   reg [15:0] pgen_usr_data_dly  [DELAY_REG-1:0];
   reg        rx_valid_dly       [DELAY_DATA-1:0];
   reg [15:0] rx_data_dly        [DELAY_DATA-1:0];

   integer i;
   always @(posedge cc_clk) begin
      pgen_disable_dly[0]   <= pgen_disable;
      pgen_rate_dly[0]      <= pgen_rate;
      pgen_test_mode_dly[0] <= pgen_test_mode;
      pgen_inc_step_dly[0]  <= pgen_inc_step;
      pgen_usr_data_dly[0]  <= pgen_usr_data;
      for ( i = 1; i < DELAY_REG; i++) begin
         pgen_disable_dly[i]  <= pgen_disable_dly[i-1];
         pgen_rate_dly[i]     <= pgen_rate_dly[i-1];
         pgen_test_mode_dly[i]<= pgen_test_mode_dly[i-1];
         pgen_inc_step_dly[i] <= pgen_inc_step_dly[i-1];
         pgen_usr_data_dly[i] <= pgen_usr_data_dly[i-1];
      end
   end
   always @(posedge tx_clk) begin
      rx_valid_dly[0] <= tx_valid;
      rx_data_dly[0]  <= tx_data;
      for (i = 1; i < DELAY_DATA; i++) begin
         rx_valid_dly[i] <= rx_valid_dly[i-1];
         rx_data_dly[i]  <= rx_data_dly[i-1];
      end
   end

   assign rx_valid = rx_valid_dly[DELAY_DATA-1];

   patt_gen #(
      .DWI     (16),
      .P_CHECK (1))
   i_dut_check (
      .lb_clk         (cc_clk),
      .pgen_disable   (pgen_disable_dly[DELAY_REG-1]),
      .pgen_rate      (pgen_rate_dly[DELAY_REG-1]),
      .pgen_test_mode (pgen_test_mode_dly[DELAY_REG-1]),
      .pgen_inc_step  (pgen_inc_step_dly[DELAY_REG-1]),
      .pgen_usr_data  (pgen_usr_data_dly[DELAY_REG-1]),
      .clk            (tx_clk),
      .tx_valid       (),
      .tx_data        (),
      .rx_valid       (rx_valid),
      .rx_data        (rx_data_dly[DELAY_DATA-1]),
      .rx_match       (rx_match),
      .rx_err_cnt     (rx_err_cnt)
   );

endmodule
