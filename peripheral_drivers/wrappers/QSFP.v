`timescale 1ns / 1ns
module QSFP (
   input  IntL,
   output LPMode,
   input  ModPrsL,
   output ModSelL,
   output ResetL,
   input  Rx1n,
   input  Rx1p,
   input  Rx2n,
   input  Rx2p,
   input  Rx3n,
   input  Rx3p,
   input  Rx4n,
   input  Rx4p,
   output Tx1n,
   output Tx1p,
   output Tx2n,
   output Tx2p,
   output Tx3n,
   output Tx3p,
   output Tx4n,
   output Tx4p,

   input        sysclk,
   input  [3:0] gtrefclk,
   input  [3:0] gtrefclkbuf,
   input  [3:0] soft_reset,
   input  [3:0] gt_txusrrdy,
   input  [3:0] gt_rxusrrdy,
   input  [3:0] txusrclk,
   input  [3:0] rxusrclk,
   output [3:0] txoutclk,
   output [3:0] rxoutclk,
   output [3:0] rxbyteisaligned,
   input  [4*20-1:0] gt_txdata,
   output [4*20-1:0] gt_rxdata,
   input  resetl,
   output modprsl,
   input  lpmode,
   input  modsel
);

   OBUF lpmode_obuf(.I(lpmode),.O(LPMode));
   OBUF resetl_obuf(.I(resetl),.O(ResetL));
   OBUF modsel_obuf(.I(modsel),.O(ModSelL));

   assign modprsl = ModPrsL;  // Module Present bit sent to application

   wire [3:0] RXN, RXP, TXN, TXP;

   assign RXN = {Rx4n,Rx3n,Rx2n,Rx1n};
   assign RXP = {Rx4p,Rx3p,Rx2p,Rx1p};
   assign {Tx4n,Tx3n,Tx2n,Tx1n} = TXN;
   assign {Tx4p,Tx3p,Tx2p,Tx1p} = TXP;

   gtx #(.CHAN(4)) i_gtx(
      .gtrefclk        (gtrefclk),
      .gtrefclkbuf     (gtrefclkbuf),
      .RXN             (RXN),
      .RXP             (RXP),
      .TXN             (TXN),
      .TXP             (TXP),
      .sysclk          (sysclk),
      .soft_reset      (soft_reset),
      .txusrclk        ({txusrclk[3:0]}),
      .rxusrclk        ({rxusrclk[3:0]}),
      .txoutclk        ({txoutclk[3:0]}),
      .rxoutclk        ({rxoutclk[3:0]}),
      .gt_txusrrdy_in  (gt_txusrrdy),
      .gt_rxusrrdy_in  (gt_rxusrrdy),
      .rxbyteisaligned (rxbyteisaligned),
      .gt_txdata       (gt_txdata),
      .gt_rxdata       (gt_rxdata)
   );

endmodule
