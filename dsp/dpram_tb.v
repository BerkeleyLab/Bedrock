`timescale 1ns / 1ps

module dpram_tb;

   localparam SIM_TIME = 50000; // ns

   localparam CLK_RW_PERIOD = 10;
   localparam CLK_RO_PERIOD = 20;

   localparam ADDR_WI = 8;
   localparam DATA_WI = 10;
   localparam MEM_SIZE = (1<<ADDR_WI);

   reg clk_rw = 0;
   reg clk_ro = 0;
   integer seed_int;

   wire fail;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("dpram.vcd");
         $dumpvars(5, dpram_tb);
      end
      if (!$value$plusargs("seed=%d", seed_int))
         seed_int = 12345;
      $display("SEED = %d", seed_int);

      while ($time < SIM_TIME) @(posedge clk_rw);

      if (~fail) begin
         $display("PASS");
         $finish;
      end else begin
         $display("FAIL");
         $stop;
      end
   end

   always begin clk_rw = ~clk_rw; #(CLK_RW_PERIOD/2); end
   always begin clk_ro = ~clk_ro; #(CLK_RO_PERIOD/2); end

   // ----------------------
   // Generate stimulus
   // ----------------------
   reg  [ADDR_WI-1:0] addra=0;
   wire [DATA_WI-1:0] dina;
   wire [DATA_WI-1:0] douta;
   reg wena=0;

   reg  [ADDR_WI-1:0] addrb=0;
   reg  [DATA_WI-1:0] dinb;
   wire [DATA_WI-1:0] doutb;

   reg [DATA_WI-ADDR_WI-1:0] wr_count=0;

   always @(posedge clk_rw) begin
      wena <= 1'b0;
      if (($urandom(seed_int) % 10) > 6) begin
         addra <= addra + 1;
         wena  <= 1'b1;

         if (&addra)
            wr_count <= wr_count + 1;
      end
   end

   assign dina = {wr_count, addra}; // Data contents are mostly irrelevant

   always @(posedge clk_ro) begin
      addrb <= $urandom(seed_int) % MEM_SIZE;
   end

   // ----------------------
   // Instantiate DUT
   // ----------------------

   dpram #(
      .aw (ADDR_WI),
      .dw (DATA_WI))
   i_dut (
      // Read-Write interface
      .clka  (clk_rw),
      .addra (addra),
      .douta (douta),
      .dina  (dina),
      .wena  (wena),

      // Read-Only interface
      .clkb  (clk_ro),
      .addrb (addrb),
      .doutb (doutb)
   );

   // ----------------------
   // Scoreboarding
   // ----------------------

   reg [DATA_WI-1:0] mem_model[MEM_SIZE-1:0];
   reg [MEM_SIZE-1:0] init_mask = 0;

   // dpram guarantees one-cycle read and write latency
   reg  [ADDR_WI-1:0] addra_r=0;
   reg  [ADDR_WI-1:0] addrb_r=0;
   wire [DATA_WI-1:0] douta_model;
   wire [DATA_WI-1:0] doutb_model;
   reg fail_a=0, fail_b=0;

   assign douta_model = (init_mask[addra_r]) ? mem_model[addra_r] : 0;
   assign doutb_model = (init_mask[addrb_r]) ? mem_model[addrb_r] : 0;

   always @(posedge clk_rw) begin
      addra_r <= addra;

      if (wena) begin
         mem_model[addra] <= dina;
         init_mask[addra] <= 1'b1;
      end

      if (douta != douta_model) begin
         $display("ERROR %t: Mismatch in port A. Expected: %d. Received: %d", $time, douta_model, douta);
         fail_a <= 1;
      end
   end

   always @(posedge clk_ro) begin
      addrb_r <= addrb;

      if (doutb != doutb_model) begin
         $display("ERROR %t: Mismatch in port B. Expected: %d. Received: %d", $time, doutb_model, doutb);
         fail_b <= 1;
      end
   end

   assign fail = fail_a | fail_b;

endmodule
