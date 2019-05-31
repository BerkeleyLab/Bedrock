module xadc_mon(
   input lb_clk,                // Clock input for the dynamic reconfiguration port
   input reset,                 // Reset signal for the System Monitor control logic
   input [4:0] lb_addr,         // read out channel address
   output [15:0] lb_data_out,   // sequencer data out

   output [8:0] alarm_out,      // {Over-Temp, 5'hx, VCCAUX, VCCINT, Temp}
   input vp_in,                 // Dedicated Analog Input Pair
   input vn_in
);

reg [6:0] daddr_in=0;    // Address bus for the dynamic reconfiguration port
reg den_in=0;            // Enable Signal for the dynamic reconfiguration port
reg [15:0] di_in=0;      // Input data bus for the dynamic reconfiguration port
reg dwe_in=0;            // Write Enable for the dynamic reconfiguration port

wire [4:0] channel_out;  // Channel Selection Outputs
wire eoc_out;            // End of Conversion Signal
wire eos_out;            // End of Sequence Signal
wire drdy_out;           // Data ready signal for the dynamic reconfiguration port
wire [15:0] do_out;      // Output data bus for dynamic reconfiguration port
wire busy_out;           // ADC Busy signal

reg reset_int=1'b1;
reg [3:0] reset_wait=0;  // 200 ns initial reset, or 16 cycles
wire reset_wait_done = &reset_wait;
reg rst_sync=0;
reg rst_sync_int=0;
reg rst_sync_int1=0;
reg rst_sync_int2=0;
reg [4:0]  addr_out=0;    // sequencer chan out
reg [15:0] data_out=0;    // sequencer data out
reg data_rdy=0;

always @(posedge reset or posedge lb_clk) begin
   if (reset) begin
        reset_wait <= 4'b0;
		rst_sync <= 1'b1;
		rst_sync_int <= 1'b1;
		rst_sync_int1 <= 1'b1;
		rst_sync_int2 <= 1'b1;
        daddr_in <= 7'b0;
        den_in <= 1'b0;
        addr_out <= 0;
        data_out <= 0;
        data_rdy <= 1'b0;
   end else begin
        reset_wait <= reset_wait_done ? 4'hf : reset_wait + 1'b1;
		rst_sync <= 1'b0;
		rst_sync_int <= rst_sync;
		rst_sync_int1 <= rst_sync_int;
		rst_sync_int2 <= rst_sync_int1;
        daddr_in <= {2'b0, channel_out};
        den_in <= eoc_out;
        if (drdy_out) begin
            addr_out <= channel_out;
            data_out <= do_out;
        end
        data_rdy <= drdy_out;
   end
end

dpram #(
    .aw(5), .dw(16)
) ram (
    .clka       (lb_clk     ),
    .addra      (addr_out   ),
    .dina       (data_out   ),
    .wena       (data_rdy   ),
    .clkb       (lb_clk     ),
    .addrb      (lb_addr    ),
    .doutb      (lb_data_out)
);

wire reset_in = rst_sync_int2 | ~reset_wait_done;
wire [7:0]  alm_int;
wire ot_out;
assign alarm_out = {ot_out, alm_int};

`ifndef SIMULATION
/***********
create_ip -name xadc_wiz -vendor xilinx.com -library ip -module_name "xadc_wiz_0"
set_property -dict {
    CONFIG.INTERFACE_SELECTION {ENABLE_DRP}
    CONFIG.DCLK_FREQUENCY {125}
    CONFIG.ADC_CONVERSION_RATE {1000}
    CONFIG.XADC_STARUP_SELECTION {channel_sequencer}
    CONFIG.ENABLE_AXI4STREAM {false}
    CONFIG.CHANNEL_ENABLE_TEMPERATURE {true}
    CONFIG.CHANNEL_ENABLE_VCCINT {true}
    CONFIG.CHANNEL_ENABLE_VCCAUX {true}
    CONFIG.CHANNEL_ENABLE_VP_VN {true}
    CONFIG.AVERAGE_ENABLE_VBRAM {false}
    CONFIG.AVERAGE_ENABLE_VP_VN {false}
    CONFIG.AVERAGE_ENABLE_TEMPERATURE {false}
    CONFIG.AVERAGE_ENABLE_VCCINT {false}
    CONFIG.AVERAGE_ENABLE_VCCAUX {false}
    CONFIG.SEQUENCER_MODE {Continuous}
    CONFIG.EXTERNAL_MUX_CHANNEL {VP_VN}
    CONFIG.SINGLE_CHANNEL_SELECTION {TEMPERATURE}
} [get_ips xadc_wiz_0]
generate_target {instantiation_template} [get_files xadc_wiz_0.xci]
generate_target all [get_files xadc_wiz_0.xci]
create_ip_run [get_files -of_objects [get_fileset sources_1] xadc_wiz_0.xci]
*/

XADC #(
    .INIT_40(16'h0000), // config reg 0
    .INIT_41(16'h21A0), // config reg 1
    .INIT_42(16'h0500), // config reg 2
    .INIT_48(16'h0F00), // Sequencer channel selection
    .INIT_49(16'h0000), // Sequencer channel selection
    .INIT_4A(16'h0000), // Sequencer Average selection
    .INIT_4B(16'h0000), // Sequencer Average selection
    .INIT_4C(16'h0000), // Sequencer Bipolar selection
    .INIT_4D(16'h0000), // Sequencer Bipolar selection
    .INIT_4E(16'h0000), // Sequencer Acq time selection
    .INIT_4F(16'h0000), // Sequencer Acq time selection
    .INIT_50(16'hB5ED), // Temp alarm trigger
    .INIT_51(16'h57E4), // Vccint upper alarm limit
    .INIT_52(16'hA147), // Vccaux upper alarm limit
    .INIT_53(16'hCA33), // Temp alarm OT upper
    .INIT_54(16'hA93A), // Temp alarm reset
    .INIT_55(16'h52C6), // Vccint lower alarm limit
    .INIT_56(16'h9555), // Vccaux lower alarm limit
    .INIT_57(16'hAE4E), // Temp alarm OT reset
    .INIT_58(16'h5999), // VCCBRAM upper alarm limit
    .INIT_5C(16'h5111), //  VCCBRAM lower alarm limit
    .SIM_DEVICE("7SERIES")
) inst (
        .CONVST         (1'b0),
        .CONVSTCLK      (1'b0),
        .DADDR          (daddr_in[6:0]),
        .DCLK           (lb_clk),
        .DEN            (den_in),
        .DI             (di_in),
        .DWE            (dwe_in),
        .RESET          (reset_in),
        .VAUXN          (16'h0),
        .VAUXP          (16'h0),
        .ALM            (alm_int),
        .BUSY           (busy_out),
        .CHANNEL        (channel_out),
        .DO             (do_out),
        .DRDY           (drdy_out),
        .EOC            (eoc_out),
        .EOS            (eos_out),
        .JTAGBUSY       (),
        .JTAGLOCKED     (),
        .JTAGMODIFIED   (),
        .OT             (ot_out),
        .MUXADDR        (),
        .VP             (vp_in),
        .VN             (vn_in)
);
`else
    assign channel_out = 5'h3;
    assign alm_int = 0;
    assign do_out = 16'hbeaf;
    assign drdy_out = 1'b1;
    assign eoc_out = 0;
    assign eos_out = 0;
    assign ot_out = 0;
`endif

endmodule
