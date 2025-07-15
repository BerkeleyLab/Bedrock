`timescale 1ns / 1ns

/** SERIALIZER_MULTICHANNEL **
    Conveyor belt generator which takes a generic number of input vectors (flattened)
    and samples them into a shift-based conveyor belt.

               sample_in
                   +
                   |
         +---------v-------------+
         |               +-----+ |
d_in[0]+----------------->  S  +---> stream_out
         |               +--^--+ |
         |        +-----+   |    |
d_in[1]+---------->  S  +---+    |
         |        +--^--+        |
         | +-----+   |           |
d_in[N]+--->  S  +---+           |
         | +-----+               |
         +-----------------------+
*/

`ifdef SIMULATE
`define FILL_BIT 1'bx
`else
`define FILL_BIT 1'b0
`endif

module serializer_multichannel #(
   parameter n_chan = 8, // Number of channels to serialize
   parameter dw = 16,
   parameter l_to_r=1  // l_to_r=1: Channel shifting starts with CH0 (default)
                       // l_to_r=0: Channel shifting starts with last CH
) (
   input                 clk,
   input                 sample_in, // Sampling signal which determines when to push inputs to belt
   input [n_chan*dw-1:0] data_in,   // Flattened array of unprocessed data streams
   output                gate_out,
   output [dw-1:0]       stream_out // Serialized stream of channels. Default order is CH0 first (l_to_r=1)
);
   wire [dw-1:0] shift_chain[n_chan:0]; // +1 for feed-out
   wire          shift_gate[n_chan:0]; // +1 for feed-out
   wire [dw-1:0] sr_in[n_chan-1:0];


   assign shift_chain[0] = {dw{`FILL_BIT}}; // initialize shift-chain
   assign shift_gate[0]  = 1'b0;

   genvar ch_id;
   generate for (ch_id=0; ch_id < n_chan; ch_id=ch_id+1) begin : g_serializer
      if (l_to_r == 0) begin : g_l_to_r  // CH0 first
         assign sr_in[ch_id] = data_in[(n_chan-ch_id)*dw-1: (n_chan-ch_id-1)*dw];
      end else begin : g_r_to_l
         assign sr_in[ch_id] = data_in[(ch_id+1)*dw-1: ch_id*dw];
      end

      serialize #(
         .dwi(dw))
      i_serialize_ch
      (
         .clk        (clk),
         .samp       (sample_in),
         .data_in    (sr_in[ch_id]),
         .stream_in  (shift_chain[n_chan - ch_id - 1]),
         .stream_out (shift_chain[n_chan - ch_id]),
         .gate_in    (shift_gate[n_chan - ch_id -1]),
         .gate_out   (shift_gate[n_chan - ch_id]),
         .strobe_out () // Open - unused
      );
   end endgenerate

   assign gate_out   = shift_gate[n_chan];
   assign stream_out = shift_chain[n_chan];

endmodule
