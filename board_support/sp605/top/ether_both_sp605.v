`timescale 1ns / 1ps

module ether_both_sp605(
		       // Stupid non-general-purpose FPGA pins
			input            sfpclk_p,
			input            sfpclk_n,
	                input            rxn0,
	                input            rxp0,
	                output           txn0,
	                output           txp0,
	                input            rxn1,
	                input            rxp1,
	                output           txn1,
	                output           txp1,
			// SFP Pins
			output           SFP_TX_DISABLE,
			input            SFP_LOS,
			inout            IIC_SDA_SFP,
			output           IIC_SCL_SFP,
			// Faceplate Ethernet pins
			output           PHY_MDC,
			inout            PHY_MDIO,

			// GMII related:
			input            SYSCLK_P,
			input            SYSCLK_N,
			input            GMII_RX_CLK,
			input [7:0]      GMII_RXD,
			input            GMII_RX_DV,
			input            GMII_RX_ER, // not used XXX that's a mistake
			output           GMII_GTX_CLK,
		        input            GMII_TX_CLK, // not used
			output reg [7:0] GMII_TXD,
			output reg       GMII_TX_EN,
			output reg       GMII_TX_ER,
			output           PHY_RSTN,
			output [3:0]     LED
			);
   // LED assignment derived from bit assignments here,
   // in aggregate.v, and in client_rx.v.
   //   LED[0] D7: Rx CRC OK (sticks on after a single packet passes CRC test)
   //   LED[1] D8: 3.7 Hz clock-present blinker
   //   LED[2] D1: brightness controlled by UDP port 1000, payload byte 1
   //   LED[3] D2: brightness controlled by UDP port 1000, payload byte 2
   //   LED[4] D3: ARP packet rejected
   //   LED[5] D4: ARP packet accepted
   //   LED[6] D5: Rx packet activity
   //   LED[7] D6: Tx packet activity

   parameter [31:0] ip  = {8'd192,8'd168,8'd21,8'd116};    // 192.168.21.116
   parameter [47:0] mac = 48'h00105ad152b4;  // scraped from a 3C905B
   parameter [31:0] ip2 = {8'd192,8'd168,8'd21,8'd117};    // 192.168.21.117
   parameter [47:0] mac2 = 48'h00105ad155b3;  // scraped from a 3C905B
   reg [3:0] power_conf_iob=4'b0000;// Start all off (except for FP Eth, see below)


   wire clk125;

   // ============= Clock setup =============


   sp60x_clocks clkgen(
		       .SYSCLK_P(SYSCLK_P), .SYSCLK_N(SYSCLK_N),
		       .RST(1'b0),
		       .CLK125(clk125)
		       );
`define HAVE_ODDR2
`ifdef HAVE_ODDR2
   ODDR2 GTXCLK_OUT(
		    .Q(GMII_GTX_CLK),
		    .C0(clk125),
		    .C1(~clk125),
		    .CE(1'b1),
		    .D0(1'b1),
		    .D1(1'b0),
		    .R(1'b0),
		    .S(1'b0)
		    );
`else
   assign GMII_GTX_CLK=clk125;
`endif

   // ============= Ethernet on SFP0 follows ===================

   // The two clocks are sourced from gmii_link
   wire rx_clk, tx_clk;

   // Stupid resets
   reg gtp_reset=1, gtp_reset1=1;
   always @(posedge tx_clk) begin
      gtp_reset <= gtp_reset1;
      gtp_reset1 <= 0;
   end

   // Spartan-6 MGT wrapper on top of wrapper on s6_gtpwizard_tile
   wire [9:0] txdata0, rxdata0;
   wire [9:0] txdata1, rxdata1;
   wire [6:0] rxstatus0, rxstatus1;  // XXX not hooked up?
   wire       txstatus0, txstatus1;
   wire       plllkdet;
   wire       resetdone;

   s6_gtp_wrap s6_gtp_wrap_i(
			     .txdata0(txdata0), .txstatus0(txstatus0),
			     .rxdata0(rxdata0), .rxstatus0(rxstatus0),
			     .txdata1(txdata1), .txstatus1(txstatus1),
			     .rxdata1(rxdata1), .rxstatus1(rxstatus1),
			     .tx_clk(tx_clk), .rx_clk(rx_clk),
			     .gtp_reset_i(gtp_reset),
			     .refclk_p(sfpclk_p), .refclk_n(sfpclk_n),
			     .plllkdet(plllkdet),
			     .resetdone(resetdone),
                             .rxn0(rxn0), .rxp0(rxp0),
			     .txn0(txn0), .txp0(txp0),
	                     .rxn1(rxn1), .rxp1(rxp1),
	                     .txn1(txn1), .txp1(txp1)
			     );

   wire [2:0] debug;

   // bridge between serdes and internal GMII
   // watch the clock domains!
   wire [7:0] abst2_in, abst2_out, rxd;
   wire       abst2_in_s, abst2_out_s, rx_dv;
   reg       rd=0;  // Running Disparity, see below
   reg       rd_hack=0, rd_hack0=0;  // Software-writable
   always @(posedge tx_clk) rd_hack <= rd_hack0;

   wire [5:0] gmii_link_leds;
   wire [15:0] lacr_rx;  // nominally in Rx clock domain, don't sweat it
   wire [1:0]  an_state_mon;
   reg        an_bypass=1;  // settable by software
   gmii_link glink(
		.RX_CLK(rx_clk),
		.RXD(rxd),
		.RX_DV(rx_dv),
		.GTX_CLK(tx_clk),
		.TXD(abst2_out),
		.TX_EN(abst2_out_s),
		.TX_ER(1'b0),
		.txdata(txdata0),
		.rxdata(rxdata0),
		.rx_err_los(rxstatus0[4]),
		.an_bypass(an_bypass),
		.lacr_rx(lacr_rx),
		.an_state_mon(an_state_mon),
		.leds(gmii_link_leds)
		);

   // Trace logic on the data source side, rx_clk domain
`ifdef TRACE_RX
   wire [31:0] trace_in = {4'h4,rx_dv,1'h1,rxd,rxstatus0,rxdata0};
   wire        trace_clk=rx_clk;
`else
   wire [31:0] trace_in = {4'h4,abst2_out_s,3'h1,abst2_out,4'b0,txstatus0,txdata0};
   wire        trace_clk=tx_clk;
`endif

   // FIFO from Rx clock domain to Tx clock domain
   gmii_fifo rx2tx(
		.clk_in(rx_clk), .d_in(rxd),   .strobe_in(rx_dv),
		.clk_out(tx_clk),   .d_out(abst2_in), .strobe_out(abst2_in_s)
		);

   // Single clock domain, abstract Ethernet
   wire        rx_crc_ok2;
   wire [7:0]  data_rx2_1;  wire ready2_1, strobe_rx2_1, crc_rx2_1;
   wire [7:0]  data_rx2_2;  wire ready2_2, strobe_rx2_2, crc_rx2_2;
   wire [7:0]  data_rx2_3;  wire ready2_3, strobe_rx2_3, crc_rx2_3;
   wire [7:0]  data_tx2_1;  wire [10:0] length2_1;  wire req2_1, ack2_1, warn2_1, strobe_tx2_1;
   wire [7:0]  data_tx2_2;  wire [10:0] length2_2;  wire req2_2, ack2_2, warn2_2, strobe_tx2_2;
   wire [7:0]  data_tx2_3;  wire [10:0] length2_3;  wire req2_3, ack2_3, warn2_3, strobe_tx2_3;
   wire [3:0]  abst2_leds;
   aggregate #(.ip(ip2), .mac(mac2))
   a2(
      .clk(tx_clk),
      .eth_in(abst2_in),   .eth_in_s(abst2_in_s),
      .eth_out(abst2_out), .eth_out_s(abst2_out_s),
      .rx_crc_ok(rx_crc_ok2),
      .address_set(9'b0),
      .data_rx_1(data_rx2_1), .ready_1(ready2_1), .strobe_rx_1(strobe_rx2_1), .crc_rx_1(crc_rx2_1),
      .data_rx_2(data_rx2_2), .ready_2(ready2_2), .strobe_rx_2(strobe_rx2_2), .crc_rx_2(crc_rx2_2),
      .data_rx_3(data_rx2_3), .ready_3(ready2_3), .strobe_rx_3(strobe_rx2_3), .crc_rx_3(crc_rx2_3),
      .req_1(req2_1), .length_1(length2_1), .ack_1(ack2_1), .warn_1(warn2_1), .strobe_tx_1(strobe_tx2_1), .data_tx_1(data_tx2_1),
      .req_2(req2_2), .length_2(length2_2), .ack_2(ack2_2), .warn_2(warn2_2), .strobe_tx_2(strobe_tx2_2), .data_tx_2(data_tx2_2),
      .req_3(req2_3), .length_3(length2_3), .ack_3(ack2_3), .warn_3(warn2_3), .strobe_tx_3(strobe_tx2_3), .data_tx_3(data_tx2_3),
	.debug(debug), .leds(abst2_leds)
      );

   wire [23:0] control2_addr;
   wire        control2_strobe, control2_rd;
   wire [31:0] data2_out;
   wire [31:0] data2_in;

   // instantiate some test clients
   // Tx only, but triggered by corresponding Rx ready
   client_tx cl1tx(
		.clk(tx_clk), .ack(ack2_1),
		.strobe(strobe_tx2_1), .req(req2_1),
		.length(length2_1), .data_out(data_tx2_1),
		.srx(ready2_1)
		);

   wire [1:0]  led2;
   client_rx cl1rx(
		.clk(tx_clk), .ready(ready2_1), .strobe(strobe_rx2_1),
		.crc(crc_rx2_1), .data_in(data_rx2_1), .led(led2)
		);

   reg nomangle=0;
   client_thru cl2rxtx(
		.clk(tx_clk), .rx_ready(ready2_2), .rx_strobe(strobe_rx2_2),
		.rx_crc(crc_rx2_2), .data_in(data_rx2_2),
		.nomangle(nomangle),
		.tx_ack(ack2_2), .tx_warn(warn2_2),
		.tx_req(req2_2), .tx_len(length2_2), .data_out(data_tx2_2)
		);

   mem_gateway #(.read_pipe_len(11))
     sfp_cl3 (
	      .clk(tx_clk), .rx_ready(ready2_3), .rx_strobe(strobe_rx2_3),
	      .rx_crc(crc_rx2_3), .packet_in(data_rx2_3),
	      .tx_ack(ack2_3), .tx_strobe(warn2_3),
	      .tx_req(req2_3), .tx_len(length2_3), .packet_out(data_tx2_3),
	      .addr(control2_addr),
	      .control_strobe(control2_strobe), .control_rd(control2_rd),
	      .data_out(data2_out), .data_in(data2_in)
	      );

   // Clock domain crossing ((local bus/Ethernet) --> dsp clock domains)
   wire [56:0] lb_word_out_eth={data2_out, control2_addr, control2_rd};
   wire [56:0] lb_word_out_dsp;
   wire [31:0] lb_data;
   wire [23:0] lb_addr;
   wire        lb_control_rd;
   wire        lb_control_strobe;
   wire        dsp_clk = clk125;

   // gate_in must be & ~control2_rd
   // mem_gateway generate control_strobe at every R/W cycle
   // So just delay lb_control_strobe for a certain time. see below
   data_xdomain #(.size(57))
   x_eth2dsp(.clk_in(tx_clk), .gate_in(control2_strobe), .data_in(lb_word_out_eth),
	     .clk_out(dsp_clk), .gate_out(lb_control_strobe), .data_out(lb_word_out_dsp)
	     );

   assign {lb_data,lb_addr,lb_control_rd}=lb_word_out_dsp;

   // Clock domain crossing (dsp --> (local bus/Ethernet) clock domains)
   reg       lb_control_strobe_d1=1'b0, lb_control_strobe_d2=1'b0, lb_control_strobe_d3=1'b0;
   wire        lb_control_strobe_back;
   // dsp clock domain
   reg [31:0]  lb_data_in;

   // Introduce 3 clock cycle delay to strobe to match data bus pipeline
   always @(posedge dsp_clk) begin
      lb_control_strobe_d1 <= lb_control_strobe;
      lb_control_strobe_d2 <= lb_control_strobe_d1;
      lb_control_strobe_d3 <= lb_control_strobe_d2;
   end

   // Multiplexer selecting data output from the different modules to the Ethernet input via the local data bus
   always @(posedge dsp_clk)
	case(lb_addr[23:20])
	  0: lb_data_in <= "Hell";
	  1: lb_data_in <= "o wo";
	  2: lb_data_in <= "rld!";
	  3: lb_data_in <= "(::)";
	  default: lb_data_in <= 32'hdeadbeef;
	endcase // case (lb_addr[23:20])

   data_xdomain #(.size(32))
   x_dsp2eth(.clk_in(dsp_clk), .gate_in(lb_control_strobe), .data_in(lb_data_in),
	     .clk_out(tx_clk), .gate_out(lb_control_strobe_back), .data_out(data2_in)
	     );
   // nobody looks at lb_control_strobe_back yet, but it could be used to detect a timing error


   // trace logic, now that the source is defined
   reg [10:0]  trace_wadd=0;
   reg [31:0]  trace_in1=0, trace_in2=0;  // input history
   // actually save trace_in2 so we get old as well as triggering data
   wire        trace_trig = trace_in2[8:0] != trace_in[8:0];  // sensitive to changes in alternating rx_data0
   reg        trace_req1=0;  // forward reference
   reg        trace_nowait=0;  // software controlled
   reg        trace_run=0, trace_req2=0, trace_done=0;
   wire        trace_ending=trace_wadd==11'h7ff;
   always @(posedge trace_clk) begin
      trace_wadd <= trace_run ? (trace_wadd+1) : 0;
      trace_in1 <= trace_in;
      trace_in2 <= trace_in1;
      trace_req2 <= trace_req1;  // cross clock domains
      if (trace_req2 & ~trace_run & (trace_nowait | trace_trig))
	trace_run <= 1;
      if (trace_ending)
	trace_run <= 0;
      if (trace_ending)
	trace_done <= 1;  // flag to requesting clock domain
      if (~trace_req2)
	trace_done <= 0;
   end

   // ============= Faceplate GMII Ethernet follows ===================
   wire        gtx_clk=clk125;
   wire        fp_clk=clk125;   // at some point we want a ring clock instead

   // Latch Rx input pins in IOB
   // XXX? assign GMII_RX_CLK = rx_clk;
   reg [7:0]   rx1d=0;
   reg        rx1_dv=0, rx1_er=0;
   always @(posedge GMII_RX_CLK) begin
      rx1d   <= GMII_RXD;
      rx1_dv <= GMII_RX_DV;
      rx1_er <= GMII_RX_ER;
   end
   // FIFO from Rx clock domain to ring clock domain
   wire [7:0] abst1_in, abst1_out;
   wire       abst1_in_s, abst1_out_s;
   gmii_fifo rx2ring(
		     .clk_in(GMII_RX_CLK), .d_in(rx1d),  .strobe_in(rx1_dv),
		     .clk_out(fp_clk),    .d_out(abst1_in), .strobe_out(abst1_in_s)
		     );

   // Single clock domain, abstract Ethernet
   wire       rx_crc_ok1;
   wire [7:0] data_rx_1;  wire ready_1, strobe_rx_1, crc_rx_1;
   wire [7:0] data_rx_2;  wire ready_2, strobe_rx_2, crc_rx_2;
   wire [7:0] data_rx_3;  wire ready_3, strobe_rx_3, crc_rx_3;
   wire [7:0] data_tx_1;  wire [10:0] length_1;  wire req_1, ack_1, warn_1, strobe_tx_1;
   wire [7:0] data_tx_2;  wire [10:0] length_2;  wire req_2, ack_2, warn_2, strobe_tx_2;
   wire [7:0] data_tx_3;  wire [10:0] length_3;  wire req_3, ack_3, warn_3, strobe_tx_3;
   wire [3:0] abst1_leds;
   aggregate #(.ip(ip), .mac(mac))
   a1(
      .clk(fp_clk),
      .eth_in(abst1_in),   .eth_in_s(abst1_in_s),
      .eth_out(abst1_out), .eth_out_s(abst1_out_s),
      .rx_crc_ok(rx_crc_ok1),
      .address_set(9'b0),
      .data_rx_1(data_rx_1), .ready_1(ready_1), .strobe_rx_1(strobe_rx_1), .crc_rx_1(crc_rx_1),
      .data_rx_2(data_rx_2), .ready_2(ready_2), .strobe_rx_2(strobe_rx_2), .crc_rx_2(crc_rx_2),
      .data_rx_3(data_rx_3), .ready_3(ready_3), .strobe_rx_3(strobe_rx_3), .crc_rx_3(crc_rx_3),
      .req_1(req_1), .length_1(length_1), .ack_1(ack_1), .warn_1(warn_1), .strobe_tx_1(strobe_tx_1), .data_tx_1(data_tx_1),
      .req_2(req_2), .length_2(length_2), .ack_2(ack_2), .warn_2(warn_2), .strobe_tx_2(strobe_tx_2), .data_tx_2(data_tx_2),
      .req_3(req_3), .length_3(length_3), .ack_3(ack_3), .warn_3(warn_3), .strobe_tx_3(strobe_tx_3), .data_tx_3(data_tx_3),
      .leds(abst1_leds)
      );


   // instantiate some test clients

   reg [7:0]  client_txu_config=8'h12;
   wire [3:0] sfp_static={SFP_LOS, SFP_TX_DISABLE, IIC_SDA_SFP, IIC_SCL_SFP};
   client_txu mut
     (.clk(fp_clk), .ack(ack_1), .strobe(warn_1),
      .req(req_1), .length(length_1), .data_out(data_tx_1),
      .rx_clk(rx_clk), .tx_clk(tx_clk), .gr_clk(GMII_RX_CLK),
      .if_config(client_txu_config),
      .GBE_FP_MDC(PHY_MDC), .GBE_FP_MDIO(PHY_MDIO),
      .SFP0_MOD1(IIC_SCL_SFP), .SFP0_MOD2(IIC_SDA_SFP),
      .other({lacr_rx,8'hbe, 2'b11, an_state_mon, sfp_static})
      );

   wire [1:0] led1;
   client_rx cl1rx1 (
		     .clk(fp_clk), .ready(ready_1), .strobe(strobe_rx_1),
		     .crc(crc_rx_1), .data_in(data_rx_1), .led(led1)
		     );

   client_thru cl2rxtx1 (
			 .clk(fp_clk),
			 .rx_ready(ready_2), .rx_strobe(strobe_rx_2),
			 .rx_crc(crc_rx_2), .data_in(data_rx_2),
			 .nomangle(nomangle),
			 .tx_ack(ack_2), .tx_warn(warn_2),
			 .tx_req(req_2), .tx_len(length_2), .data_out(data_tx_2)
			 );

   wire [23:0] control1_addr;
   wire        control1_strobe, control1_rd;
   wire [31:0] data1_out;
   reg [31:0]  data1_in=0;
   mem_gateway cl3rxtx1 (.clk(fp_clk),
		      .rx_ready(ready_3), .rx_strobe(strobe_rx_3),
		      .rx_crc(crc_rx_3), .packet_in(data_rx_3),
		      .tx_ack(ack_3), .tx_strobe(warn_3),
		      .tx_req(req_3), .tx_len(length_3), .packet_out(data_tx_3),
		      .addr(control1_addr),
		      .control_strobe(control1_strobe), .control_rd(control1_rd),
		      .data_out(data1_out), .data_in(data1_in)
		      );


   // Stupid test rig
   wire [31:0] trace_ro;
   dpram #(.aw(11), .dw(32))
   trace(
	 .clka(rx_clk), .addra(trace_wadd), .dina(trace_in2), .wena(trace_run),
	 .clkb(fp_clk), .addrb(control1_addr[10:0]), .doutb(trace_ro));
   always @(posedge fp_clk)
     case ({control1_addr[12],control1_addr[1:0]})
       0: data1_in <= "Good";
       1: data1_in <= "bye ";
       2: data1_in <= trace_req1 ? "Davi" : "Worl";  // trace has been requested but not yet acknowledged
       3: data1_in <= {"d!", 16'h0d0a};
       4: data1_in <= trace_ro;
       5: data1_in <= trace_ro;
       6: data1_in <= trace_ro;
       7: data1_in <= trace_ro;
     endcase // case ({control1_addr[12],control1_addr[1:0]})

   always @(posedge fp_clk) begin
      if (control1_strobe & ~control1_rd & (control1_addr[7:0]==8'h76))
	power_conf_iob <= data1_out;
//      if (control1_strobe & ~control1_rd & (control1_addr[7:0]==8'h77))
//      client_txu_config <= data1_out;
   end
   reg trace_req0=0, trace_done1=0;
   always @(posedge fp_clk) begin
      trace_req0 <= (control1_strobe & ~control1_rd & (control1_addr[7:0]==8'h78));
      if (control1_strobe & ~control1_rd & (control1_addr[7:0]==8'h78))
	trace_nowait <= data1_out[0];
      trace_done1 <= trace_done;  // cross clock domains
      if (trace_req0) trace_req1 <= 1;  // flag for acknowledging clock domain
      if (trace_done1) trace_req1 <= 0;
   end
   always @(posedge fp_clk) begin
      if (control1_strobe & ~control1_rd & (control1_addr[7:0]==8'h79))
	{rd_hack0,an_bypass} <= data1_out[1:0];
   end
   always @(posedge fp_clk) begin
      if (control1_strobe & ~control1_rd & (control1_addr[7:0]==8'h7a))
	nomangle <= data1_out[0];
   end


   // FIFO from ring clock domain to tx clock domain
   // No-op in the current configuration
   wire [7:0] txd;
   wire       tx_en;
`ifdef LATER
   gmii_fifo ring2tx(
		     .clk_in(fp_clk), .d_in(abst1_out), .strobe_in(abst1_out_s),
		     .clk_out(gtx_clk), .d_out(txd), .strobe_out(tx_en)
		     );
`else
   assign txd=abst1_out;
   assign tx_en=abst1_out_s;
`endif

   // Latch Tx output pins in IOB
   always @(posedge gtx_clk) begin
      GMII_TXD   <= txd;
      GMII_TX_EN <= tx_en;
      GMII_TX_ER <= 0;  // Our logic never needs this
   end

   // ============= Housekeeping follows ===================

   // Simple blinker to show clock exists
   reg [24:0]  ecnt=0;
   always @(posedge rx_clk) ecnt<=ecnt+1;
   wire        blink=ecnt[24];

   assign LED={abst2_leds,led2,blink,resetdone};
   assign PHY_RSTN=1;    // Can't do anything unless PHY is out of reset

   // Make the SFP Module happy:
   assign SFP_TX_DISABLE = 0;


endmodule

//
// ether_both_sp605.v ends here
