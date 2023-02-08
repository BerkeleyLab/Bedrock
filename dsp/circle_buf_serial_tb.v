`timescale 1ns / 1ns

module circle_buf_serial_tb;
   parameter NCHAN = 8;
   parameter CHAN_MASK = 170;

   localparam MAX_ERROR = 10; // Limit error reporting

   function [7:0] count_ones;
      input [NCHAN-1:0] mask;
      integer i, acc;
   begin
      acc=0;
      for (i=NCHAN-1; i >=0 ; i=i-1) begin
         if (mask[i]) acc = acc+1;
      end
      count_ones=acc;
   end
   endfunction

   reg iclk;
   integer cc, errors;
   integer num_tx_out=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("circle_buf_serial.vcd");
         $dumpvars(5,circle_buf_serial_tb);
      end
      errors = 0;
      for (cc=0; cc<4000; cc=cc+1) begin
         iclk=0; #5;
         iclk=1; #5;
      end
      if (num_tx_out == 0) begin
         $display("ERROR: No transactions, nothing was tested.");
         errors = errors + 1;
      end
      $display("%d errors", errors);
      if (errors > 0) $stop("FAIL");
      else $finish("PASS");
   end

   reg oclk=0;
   always begin
      oclk=0; #3;
      oclk=1; #3;
   end

   // Source emulation
   reg [15:0] d_in=0;
   reg stop=0;
   reg [NCHAN-1:0] chan_mask=0;
   reg [7:0] count_on=0;
   reg stb_in;
   reg [7:0] chan_active_count; // TODO: Size channel counts properly

   integer chan_count=0;
   always @(negedge iclk) begin
      // TODO: Create pseudo-random gaps in stb_in
      if (count_on==0 && (cc%4==2)) begin
         count_on <= NCHAN;
         stb_in <= 1'b1;
      end else begin
         if (count_on)
            count_on <= count_on - 1;
      end

      if (stb_in)
         chan_count <= (chan_count+1)%NCHAN;

      stop <= cc==1500 || cc==2200;
      chan_mask <= CHAN_MASK; // TODO: Make this pseudo-random for each TB run/seed.
   end
   always @(*) begin
      stb_in = (count_on!=0);
      d_in   = {chan_count[7:0], cc[7:0]};
      chan_active_count = count_ones(chan_mask);
   end

   // Readout emulation
   reg [5:0] read_addr=0;
   reg stb_out=0, odata_val=0;
   reg [1:0] ocnt=0;
   wire enable;
   wire otrig=(ocnt==3) & enable;
   integer frame=0;
   always @(posedge oclk) begin
      ocnt <= ocnt+1;
      if (otrig) read_addr <= read_addr+1;
      if (otrig & (&read_addr)) frame <= frame+1;
      stb_out <= otrig;
      odata_val <= stb_out;
   end

   // Instantiate Device Under Test
   wire [15:0] d_out, buf_stat;
   circle_buf_serial #(.n_chan(NCHAN),
                       .lsb_mask(1),
                       .buf_aw(6),
                       .buf_dw(16),
                       .buf_stat_w(16),
                       .buf_auto_flip(1))
   dut(.iclk      (iclk),
      .reset     (1'b0),
      .sr_in     (d_in),
      .sr_stb    (stb_in),
      .chan_mask (chan_mask),
      .oclk      (oclk),
      .buf_sync  (),
      .buf_transferred (),
      .buf_stop  (stop),
      .buf_count (),
      .buf_stat2 (),
      .buf_stat  (buf_stat),
      .debug_stat (),
      .stb_out   (stb_out),
      .enable    (enable),
      .read_addr (read_addr),
      .d_out     (d_out)
   );

   // Check result
   reg [7:0] prev_read=0;
   wire [5:0] save_addr=buf_stat[5:0];
   wire record_type=buf_stat[15];
   reg mismatch=0, buffer_mark=0;

   wire [7:0] data_out, cur_chan;
   reg [7:0] prev_chan;

   assign cur_chan = d_out[15:8];
   assign data_out = d_out[7:0];

   always @(posedge oclk) if (odata_val) begin
      prev_chan  <= cur_chan;
      prev_read  <= d_out;
      buffer_mark = (save_addr == read_addr) & ~record_type;

      mismatch = 0;
      if (errors < MAX_ERROR)
         if (~buffer_mark && (read_addr != 0) && frame >1) begin
            num_tx_out <= num_tx_out + 1;

            if (~chan_mask[cur_chan]) begin
               mismatch = 1;
               $display("%t ERROR: Read a channel that shouldn't have been active", $time);
            end
            if (chan_active_count != 1 && (cur_chan == prev_chan)) begin
               mismatch = 1;
               $display("%t ERROR: Received the same channel back to back", $time);
            end
            if (cur_chan > prev_chan) begin
               if (data_out-prev_read != cur_chan-prev_chan) begin
                  mismatch = 1;
                  $display("%t ERROR: Failed sample comparison", $time);
               end
            end
         end
      if (mismatch) errors = errors+1;
   end
endmodule
