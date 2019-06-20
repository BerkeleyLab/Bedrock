// File ep_sync_detect.vhd translated with vhd2vl v2.3 VHDL to Verilog RTL translator
// see http://doolittle.icarus.com/~larry/vhd2vl/
// Additional modifications by hand by Larry Doolittle

//-----------------------------------------------------------------------------
// Title      : 802.3x 1000base-X compatible synchronization detect unit
// Project    : WhiteRabbit Switch
//-----------------------------------------------------------------------------
// File       : ep_sync_detect.vhd
// Author     : Tomasz Wlostowski
// Company    : CERN BE-Co-HT
// Created    : 2010-05-28
// Last update: 2010-05-31
// Platform   : FPGA-generics
// Standard   : VHDL
//-----------------------------------------------------------------------------
// Description: Module implements a link synchronization detect state machine
// compatible with 802.3x spec.
//-----------------------------------------------------------------------------
// Copyright (c) 2010 Tomasz Wlostowski
//-----------------------------------------------------------------------------
// Revisions  :
// Date        Version  Author          Description
// 2010-05-28  1.0      twlostow        Created
//-----------------------------------------------------------------------------
// no timescale needed

module ep_sync_detect(
	input rst,           // reset, synchronous to rbclk_i, active HIGH
	input clk,           // recovered byte clock
	input en_i,          // enable, active HI
	input [7:0] data_i,  // decoded data input, active HI
	input k_i,           // decoded K signal, active HI
	input err_i,         // 8b10b coding error indication, active HI
	output reg synced_o, // sync detect output, active HI
	output even_o        // odd/even field indicator (HI = even field)
);

parameter [3:0]
  LOSS_OF_SYNC = 0,
  COMMA_DETECT_1 = 1,
  ACQUIRE_SYNC_1 = 2,
  COMMA_DETECT_2 = 3,
  ACQUIRE_SYNC_2 = 4,
  COMMA_DETECT_3 = 5,
  SYNC_ACQUIRED_1 = 6,
  SYNC_ACQUIRED_2 = 7,
  SYNC_ACQUIRED_3 = 8,
  SYNC_ACQUIRED_4 = 9,
  SYNC_ACQUIRED_2A = 10,
  SYNC_ACQUIRED_3A = 11,
  SYNC_ACQUIRED_4A = 12;

initial synced_o=0;
reg [3:0] state=LOSS_OF_SYNC;
wire cggood;
wire cgbad;
wire comma;
reg rx_even=0;
wire is_d;
wire is_k28_5;
reg [2:0] good_cgs=0;
wire [7:0] c_k28_5 = 8'b10111100;

  // behavioral
  assign is_k28_5 = data_i == c_k28_5 ? 1'b 1 : 1'b 0;
  assign is_d = ( ~k_i);
  assign comma = is_k28_5;
  assign cgbad = err_i | ((k_i & comma & rx_even));
  assign cggood =  ~((err_i | ((k_i & comma & rx_even))));
  assign even_o =  ~rx_even;
  // fixme!
  // 1000base-x sync detect state machine
  // as defined in 802.3-2008, figure 36-9.
  always @(posedge clk) begin
      // process sync_fsm
    if(rst) begin
      state <= LOSS_OF_SYNC;
      synced_o <= 1'b 0;
      rx_even <= 1'b 0;
      good_cgs <= {3{1'b0}};
    end
    else begin
      if((en_i == 1'b 0)) begin
        state <= LOSS_OF_SYNC;
        synced_o <= 1'b 0;
        rx_even <= 1'b 0;
        good_cgs <= {3{1'b0}};
      end
      else begin
        case(state)
        LOSS_OF_SYNC : begin
          synced_o <= 1'b 0;
          rx_even <=  ~rx_even;
          if((comma == 1'b 1)) begin
            state <= COMMA_DETECT_1;
          end
        end
        COMMA_DETECT_1 : begin
          rx_even <= 1'b 0;
          // was 1
          if((is_d == 1'b 1)) begin
            // got data
            state <= ACQUIRE_SYNC_1;
          end
          else begin
            state <= LOSS_OF_SYNC;
          end
        end
        ACQUIRE_SYNC_1 : begin
          rx_even <=  ~rx_even;
          if((cgbad == 1'b 1)) begin
            state <= LOSS_OF_SYNC;
          end
          else if((rx_even == 1'b 0 && comma == 1'b 1)) begin
            state <= COMMA_DETECT_2;
          end
        end
        COMMA_DETECT_2 : begin
          rx_even <= 1'b 0;
          // was 1
          if((is_d == 1'b 1)) begin
            state <= ACQUIRE_SYNC_2;
          end
          else begin
            state <= LOSS_OF_SYNC;
          end
        end
        ACQUIRE_SYNC_2 : begin
          rx_even <=  ~rx_even;
          if((cgbad == 1'b 1)) begin
            state <= LOSS_OF_SYNC;
          end
          else if((rx_even == 1'b 0 && comma == 1'b 1)) begin
            state <= COMMA_DETECT_3;
          end
        end
        COMMA_DETECT_3 : begin
          rx_even <= 1'b 0;
          if((is_d == 1'b 1)) begin
            state <= SYNC_ACQUIRED_1;
          end
          else begin
            state <= LOSS_OF_SYNC;
          end
        end
        SYNC_ACQUIRED_1 : begin
          synced_o <= 1'b 1;
          rx_even <=  ~rx_even;
          if((cggood == 1'b 1)) begin
            state <= SYNC_ACQUIRED_1;
          end
          if((cgbad == 1'b 1)) begin
            state <= SYNC_ACQUIRED_2;
          end
        end
        SYNC_ACQUIRED_2 : begin
          rx_even <=  ~rx_even;
          good_cgs <= {3{1'b0}};
          if((cggood == 1'b 1)) begin
            state <= SYNC_ACQUIRED_2A;
          end
          if((cgbad == 1'b 1)) begin
            state <= SYNC_ACQUIRED_3;
          end
        end
        SYNC_ACQUIRED_2A : begin
          rx_even <=  ~rx_even;
          good_cgs <= good_cgs + 1;
          if((good_cgs == 3'b 011 && cggood == 1'b 1)) begin
            state <= SYNC_ACQUIRED_1;
          end
          if((cgbad == 1'b 1)) begin
            state <= SYNC_ACQUIRED_3;
          end
        end
        SYNC_ACQUIRED_3 : begin
          rx_even <=  ~rx_even;
          good_cgs <= {3{1'b0}};
          if((cggood == 1'b 1)) begin
            state <= SYNC_ACQUIRED_3A;
          end
          if((cgbad == 1'b 1)) begin
            state <= SYNC_ACQUIRED_4;
          end
        end
        SYNC_ACQUIRED_3A : begin
          rx_even <=  ~rx_even;
          good_cgs <= good_cgs + 1;
          if((good_cgs == 3'b 011 && cggood == 1'b 1)) begin
            state <= SYNC_ACQUIRED_2;
          end
          if((cgbad == 1'b 1)) begin
            state <= SYNC_ACQUIRED_4;
          end
        end
        SYNC_ACQUIRED_4 : begin
          rx_even <=  ~rx_even;
          good_cgs <= {3{1'b0}};
          if((cggood == 1'b 1)) begin
            state <= SYNC_ACQUIRED_4A;
          end
          if((cgbad == 1'b 1)) begin
            state <= LOSS_OF_SYNC;
          end
        end
        SYNC_ACQUIRED_4A : begin
          rx_even <=  ~rx_even;
          good_cgs <= good_cgs + 1;
          if((good_cgs == 3'b 011 && cggood == 1'b 1)) begin
            state <= SYNC_ACQUIRED_3;
          end
          if((cgbad == 1'b 1)) begin
            state <= LOSS_OF_SYNC;
          end
        end
        default : begin
          state <= LOSS_OF_SYNC;  // impossible state machine error
        end
        endcase
      end
    end
  end


endmodule
