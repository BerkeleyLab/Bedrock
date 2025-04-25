// File ep_tx_pcs.vhd translated with vhd2vl v2.3 VHDL to Verilog RTL translator
// see http://doolittle.icarus.com/~larry/vhd2vl/
// Substantial post-translation modifications by Larry Doolittle
// Now has GMII-ish input!
// Eats zero or one preamble octets, inevitable due to even/odd PMA asymmetry

//-----------------------------------------------------------------------------
// Title      : Optical 1000base-X endpoint - PMA interface - transmit path logic
// Project    : WhiteRabbit switch
//-----------------------------------------------------------------------------
// File       : ep_tx_pcs.vhd
// Author     : Tomasz Wlostowski
// Company    : CERN BE-CO-HT section
// Created    : 2009-06-16
// Last update: 2010-06-03
// Platform   : FPGA-generic
// Standard   : VHDL'87
//-----------------------------------------------------------------------------
// Description: Module implements 802.1x transmit PCS - block which
// interfaces the Ethernet framer to TX PMA (physical medium attachment). It
// performs preamble generation, inserting idle patterns, 802.1x link
// negotiation and all the low-level signalling stuff (including 8b10b coding).
// Strobing signal for taking TX timestamps is also generated.
//
// Module uses two separate clocks: 125 MHz tbi_tx_clk (Transmit clock for PHY)
// which clocks 8b10b signalling layer, and 62.5 MHz REFCLK/2 which is used for
// data exchange with the rest of switch. Data exchange between these clock domains
// is done using an async FIFO.
//-----------------------------------------------------------------------------
// Copyright (c) 2009 Tomasz Wlostowski
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author   Description
// 2009-06-16  0.1      twlostow Created (no error propagation supported yet)
// 2010-04-06  0.2      twlostow Cleanup, new timestamping/LCR scheme
//-----------------------------------------------------------------------------
// no timescale needed

module ep_tx_pcs(
input clk,  // single clock domain, fully deterministic
input rst,
//-----------------------------------------------------------------------------
// GMII-ish input port
input [7:0] tx_data_i,
input tx_enable,
//-----------------------------------------------------------------------------
// output to serdes
output reg [7:0] tx_odata_reg,
output reg tx_is_k,
input disparity_i,  // Xilinx serdes computes this for us?
//-----------------------------------------------------------------------------
// control signals
//-----------------------------------------------------------------------------
input ep_tcr_en_pcs_i, // Transmit Control Register, EN_PCS field
input [15:0] ep_lacr_tx_val_i, // Link Autonegotiation Control Register, TX_VAL field
input ep_lacr_tx_en_i // Link Autonegotiation Control Register, TX_EN field
);

`include "endpoint.vh"

parameter INDENT = "";

// TX state machine definitions
parameter [3:0]
  TX_COMMA = 0,
  TX_CR1 = 1,
  TX_CR2 = 2,
  TX_CR3 = 3,
  TX_CR4 = 4,
  TX_SPD = 5,
  TX_IDLE = 6,
  TX_DATA = 7,
  TX_EPD = 8,
  TX_EXTEND = 9;

initial begin
  tx_odata_reg=0;
  tx_is_k=0;
end

reg [3:0] tx_state=TX_COMMA;
reg tx_cr_alternate=0;
reg tx_odd_length=0;

// Two stages of passive data pipeline
reg [7:0] tx_data_p=0, tx_data_p2=0;
always @(posedge clk) tx_data_p <= tx_data_i;
always @(posedge clk) tx_data_p2 <= tx_data_p;
reg tx_enable_p=0;
`ifdef SIMULATE
reg [15:0] old_ep_lacr_tx_val_i=16'hffff;
`endif
always @(posedge clk) tx_enable_p <= tx_enable;

  always @(posedge clk) begin
    if((rst)) begin
      tx_state <= TX_COMMA;
      tx_odata_reg <= {8{1'b0}};
      tx_is_k <= 1'b 1;
      tx_cr_alternate <= 1'b 0;
      tx_odd_length <= 1'b 0;
    end
    else begin
      if((ep_tcr_en_pcs_i == 1'b 0)) begin
        tx_state <= TX_COMMA;
        tx_cr_alternate <= 1'b 0;
      end
      else begin
        case(tx_state)
        TX_COMMA : begin
          tx_is_k <= 1'b 1;
          tx_odata_reg <= c_k28_5;
          tx_state <= TX_IDLE;
        end
        TX_IDLE : begin
          // endpoint wants to send LCR register by pulsing tx_cr_send_i
          if((ep_lacr_tx_en_i == 1'b 1)) begin
            tx_state <= TX_CR1;
            tx_cr_alternate <= 1'b 0;
            // we've read something from the FIFO and it indicates a beginning of new frame
          end
          else if(tx_enable) begin
            tx_state <= TX_SPD;
          end
          else begin
            // continue sending idle sequences
            tx_state <= TX_COMMA;
          end
          tx_is_k <= 1'b 0;
          tx_odata_reg <= disparity_i ? c_d5_6 : c_d16_2;
        end
        TX_CR1 : begin
          tx_is_k <= 1'b 1;
          tx_odata_reg <= c_k28_5;
          tx_state <= TX_CR2;
        end
        TX_CR2 : begin
          tx_is_k <= 1'b 0;
          tx_odata_reg <= tx_cr_alternate ? c_d21_5 : c_d2_2;
          tx_cr_alternate <=  ~tx_cr_alternate;
          tx_state <= TX_CR3;
        end
        TX_CR3 : begin
          tx_odata_reg <= ep_lacr_tx_val_i[7:0]; // Little endian
          tx_state <= TX_CR4;
        end
        TX_CR4 : begin
          `ifdef SIMULATE
            if (old_ep_lacr_tx_val_i != ep_lacr_tx_val_i) begin
              if (ep_lacr_tx_val_i == 0) begin
                $display("%s(%t) Transmitting breaklink", INDENT, $stime);
              end else begin
                $display("%s(%t) Transmitting 0x%x", INDENT, $stime, ep_lacr_tx_val_i);
              end
            end
            old_ep_lacr_tx_val_i <= ep_lacr_tx_val_i;
          `endif
          tx_odata_reg <= ep_lacr_tx_val_i[15:8];
          if((ep_lacr_tx_en_i == 1'b 1)) begin
            tx_state <= TX_CR1;
          end
          else begin
            tx_state <= TX_COMMA;
          end
        end
        TX_SPD : begin
          tx_is_k <= 1'b 1;
          tx_odata_reg <= c_k27_7;
          tx_odd_length <= 1'b 1;
          tx_state <= TX_DATA;
        end
        TX_DATA : begin
          tx_is_k <= 1'b 0;
          // send actual data
          tx_odata_reg <= tx_data_p2;
          // handle the end of frame both for even- and odd-length frames
          tx_odd_length <= ~tx_odd_length;
          if(~tx_enable_p) tx_state <= TX_EPD;
        end
        TX_EPD : begin
          tx_is_k <= 1'b 1;
          tx_odata_reg <= c_k29_7;
          tx_state <= TX_EXTEND;
        end
        TX_EXTEND : begin
          tx_odata_reg <= c_k23_7;
          if((tx_odd_length == 1'b 0)) begin
            tx_state <= TX_COMMA;
          end
          else begin
            tx_odd_length <= 1'b 0;
          end
        end
        default : begin
        end
        endcase
      end
    end
  end

endmodule
