/* N stages of additional routing pipeline for a localbus interface
*/

module lb_delay #(
  parameter NSTAGES = 0,
  parameter LB_DW = 32,
  parameter LB_AW = 21
) (
  input  clk,
  // Host-side interface (connect to host)
  input  h_lb_wen,
  input  [LB_AW-1:0] h_lb_addr,
  input  [LB_DW-1:0] h_lb_wdata,
  output [LB_DW-1:0] h_lb_rdata,
  input  h_lb_wstb,
  input  h_lb_rstb,
  // Peripheral-side interface (connect to peripheral)
  output p_lb_wen,
  output [LB_AW-1:0] p_lb_addr,
  output [LB_DW-1:0] p_lb_wdata,
  input  [LB_DW-1:0] p_lb_rdata,
  output p_lb_wstb,
  output p_lb_rstb
);

integer N;
generate
  if (NSTAGES == 0) begin : passthrough
    assign p_lb_wen = h_lb_wen;
    assign p_lb_addr = h_lb_addr;
    assign p_lb_wdata = h_lb_wdata;
    assign h_lb_rdata = p_lb_rdata; // ptoh
    assign p_lb_wstb = h_lb_wstb;
    assign p_lb_rstb = h_lb_rstb;
  end else begin :          pipeline
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] lb_wen=0;
    assign p_lb_wen = lb_wen[NSTAGES-1];
    (* KEEP="TRUE" *) reg [LB_AW-1:0] lb_addr [0:NSTAGES-1];
    assign p_lb_addr = lb_addr[NSTAGES-1];
    (* KEEP="TRUE" *) reg [LB_DW-1:0] lb_wdata [0:NSTAGES-1];
    assign p_lb_wdata = lb_wdata[NSTAGES-1];
    (* KEEP="TRUE" *) reg [LB_DW-1:0] lb_rdata [0:NSTAGES-1];
    assign h_lb_rdata = lb_rdata[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] lb_wstb=0;
    assign p_lb_wstb = lb_wstb[NSTAGES-1];
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] lb_rstb=0;
    assign p_lb_rstb = lb_rstb[NSTAGES-1];
    always @(posedge clk) begin
      lb_wen[0] <= h_lb_wen;
      lb_addr[0] <= h_lb_addr;
      lb_wdata[0] <= h_lb_wdata;
      lb_rdata[0] <= p_lb_rdata; // ptoh
      lb_wstb[0] <= h_lb_wstb;
      lb_rstb[0] <= h_lb_rstb;
      for (N=1; N < NSTAGES; N = N + 1) begin
        lb_wen[N] <= lb_wen[N-1];
        lb_addr[N] <= lb_addr[N-1];
        lb_wdata[N] <= lb_wdata[N-1];
        lb_rdata[N] <= lb_rdata[N-1];
        lb_wstb[N] <= lb_wstb[N-1];
        lb_rstb[N] <= lb_rstb[N-1];
      end
    end
  end
endgenerate

endmodule


