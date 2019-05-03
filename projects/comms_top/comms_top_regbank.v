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

   // Control registers out
   output [2:0]        tx_location_o
);
   `include "comms_pack.vh"

   // Address map of read registers
   localparam INFO0_RD_REG            = 0;
   localparam INFO1_RD_REG            = 1;
   localparam RX_FRAME_COUNTER_RD_REG = 2;
   localparam TXRX_LATENCY_RD_REG     = 3;
   localparam CCRX_FAULT_RD_REG       = 4;
   localparam CCRX_FAULT_CNT_RD_REG   = 5;
   localparam CCRX_LOS_RD_REG         = 6;
   localparam RX_PROTOCOL_VER_RD_REG  = 7;
   localparam RX_GATEWARE_TYPE_RD_REG = 8;
   localparam RX_LOCATION_RD_REG      = 9;
   localparam RX_REV_ID_RD_REG        = 10;

   // Address map of write registers
   localparam TX_LOCATION_WR_REG      = 0;

   // Size of read and write register banks
   localparam NUM_RD_REG = RX_REV_ID_RD_REG + 1;
   localparam NUM_WR_REG = TX_LOCATION_WR_REG + 1;

   reg [LBUS_DATA_WIDTH-1:0] reg_rd_array [NUM_RD_REG-1:0];
   reg [LBUS_DATA_WIDTH-1:0] reg_wr_array [NUM_RD_REG-1:0];

   reg [LBUS_DATA_WIDTH-1:0] lb_rdata_reg;

   // -------------------
   // Register wiring
   // -------------------
   always @(posedge lb_clk) begin
      reg_rd_array[INFO0_RD_REG]            <= "QF2\n";
      reg_rd_array[INFO1_RD_REG]            <= "COM\n";

      // Input registers will auto-extend to LBUS_DATA_WIDTH
      reg_rd_array[RX_FRAME_COUNTER_RD_REG] <= rx_frame_counter_i;
      reg_rd_array[TXRX_LATENCY_RD_REG]     <= txrx_latency_i;
      reg_rd_array[CCRX_FAULT_RD_REG]       <= ccrx_fault_i;
      reg_rd_array[CCRX_FAULT_CNT_RD_REG]   <= ccrx_fault_cnt_i;
      reg_rd_array[CCRX_LOS_RD_REG]         <= ccrx_los_i;
      reg_rd_array[RX_PROTOCOL_VER_RD_REG]  <= rx_protocol_ver_i;
      reg_rd_array[RX_GATEWARE_TYPE_RD_REG] <= rx_gateware_type_i;
      reg_rd_array[RX_LOCATION_RD_REG]      <= rx_location_i;
      reg_rd_array[RX_REV_ID_RD_REG]        <= rx_rev_id_i;
   end

   assign tx_location_o = reg_wr_array[TX_LOCATION_WR_REG];

   // -------------------
   // Local Bus decoding
   // -------------------
   always @(posedge lb_clk) begin
      if (lb_valid) begin
         if (lb_rnw) begin
            if (lb_addr >= NUM_RD_REG)
               lb_rdata_reg <= 32'hdeadf00d;
            else
               lb_rdata_reg <= reg_rd_array[lb_addr];
         end else begin
            if (lb_addr < NUM_WR_REG)
               reg_wr_array[lb_addr] <= lb_wdata;
         end
      end
   end

   assign lb_rdata = lb_rdata_reg;

endmodule
