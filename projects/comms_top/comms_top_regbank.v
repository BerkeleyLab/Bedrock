// ------------------------------------
// COMMS_TOP_REGBANK.v
//
// A simple register bank with local bus decoding created to support comms_top.v
//
// ------------------------------------

module comms_top_regbank #(
   parameter LB_AWI = 24,
   parameter LB_DWI = 32
) (
   // Local bus interface
   input               lb_clk,
   input               lb_valid,
   input               lb_rnw,
   input [LB_AWI-1:0]  lb_addr,
   input [LB_DWI-1:0]  lb_wdata,
   input               lb_renable, // Ignored in this module
   output [LB_DWI-1:0] lb_rdata,

   // Control registers in
   input [15:0]        rx_frame_counter_i,
   input [15:0]        txrx_latency_i,
   input [2:0]         ccrx_fault_i,
   input [15:0]        ccrx_fault_cnt_i,
   input               ccrx_los_i,
   input [3:0]         rx_protocol_ver_i,
   input [2:0]         rx_gateware_type_i,
   input [2:0]         rx_location_i,
   input [31:0]        rx_rev_id_i,

   input [31:0]        rx_data0_i,
   input [31:0]        rx_data1_i,

   // Control registers out
   output reg [2:0]    tx_location_o,
   output reg          tx_transmit_en_o
);
   `include "comms_pack.vh"

   localparam LOCAL_AWI = 4;

   // Address map of read registers
   localparam [LOCAL_AWI-1:0] INFO0_RD_REG            = 0;
   localparam [LOCAL_AWI-1:0] INFO1_RD_REG            = 1;
   localparam [LOCAL_AWI-1:0] RX_FRAME_COUNTER_RD_REG = 2;
   localparam [LOCAL_AWI-1:0] TXRX_LATENCY_RD_REG     = 3;
   localparam [LOCAL_AWI-1:0] CCRX_FAULT_RD_REG       = 4;
   localparam [LOCAL_AWI-1:0] CCRX_FAULT_CNT_RD_REG   = 5;
   localparam [LOCAL_AWI-1:0] CCRX_LOS_RD_REG         = 6;
   localparam [LOCAL_AWI-1:0] RX_PROTOCOL_VER_RD_REG  = 7;
   localparam [LOCAL_AWI-1:0] RX_GATEWARE_TYPE_RD_REG = 8;
   localparam [LOCAL_AWI-1:0] RX_LOCATION_RD_REG      = 9;
   localparam [LOCAL_AWI-1:0] RX_REV_ID_RD_REG        = 10;
   localparam [LOCAL_AWI-1:0] RX_DATA0_RD_REG         = 11;
   localparam [LOCAL_AWI-1:0] RX_DATA1_RD_REG         = 12;

   // Address map of write registers
   localparam TX_LOCATION_WR_REG      = 0;
   localparam TX_TRANSMIT_EN_WR_REG   = 1;

   // Size of read and write register banks
   localparam NUM_RD_REG = RX_DATA1_RD_REG + 1;
   localparam NUM_WR_REG = TX_TRANSMIT_EN_WR_REG + 1;

   reg [LBUS_DATA_WIDTH-1:0] lb_rdata_reg = 0;

   // -------------------
   // Local Bus decoding
   // -------------------
   always @(posedge lb_clk) begin
      if (lb_valid) begin
         if (lb_rnw) begin
            case (lb_addr[LOCAL_AWI-1:0])
               INFO0_RD_REG:            lb_rdata_reg <= "QF2P";
               INFO1_RD_REG:            lb_rdata_reg <= "COMM";
               RX_FRAME_COUNTER_RD_REG: lb_rdata_reg <= rx_frame_counter_i;
               TXRX_LATENCY_RD_REG:     lb_rdata_reg <= txrx_latency_i;
               CCRX_FAULT_RD_REG:       lb_rdata_reg <= ccrx_fault_i;
               CCRX_FAULT_CNT_RD_REG:   lb_rdata_reg <= ccrx_fault_cnt_i;
               CCRX_LOS_RD_REG:         lb_rdata_reg <= ccrx_los_i;
               RX_PROTOCOL_VER_RD_REG:  lb_rdata_reg <= rx_protocol_ver_i;
               RX_GATEWARE_TYPE_RD_REG: lb_rdata_reg <= rx_gateware_type_i;
               RX_LOCATION_RD_REG:      lb_rdata_reg <= rx_location_i;
               RX_REV_ID_RD_REG:        lb_rdata_reg <= rx_rev_id_i;
               RX_DATA0_RD_REG:         lb_rdata_reg <= rx_data0_i;
               RX_DATA1_RD_REG:         lb_rdata_reg <= rx_data1_i;
               default:                 lb_rdata_reg <= 32'hdeadf00d;
            endcase
         end else begin
            case (lb_addr[LOCAL_AWI-1:0])
               TX_LOCATION_WR_REG:      tx_location_o    <= lb_wdata;
               default:                 tx_transmit_en_o <= lb_wdata; // TX_TRANSMIT_EN_WR_REG
            endcase
         end
      end
   end

   assign lb_rdata = lb_rdata_reg;

endmodule
