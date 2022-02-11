`timescale 1ns / 1ns

/** CIRCLE_BUF_SERIAL **
    Double-buffered circular buffer wrapper with channel selector.
    This module takes a conveyor belt carrying multiple channels as an input
    and writes the channels selected by chan_mask into the Circular Buffer.
    Circular buffer can be read out at a different clock rate through the local bus.

          +------------------------+
          | +-----+    +--------+  |
  sr_in+---->     |    |        <-----+ rd_addr/val
          | |fchan+----> Circle |  |
  mask +----> sel |    | Buf    |  |
          | |     |    |        +-----> d_out
          | +-----+    +--------+  |
          +------------------------+
*/

module circle_buf_serial #(
   // Channel selector parameters
   parameter n_chan=12,
   parameter lsb_mask=0,      // lsb_mask=0: chan_mask is LEFT-to-RIGHT; MSB=CH0
                              // lsb_mask=1: chan_mask is RIGHT-to-LEFT; LSB=CH0

   // Circular Buffer parameters
   parameter buf_dw=16,
   parameter buf_aw=13,
   parameter buf_stat_w=16,
   parameter buf_auto_flip=1) // auto_flip=1: Double buffers will be flipped when
                              //              last read address is reached
                              // auto_flip=0: Buffers must be explicitly flipped by
                              //              using stb_out as a pulse and not a strobe
(
   // Incoming stream
   input                    iclk,
   input                    reset,
   input [buf_dw-1:0]       sr_in, // Conveyor belt carrying n_chan channels
   input                    sr_stb,

   // Channel selector controls
   input [n_chan-1:0]       chan_mask, // Bitmask of channels to record. See lsb_mask parameter
   // Selected waveform data in iclk domain
   output                   wave_gate,
   output                   wave_dval,
   output                   [buf_dw-1:0] wave_data,

   // Circular Buffer control and statistics
   // all of these signals are also in the iclk domain
   output                   buf_sync,        // single-cycle when buffer starts/ends
   output                   buf_transferred, // single-cycle when a buffer has been
                                             // handed over for reading;
                                             // one cycle delayed from buf_sync
   input                    buf_stop,        // single-cycle - interrupts cbuf writing
   output [buf_stat_w-1:0]  buf_count,
   output [buf_aw-1:0]      buf_stat2,       // includes fault bit
   output [buf_stat_w-1:0]  buf_stat,        // includes fault bit, and (if set) the last valid location
   output [buf_aw+4:0]      debug_stat,      // {stb_in, boundary, btest, wbank, rbank, wr_addr}

   // Circular Buffer data readout
   input                    oclk,
   input                    stb_out,
   output                   enable,
   input  [buf_aw-1:0]      read_addr, // nominally 8192 locations
   output [buf_dw-1:0]      d_out
);

   // ------
   // Interleaved channel selector
   // ------
   wire              fchan_time_error; // For debug only - will pulse if gate-per-trigger ratio is broken
   wire              wave_trig;
   assign            wave_dval = ~wave_trig;

   fchan_subset #(
      .KEEP_OLD (lsb_mask),
      .a_dw     (buf_dw),
      .o_dw     (buf_dw),
      .len      (n_chan))
   i_fchan_subset (
      .clk      (iclk),
      .reset    (reset),
      .keep     (chan_mask),
      .a_data   (sr_in),
      .a_gate   (sr_stb),
      .a_trig   (~sr_stb),
      .o_data   (wave_data),
      .o_gate   (wave_gate),
      .o_trig   (wave_trig),
      .time_err (fchan_time_error)
   );

`ifdef SIMULATE
   always @(negedge iclk) if (fchan_time_error) begin
      $display("ERROR: Gate-per-Trigger ratio violated in fchan_selector.");
      $finish;
   end
`endif

   // ------
   // Double-buffered circular buffer
   // ------

   circle_buf #(
      .aw        (buf_aw),
      .dw        (buf_dw),
      .auto_flip (buf_auto_flip))
   i_circle_buf (
      .iclk            (iclk),
      .d_in            (wave_data),
      .stb_in          (wave_gate),
      .boundary        (wave_trig),
      .stop            (buf_stop),
      .buf_sync        (buf_sync),
      .buf_transferred (buf_transferred),
      .oclk            (oclk),
      .enable          (enable),
      .read_addr       (read_addr),
      .d_out           (d_out),
      .stb_out         (stb_out),
      .buf_count       (buf_count),
      .buf_stat        (buf_stat),
      .debug_stat      (debug_stat),
      .buf_stat2       (buf_stat2)
   );

endmodule
