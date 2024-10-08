// Module that manages the asynchronous external trigger, and the internally-generated periodic trigger.
// Performs clock-domain synchronization, and delays the assertion of the trigger accordingly.
// ----------

module etrig_bridge (
  // Two clocks, ADC clock and local clock
  input lb_clk,
  input adc_clk,
  // Three external triggers, active-low
  input trign_0,
  input trign_1,
  input trign_2,
  // Control registers
  input [1:0] sel, // external
  input [25:0] period, // external
  input [25:0] delay, // external
  // Trigger Counter
  output [15:0] etrig_pulse_cnt,
  // Trigger Outputs
  output etrig_pulse,
  output etrig_pulse_delayed
);

  // -------
  // Multi-board synchronization w/ selectable external or programmable trigger
  // -------
  localparam ETRIG_0 = 0,
             ETRIG_1 = 1,
             ETRIG_2 = 2,
             ETRIG_PROG = 3;

  // wires and regs
  reg [25:0] etrig_p_cnt = 0; // counter for internally-generated trigger
  wire etrig_p_pulse, etrig_p_pulse_x; // the internal trigger and its synced partner
  wire async_trig, etrig; // MUX outputs
  reg [6:0] async_filt_cnt = 0; // to filter-out glitches in the external trigger
  wire async_trig_filt; // filtered-out trigger
  reg etrig_r = 0, etrig_r1 = 0, etrig_pulse_i = 0; // for edge detection
  reg [1:0] etrig_sreg = 0; // shift register to ensure proper delay
  reg [15:0] etrig_pulse_cnt_i = 0; // count the triggers that are issued
  reg [25:0] delay_cnt = 0; // delay counter
  reg etrig_pulse_delayed_i = 0; // delayed pulse
  reg etrig_toggle = 0; // flag indicating that we received a pulse

  // 2-FF synchronizers
  (* ASYNC_REG = "TRUE" *) reg [1:0] trign_0_sync=0, trign_1_sync=0, trign_2_sync=0;

  // Move delay control to adc_clk domain.  Should be attainable using newad.
  reg [25:0] delay_r=0;  always @(posedge adc_clk) delay_r <= delay;

  // generates the internal trigger
  always @(posedge lb_clk) begin
    etrig_p_cnt <= (etrig_p_cnt == 0) ? period : etrig_p_cnt - 1;
  end

  assign etrig_p_pulse = (etrig_p_cnt == 1);

  // from lb to adc clock domain
  flag_xdomain i_flagx_etrig (
    .clk1(lb_clk), .flagin_clk1(etrig_p_pulse),
    .clk2(adc_clk), .flagout_clk2(etrig_p_pulse_x));

  // 2-FF synchronizer before handling further
  reg [1:0] sel_r=0;
  always @(posedge adc_clk) begin
     trign_0_sync <= {trign_0_sync[0], trign_0};
     trign_1_sync <= {trign_1_sync[0], trign_1};
     trign_2_sync <= {trign_2_sync[0], trign_2};
     sel_r <= sel;  // arrived in lb_clk
  end

  // MUX to decide which trigger to propagate (external triggers are active-low)
  assign async_trig = (sel_r == ETRIG_0) ? ~trign_0_sync[1] :
                      (sel_r == ETRIG_1) ? ~trign_1_sync[1] :
                      (sel_r == ETRIG_2) ? ~trign_2_sync[1] :
                      1'b0;

  // Glitch filter async inputs by ignoring pulses shorter than 128/adc_clk = 1.356 us
  always @(posedge adc_clk) begin
     if (async_trig == 0) async_filt_cnt <= 0;
     else if (!async_trig_filt) async_filt_cnt <= async_filt_cnt + 1;
  end
  assign async_trig_filt = &(async_filt_cnt);

  assign etrig = (sel_r == ETRIG_PROG) ? etrig_p_pulse_x : async_trig_filt;

  // Rising-edge detect
  always @(posedge adc_clk) begin
    etrig_r   <= etrig;
    etrig_r1  <= etrig_r;
    etrig_pulse_i <= etrig_r & ~etrig_r1;
    if (etrig_pulse_i)
      etrig_pulse_cnt_i <= etrig_pulse_cnt_i + 1;
  end

  // Delay the trigger strobe
  always @(posedge adc_clk) begin
    if (etrig_pulse_i == 1'b1) begin
      delay_cnt     <= 0; // reset
      etrig_toggle  <= 1'b1; // raise the flag
      etrig_pulse_delayed_i <= 1'b0; // not ready yet
    end
    else if (etrig_toggle == 1'b1 && delay_cnt < delay_r) begin
      delay_cnt     <= delay_cnt + 1; // keep rolling
      etrig_toggle  <= etrig_toggle; // retain
      etrig_pulse_delayed_i <= 1'b0; // not ready yet
    end
    else if (etrig_toggle == 1'b1 && delay_cnt == delay_r) begin
      delay_cnt     <= 0; // reset
      etrig_toggle  <= 1'b0; // reset
      etrig_pulse_delayed_i <= 1'b1; // one-clock pulse
    end
    else begin
      delay_cnt     <= 0; // reset
      etrig_toggle  <= 1'b0; // keep low
      etrig_pulse_delayed_i <= 1'b0; // keep low
    end
  end

  // two-bit shift-register
  // ensures one-cycle delay between trigger and delayed trigger if delay == 1
  always @(posedge adc_clk) begin
    etrig_sreg    <= etrig_sreg << 1;
    etrig_sreg[0] <= etrig_pulse_i;
  end

  // assigning to output ports
  assign etrig_pulse_cnt  = etrig_pulse_cnt_i;
  assign etrig_pulse      = etrig_sreg[1];

  // mux for the case that the delay is zero
  assign etrig_pulse_delayed = (delay_r == 0) ? etrig_sreg[1] : etrig_pulse_delayed_i;

endmodule
