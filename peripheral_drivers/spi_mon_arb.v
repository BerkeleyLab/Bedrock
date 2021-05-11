module spi_mon_arb #(
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

   reg [NREQ-1:0] base=1;
   always @(posedge clk) begin
      // Allow current requester as long as it needs (at the risk of livelocking)
      if ((grant_bus & req_bus) == 0)
         base <= rr_next(req_bus, base);
   end

   assign grant_bus = base;

endmodule
