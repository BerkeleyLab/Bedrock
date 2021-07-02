/* rr_arb
   Generic round-robin arbiter based on request-grant handshake.
   Can be used as is or can be taken as an example of how the rr_next() function
   can be incorporated into other designs.
*/

module rr_arb #(
   parameter NREQ = 2
) (
   input             clk,
   input  [NREQ-1:0] req_bus,
   output [NREQ-1:0] grant_bus
);
   localparam NREQ_LOG2 = $clog2(NREQ);

   function [NREQ-1:0] rr_next;
      input [NREQ-1:0] reqs;
      input [NREQ-1:0] base;
      reg [NREQ*2-1:0] double_req;
      reg [NREQ*2-1:0] double_grant;
   begin
      double_req = {reqs, reqs};
      double_grant = ~(double_req - base) & double_req;
      rr_next = double_grant[NREQ*2-1:NREQ] | double_grant[NREQ-1:0];
   end endfunction

   reg [NREQ-1:0] base=1; // one-hot encoded
   always @(posedge clk) begin
      if (|(grant_bus & req_bus)) base <= base << 1 | base[NREQ-1];
   end

   assign grant_bus = rr_next(req_bus, base);

endmodule
