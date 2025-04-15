// Derived from Tomasz Wlostowski's ep_rx_pcs.vhd, Copyright (c) 2009
//  (translated with vhd2vl v2.3 VHDL to Verilog RTL translator)
// More-or-less re-written after that translation
// Tomasz's original was written for CERN's WhiteRabbit switch
// This work performed in 2010 by Larry Doolittle at LBNL

module ep_rx_pcs(
input clk,  // single clock domain, fully deterministic
input rst,

// Input from serdes
input [7:0] dec_out,
input dec_is_k,
input dec_err_code,
input dec_err_rdisp,
input dec_err_los,

// GMII-ish output
output reg [7:0] gmii_data,
output reg gmii_dv,
output gmii_err,

input ep_rcr_en_pcs_i,     // Receive control register
output ep_rcr_los_o,   // loss-of-sync field

// Link Autonegotiation Configuration Register
input lacr_rx_en,          // enable reception
output reg [15:0] lacr_rx_val,
output reg lacr_rx_stb
);

`include "endpoint.vh"

`ifdef SIMULATE
  `define INDENT  "                                                "
`endif

// RX state machine definitions
parameter [2:0]
  RX_NOFRAME = 0,
  RX_COMMA = 1,
  RX_CR3 = 2,
  RX_CR4 = 3,
  RX_PAYLOAD = 4,
  RX_EXTEND = 5;

initial begin
  gmii_data=0;
  gmii_dv=0;
  lacr_rx_val=0;
  lacr_rx_stb=0;
end

reg [2:0] rx_state=RX_NOFRAME;
reg d_is_k=0; reg d_err=0; reg d_is_comma=0; reg d_is_epd=0;
reg d_is_spd=0; reg d_is_extend=0; reg d_is_idle=0; reg d_is_lcr=0;
reg [7:0] d_data=0;
reg d_is_even=0;
wire dec_err;
reg fifo_error=0;
wire rx_synced; wire rx_even;

`ifdef SIMULATE
  //initial $monitor($time, , dec_err_code, , dec_err_rdisp);
`endif

  assign dec_err = dec_err_code | dec_err_rdisp;
  ep_sync_detect SYNC_DET(
    .clk(clk),
    .rst(rst),
    .en_i(ep_rcr_en_pcs_i),
    .data_i(dec_out),
    .k_i(dec_is_k),
    .err_i(dec_err),
    .synced_o(rx_synced),
    .even_o(rx_even));

  initial gmii_dv = 0;
  reg [7:0] gmii_pipe0=0;
  wire rx_valid = (rx_state == RX_PAYLOAD) & ~d_is_epd;
  always @(posedge clk) begin
    gmii_dv <= rx_valid;
    gmii_pipe0 <= dec_out;
    gmii_data  <= rx_valid ? gmii_pipe0 : 8'd0;
  end

  assign gmii_err = fifo_error;
  always @(posedge clk) begin
    if(rst) begin
      d_data <= {8{1'b0}};
      d_is_comma  <= 0;
      d_is_spd    <= 0;
      d_is_extend <= 0;
      d_is_lcr    <= 0;
      d_is_epd    <= 0;
      d_is_idle   <= 0;
      d_is_k      <= 0;
      d_err       <= 0;
      d_err       <= 0;
    end
    else begin
      d_is_even <= rx_even;
      if((~dec_err)) begin
        d_data <= dec_out;
        d_is_k <= dec_is_k;
        d_err <= 0;
        d_is_comma  <=  (dec_out == c_k28_5) & dec_is_k;
        d_is_extend <=  (dec_out == c_k23_7) & dec_is_k;
        d_is_spd    <=  (dec_out == c_k27_7) & dec_is_k;
        d_is_epd    <=  (dec_out == c_k29_7) & dec_is_k;
        d_is_lcr    <= ((dec_out == c_d21_5) | (dec_out == c_d2_2 )) & ~dec_is_k;
        d_is_idle   <= ((dec_out == c_d5_6 ) | (dec_out == c_d16_2)) & ~dec_is_k;
      end
      else begin
        d_err       <= 1;
        d_is_comma  <= 0;
        d_is_spd    <= 0;
        d_is_extend <= 0;
        d_is_lcr    <= 0;
        d_is_epd    <= 0;
        d_is_idle   <= 0;
        d_is_k      <= 0;
      end
    end
  end

  // RBCLK-driven RX state machine
  always @(posedge clk) begin
    if(rst) begin
      rx_state <= RX_NOFRAME;
      fifo_error <= 0;
      lacr_rx_stb <= 0;
      lacr_rx_val <= {16{1'b0}};
    end
    else begin
      lacr_rx_stb <= 0;
      if((~ep_rcr_en_pcs_i)) begin
        rx_state <= RX_NOFRAME;
        fifo_error <= 0;
        lacr_rx_val <= {16{1'b0}};
      end
      else begin
        //-----------------------------------------------------------------------------
        // Main RX PCS state machine
        //-----------------------------------------------------------------------------
        case(rx_state)
        //-----------------------------------------------------------------------------
        // State NOFRAME: receiver is receiving IDLE pattern
        //-----------------------------------------------------------------------------
        RX_NOFRAME : begin
          fifo_error <= 0;
          lacr_rx_stb <= 0;
          // PCS is not synced: stay in NOFRAME state
          if ((~rx_synced)) begin
            rx_state <= RX_NOFRAME;
          end else if ((d_is_comma)) begin
            // we've got a comma: it's probably an idle sequence, go and check it
            //$display("%s->RX_COMMA", `INDENT);
            rx_state <= RX_COMMA;
          end else if ((d_is_spd & d_is_even)) begin
            // we've got a Start-of-Packet Delimiter
            // GMII takes care of preamble and SPD, don't replicate that here
            rx_state <= RX_PAYLOAD;
          end
        end
          //-----------------------------------------------------------------------------
          // State COMMA: we've received a comma character followed by something else.
          //-----------------------------------------------------------------------------
        RX_COMMA : begin
          // received code group with error (or control code group) - go to NOFRAME
          if((d_err | d_is_k | d_is_even)) begin
            `ifdef SIMULATE
                $display("%s(%t) ->RX_NOFRAME 0x%x, %b, %b, %b", `INDENT, $stime, dec_out, d_is_k, dec_err, d_is_even);
            `endif
            rx_state <= RX_NOFRAME;
          end
          else begin
            // received D5.6 or D16.2 - it's an idle pattern.
            if((d_is_idle)) begin
              //$display("%s->RX_NOFRAME d_is_idle", `INDENT);
              rx_state <= RX_NOFRAME;
              // received D21.5 or D2.2 - it's a 802.3x autonegotiation LACR
            end
            else if((d_is_lcr)) begin
              //$display("%s->RX_CR3", `INDENT);
              rx_state <= RX_CR3;
            end
            else begin
            end
          end
        end
          //-----------------------------------------------------------------------------
          // States CR3/CR4: reception of LACR register value.
          //-----------------------------------------------------------------------------
        RX_CR3 : begin
          // 1st byte of LACR
          // an error? - drop to NOFRAME state.
          if((d_err | d_is_k | ~d_is_even)) begin
            //$display("%s->RX_NOFRAME, %b, %b, %b", `INDENT, d_err, d_is_k, d_is_even);
            rx_state <= RX_NOFRAME;
          end
          else if((lacr_rx_en)) begin
            // LACR reception is enabled:
            lacr_rx_val[7:0] <= d_data; // Little endian
            //$display("%s->RX_CR4", `INDENT);
            rx_state <= RX_CR4;
          end
        end
        RX_CR4 : begin
          // 2nd byte of LACR
          if((d_err | d_is_k | d_is_even)) begin
            //$display("%s->RX_NOFRAME %b, %b, %b", `INDENT, d_err, d_is_k, d_is_even);
            rx_state <= RX_NOFRAME;
          end
          else if((lacr_rx_en)) begin
            //$display("%s->STROBE! 0x%x", `INDENT, {d_data, lacr_rx_val[7:0]});
            lacr_rx_val[15:8] <= d_data;
            lacr_rx_stb <= 1;
          end else begin
            `ifdef SIMULATE
            $display("%s(%t) ->NO_STROBE: lacr_rx_en = %b", `INDENT, $stime, lacr_rx_en);
            `endif
          end
          rx_state <= RX_NOFRAME;
        end
          //-----------------------------------------------------------------------------
          // State PAYLOAD: receiving frame payload (including 802.1x header and FCS)
          //-----------------------------------------------------------------------------
        RX_PAYLOAD : begin
          // check for errors.
          if((d_err | ~rx_synced)) begin
            rx_state <= RX_NOFRAME;
            fifo_error <= 1;
          end
          else if(d_is_k) begin
            if(d_is_epd) begin
              // got an EPD
              rx_state <= RX_EXTEND;
            end
            else begin
              // any other K-character in the middle of frame? - premature end
              if(d_is_comma) begin
                // got link idle inside frame
                rx_state <= RX_COMMA;
              end
              else begin
                rx_state <= RX_NOFRAME;
              end
              fifo_error <= 1;
            end
          end
          else begin
            // got a data character
          end
        end
          //-----------------------------------------------------------------------------
          // State EXTEND: receive carrier extension
          //-----------------------------------------------------------------------------
        RX_EXTEND : begin
          if(d_is_extend) begin
            // got carrier extend
            rx_state <= RX_EXTEND;
          end
          else if(d_is_comma) begin
            // got comma, real end-of-frame
            rx_state <= RX_COMMA;
          end
          else begin
            fifo_error <= 1;
            rx_state <= RX_NOFRAME;
          end
        end
        default : begin
        end
        endcase
      end
    end
  end

assign ep_rcr_los_o = dec_err_los;

`ifdef SIMULATE
  reg [15:0] old_lacr=0;
  always @(posedge clk) begin
    if (lacr_rx_stb) begin
      old_lacr <= lacr_rx_val;
      if (old_lacr != lacr_rx_val) begin
        if (lacr_rx_val != 0) $display("%s(%t) Received 0x%x", `INDENT, $stime, lacr_rx_val);
        else $display("%s(%t) Received breaklink", `INDENT, $stime);
      end
    end
  end
`endif

`undef INDENT
endmodule
