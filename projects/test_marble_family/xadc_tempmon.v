`timescale 1ns / 1ns

/*
 * Using XADC for internal temperature monitoring
 * Notes:
 *    In default sequencing mode (INT41[15:12] = 0), all internal sensors are
 *    automatically monitored and the results are placed in the corresponding
 *    status registers.  An averaging of 16 is applied to all channels.  All
 *    other control register settings are ignored.
 *
 *    Status register 0x00 holds the internal temperature
 *
 *    DRP (Dynamic Reconfiguration Port) Timing:
 *      DEN should assert for only 1 DCLK duration
 *      DARR and DWE are latched when DEN asserted
 *      DWE asserted => write
 *      DI is latched when DWE asserted
 *      DRDY asserted means data successfully written to DRP register
 *      DWE deasserted => read
 *      DRDY asserted indicates valid data on DO
 */

module xadc_tempmon #(
  parameter SYSCLK_FREQ_HZ = 100000000,
  parameter UPDATE_FREQ_HZ = 2
  )(
  input wire clk,           // System clock
  input wire rst,           // High-true reset to XADC core
  output reg [15:0] dout,   // Data out
  output wire read,         // High pulse on read
  output wire otemp         // Over-temp alarm
  );

  localparam UDCNT_MAX = SYSCLK_FREQ_HZ/UPDATE_FREQ_HZ - 1;
  localparam UDCNT_WIDTH = $clog2(UDCNT_MAX);
  localparam ADDR_INT_TEMP = 7'h0;

  // Conversion-start signal; not used in default mode.
  reg convst;
  reg [UDCNT_WIDTH-1:0] udcnt;
  reg udclk;

  // Implement bus-master
  reg [6:0] daddr;
  wire [15:0] data_out;
  reg [15:0] data_in; // Not using data_in for now
  wire [7:0] alm;
  reg den, dwe;
  wire drdy;
  wire eoc, eos, busy;

  assign read = den;

  initial begin
    udclk = 1'b0;
    udcnt = {UDCNT_WIDTH{1'b0}};
    daddr = ADDR_INT_TEMP;   // Always reading from addr 0
    data_in = 16'h0;
    den = 1'b0;
    dwe = 1'b0;     // Always reading for now
    convst = 1'b0;  // Default mode passively converts
  end

  always @(posedge clk) begin
    if (rst) begin
      udcnt <= 0;
    end else begin
      if (drdy) dout <= data_out;
      if (udcnt == UDCNT_MAX) begin
        udcnt <= 0;
      end else begin
        udcnt <= udcnt + 1;
      end
    end
  end

  // DEN should change on falling edge since it is latched on rising edge
  // and should only be 1-clk long according to specs
  always @(negedge clk) begin
    if (udcnt == UDCNT_MAX) den <= 1'b1;
    else den <= 1'b0;
  end

`ifdef SIMULATE
  always @(posedge clk) begin
    data_out <= 16'h9773; // ~25degC
  end
`else

  XADC #(
    // INIT_40 - INIT_42: XADC configuration registers
    .INIT_40(16'h0000), // [4:0] = 0 => Internal temp sensor
                        // [8] = 0 => ACQ; extended settling time
                        // [9] = 0 => Continuous sampling mode
                        // [A] = 0 => Unipolar (single-ended) mode
                        // [B] = 0 => No ext mux mode
                        // [D:C] = 0b11 => 256 sample averaging
                        // [F] = 0 => Enable avg on calib coeff
    .INIT_41(16'h0000), // [0] = 0 => Enable OT alarm
                        // [3:1] = 0 => Enable all alarms
                        // [7:4] = 0 => Disable calibrations
                        // [11:8] = 0 => Enable all alarms
                        // [15:12] = 0 => Default sequence mode
    .INIT_42(16'h0800), // [5:4] = 0 => No power-down
                        // [15:8] = 0x08 => ADCCLK = DCLK/8
    // INIT_48 - INIT_4F: Sequence Registers
    .INIT_48(16'h0000),
    .INIT_49(16'h0000),
    .INIT_4A(16'h0000),
    .INIT_4B(16'h0000),
    .INIT_4C(16'h0000),
    .INIT_4D(16'h0000),
    .INIT_4F(16'h0000),
    .INIT_4E(16'h0000),                // Sequence register 6
    // INIT_50 - INIT_58, INIT5C: Alarm Limit Registers
    .INIT_50(16'h0000),
    .INIT_51(16'h0000),
    .INIT_52(16'h0000),
    .INIT_53(16'h0000),
    .INIT_54(16'h0000),
    .INIT_55(16'h0000),
    .INIT_56(16'h0000),
    .INIT_57(16'h0000),
    .INIT_58(16'h0000),
    .INIT_5C(16'h0000),
    // Simulation attributes: Set for proper simulation behavior
    .SIM_DEVICE("7SERIES"),            // Select target device (values)
    .SIM_MONITOR_FILE("design.txt")  // Analog simulation data file name
  )
  XADC_inst (
    // ALARMS: 8-bit (each) output: ALM, OT
    .ALM(alm),                   // 8-bit output: Output alarm for temp, Vccint, Vccaux and Vccbram
    .OT(otemp),                     // 1-bit output: Over-Temperature alarm
    // Dynamic Reconfiguration Port (DRP): 16-bit (each) output: Dynamic Reconfiguration Ports
    .DO(data_out),                     // 16-bit output: DRP output data bus
    .DRDY(drdy),                 // 1-bit output: DRP data ready
    // STATUS: 1-bit (each) output: XADC status ports
    .BUSY(busy),                 // 1-bit output: ADC busy output
    //.CHANNEL(adc_channel),           // 5-bit output: Channel selection outputs
    .EOC(eoc),                   // 1-bit output: End of Conversion
    .EOS(eos),                   // 1-bit output: End of Sequence
    //.JTAGBUSY(JTAGBUSY),         // 1-bit output: JTAG DRP transaction in progress output
    //.JTAGLOCKED(JTAGLOCKED),     // 1-bit output: JTAG requested DRP port lock
    //.JTAGMODIFIED(JTAGMODIFIED), // 1-bit output: JTAG Write to the DRP has occurred
    //.MUXADDR(MUXADDR),           // 5-bit output: External MUX channel decode
    // Auxiliary Analog-Input Pairs: 16-bit (each) input: VAUXP[15:0], VAUXN[15:0]
    //.VAUXN(VAUXN),               // 16-bit input: N-side auxiliary analog input
    //.VAUXP(VAUXP),               // 16-bit input: P-side auxiliary analog input
    // CONTROL and CLOCK: 1-bit (each) input: Reset, conversion start and clock inputs
    .CONVST(convst),             // 1-bit input: Convert start input
    // === We don't need the precision of CONVSTCLK and would rather trigger from general logic
    //.CONVSTCLK(CONVSTCLK),       // 1-bit input: Convert start input
    .RESET(rst),               // 1-bit input: Active-high reset
    // Dedicated Analog Input Pair: 1-bit (each) input: VP/VN
    //.VN(VN),                     // 1-bit input: N-side analog input
    //.VP(VP),                     // 1-bit input: P-side analog input
    // Dynamic Reconfiguration Port (DRP): 7-bit (each) input: Dynamic Reconfiguration Ports
    .DADDR(daddr),               // 7-bit input: DRP address bus
    .DCLK(clk),                 // 1-bit input: DRP clock
    .DEN(den),                   // 1-bit input: DRP enable signal
    .DI(data_in),                     // 16-bit input: DRP input data bus
    .DWE(dwe)                    // 1-bit input: DRP write enable
  );
  // End of XADC_inst instantiation
`endif

endmodule
