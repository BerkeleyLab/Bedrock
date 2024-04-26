`timescale 1ns / 1ns

module jxj_gate_tb;

   localparam RX_SPACING = 1; // TODO: Randomly generate spacing, including 1
   localparam NUM_WORDS = 32;

   localparam max_data_len=1024;
   reg [7:0] pack_mem [0:max_data_len-1];

   reg clk;
   integer cc;
   reg [127:0] packet_file;
   integer data_len, udp_port;
   reg use_packfile;

   reg fail = 0;

   initial begin
      use_packfile = $value$plusargs("packet_file=%s", packet_file);
      if (use_packfile) $readmemh(packet_file,pack_mem);
      if (!$value$plusargs("data_len=%d", data_len))  data_len= NUM_WORDS;
      if ($value$plusargs("udp_port=%d", udp_port))  udp_port=0;
      if ($test$plusargs("vcd")) begin
         $dumpfile("jxj_gate.vcd");
         $dumpvars(5,jxj_gate_tb);
      end
      for (cc=0; (udp_port!=0) || (cc<800); cc=cc+1) begin
         clk=0; #10;
         clk=1; #10;
      end
      if (fail) begin
        $display("FAIL");
        $stop(0);
      end else begin
        $display("PASS");
        $finish(0);
      end
   end

   // Simple test data that reads registers 0 through 3
   localparam WORD_LEN = 8; // bits
   localparam RTEST_LEN = 4;
   reg [0:WORD_LEN*NUM_WORDS-1] rtest_trace[RTEST_LEN-1:0];
   reg [0:WORD_LEN*NUM_WORDS-1] rtest_model[RTEST_LEN-1:0];
   reg [0:31] reg_data[RTEST_LEN-1:0];
   integer i;
   initial begin
      // NONCE + (COMMAND0 + ADDRESS0) + DATA0 + (COMMAND1 + ADDRESS1) + DATA1
      rtest_trace[0] = {64'h123456789ABCDEF0, 32'h00000000, 32'h00000001, 32'h00000001, 32'h00000002, 32'h00000002, 32'h00000003}; // Write
      rtest_trace[1] = {64'hFEDCBA9876543210, 32'h10000000, 32'h00000000, 32'h10000001, 32'h00000000, 32'h10000002, 32'h00000000};
      rtest_trace[2] = {64'h123456789ABCDEF0, 32'h10000000, 32'h00000000, 32'h10000001, 32'h00000000, 32'h10000002, 32'h00000000};
      rtest_trace[3] = {64'hFEDCBA9876543210, 32'h10000000, 32'h00000000, 32'h10000001, 32'h00000000, 32'h10000002, 32'h00000000};
      // Expected response
      reg_data[0] = "Hell";
      reg_data[1] = "o wo";
      reg_data[2] = "rld!";
      reg_data[3] = 32'h0d0a0d0a;
      // Expected stream
      for (i=0; i<RTEST_LEN-1; i++) begin
         rtest_model[i] = rtest_trace[i];
         rtest_model[i][96:127] = reg_data[0];
         rtest_model[i][160:191] = reg_data[1];
         rtest_model[i][224:255] = reg_data[2];
      end
   end

   // Simulated Rx data
   reg [7:0] rx_din;
   reg rx_stb=0, rx_end=0;

   // Simulated Tx data
   wire [7:0] tx_dout;
   wire tx_rdy, tx_end;
   wire tx_stb;

   // Local bus
   wire [23:0] lb_addr;
   reg [23:0] lb_addr_r;
   wire [31:0] lb_dout;
   reg [31:0] lb_din;
   wire lb_strobe, lb_rd, lb_prefill;

   jxj_gate dut(.clk(clk),
      .rx_din(rx_din), .rx_stb(rx_stb), .rx_end(rx_end),
      .tx_dout(tx_dout), .tx_rdy(tx_rdy), .tx_end(tx_end), .tx_stb(tx_stb),
      .lb_addr(lb_addr), .lb_dout(lb_dout), .lb_din(lb_din),
      .lb_strobe(lb_strobe), .lb_rd(lb_rd), .lb_prefill(lb_prefill)
   );

   // Simulate Rx data
   integer ci=0;
   integer reg_idx=0;
   integer wrd_idx=0;
   integer skip;
   always @(posedge clk) begin
      rx_din <= 8'hxx;
      rx_stb <= 0;
      rx_end <= 0;

      skip = $urandom % 100;
      if (skip < 80) begin
         ci = (ci+1) % (data_len*RX_SPACING+150);
         if ((ci>=100) & (ci<(100+data_len*RX_SPACING)) & (ci%RX_SPACING==0)) begin
            rx_stb <= 1;
            if (use_packfile) begin
               rx_din <= pack_mem[(ci-100)/RX_SPACING];
               rx_end <= (ci==(99+data_len*RX_SPACING));
            end else begin
               rx_din <= rtest_trace[reg_idx][WORD_LEN*wrd_idx+: WORD_LEN];

               rx_end  <= (wrd_idx==(NUM_WORDS-1));
               wrd_idx <= (wrd_idx + 1) % NUM_WORDS;
               reg_idx <= (wrd_idx==(NUM_WORDS-1)) ? reg_idx + 1 : reg_idx;
            end
         end
      end
   end

   `define NO_TX
   `ifdef NO_TX
   // Strobe to get Tx data
   reg tx_stb_r=0;
   reg [3:0] tx_cnt=0;
   always @(posedge clk) begin
      tx_cnt <= tx_cnt==8 ? 0 : tx_cnt+1;
      tx_stb_r <= (tx_cnt==0) & tx_rdy;
   end
   assign tx_stb = 1; //tx_stb_r;
   `else
   wire data_out_pin;
   // tx_8b9b drives tx_stb
   tx_8b9b i_tx_8b9b (.clk(clk), .data_out(data_out_pin), .word_in(tx_dout),
                      .word_available(tx_rdy), .frame_complete(tx_end), .word_read(tx_stb));
   `endif

   //always @(negedge clk) if (tx_stb) $display("Tx %x",tx_dout);

   // Just for grins, see if the Rx module works
   // Synthesize 4 x sampled waveform.
   // According to comments in oversampled_rx_8b9b,
   // "int_data(0) is first to arrive, int_data(3) is last"
   `ifndef NO_TX
   reg [7:0] comm_wave=0;
   reg transition;
   always @(posedge clk) begin
      transition = data_out_pin;
      if (comm_wave[7] != transition) transition = $random;
      comm_wave <= {{3{data_out_pin}},transition,comm_wave[7:4]};
   end
   wire [3:0] int_data = comm_wave[5-:4];
   oversampled_rx_8b9b #(.word_width(8)) i_oversampled_rx_8b9b (
      .clk(clk),
      .sync_reset(cc<10),
      .int_data(int_data),
      .enable(1'b1));
   `endif

   // Simple test rig
   always @(posedge clk) begin
      if (lb_strobe)
         lb_addr_r <= lb_addr;

      case (lb_addr_r[2:0])
      0: lb_din <= reg_data[0];
      1: lb_din <= reg_data[1];
      2: lb_din <= reg_data[2];
      3: lb_din <= reg_data[3];
      endcase
   end

   // Simple scoreboard based on simple test rig and register trace

   integer r_idx = 0;
   integer w_idx = 0;
   reg [WORD_LEN-1:0] wrd_model;
   always @(posedge clk) begin
      if (tx_stb && tx_rdy) begin
         wrd_model = rtest_model[r_idx][WORD_LEN*w_idx+: WORD_LEN];
         if (tx_dout != wrd_model) begin
            $display("%t ERROR. Expected %x, got %x", $time, wrd_model, tx_dout);
            fail <= 1;
         end
         if (tx_end && w_idx != NUM_WORDS-1) begin
            $display("%t ERROR. Unexpected tx_end", $time);
            fail <= 1;
         end
         if (!tx_end && w_idx == NUM_WORDS-1) begin
            $display("%t ERROR. Expected tx_end", $time);
            fail <= 1;
         end
         w_idx <= (w_idx + 1) % NUM_WORDS;
         r_idx <= (w_idx==(NUM_WORDS-1)) ? r_idx + 1 : r_idx;
      end
   end

endmodule
