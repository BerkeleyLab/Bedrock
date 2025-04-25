`timescale 1ns / 1ns

module duc #(
    parameter DW = 17,
    parameter USE_MIX_FOVER4 = 1
)(
    // in adc_clk domain
	input adc_clk,
	input [1:0] div_state,
	input signed [DW-1:0] drive_i,
	input signed [DW-1:0] drive_q,
	input signed [DW:0] cosa,
	input signed [DW:0] sina,
       input signed [DW-1:0] interp_coeff,
       input dac_iq_phase,  // unused for now
	output signed [DW-2:0] dac_mon,
    // in dac_clk domain
	input dac_clk,
       output signed [DW-2:0] dac_out
);

reg signed [DW:0] cosb=0, sinb=0;
reg signed [DW:0] cosb1=0, sinb1=0, cosb2=0, sinb2=0;
wire signed [DW-2:0] out1, out2;

// Digital Up-converter - Double side-band modulator
// check out pg. 268 from https://cds.cern.ch/record/1100538/files/p249.pdf
// Digital quadrature modulation followed by analog up-conversion mixer
// rf_out = I*cos(wt) + Q*sin(wt)
// Gain = `LO_AMP * `CORDIC_GAIN / 2**18 / 2 = 0.235068
// delay: 3 cycles

generate if (USE_MIX_FOVER4) begin : fover4
        // for AWA case
        reg dac_iq_phase_r=0;
        always @(posedge dac_clk) dac_iq_phase_r <= dac_iq_phase;
        // One of these, used in moving dac output data from adc_clk to dac_clk domain
        reg dac_iq=0;
        always @(posedge dac_clk) dac_iq <= ~dac_iq;
        reg dac_iq_use=0;
        always @(posedge dac_clk) dac_iq_use <= dac_iq ^ dac_iq_phase_r;
        // taken from bedrock second_if_out.v
        // Convert the 7/33 LO to 61/132 by (complex) multiplying by a 1/4 LO.
        // This is "cheap" and adds the minimum extra divider state.
        // Only has value because we keep the LO in complex form.
        wire signed [DW:0] cosi = ~cosa;
        wire signed [DW:0] sini = ~sina;
        always @(posedge adc_clk) case(div_state)
            2'b00: begin cosb <= cosa;  sinb <= sina;  end
            2'b01: begin cosb <= sini;  sinb <= cosa;  end
            2'b10: begin cosb <= cosi;  sinb <= sini;  end
            2'b11: begin cosb <= sina;  sinb <= cosi;  end
        endcase

        always @(posedge adc_clk) begin
            // multiply by 1+i/16 \approx exp(i*5/528*2*pi)
            cosb1 <= cosb - (sinb>>>4);
            sinb1 <= sinb + (cosb>>>4);
            // multiply by i+1/16 \approx exp(i*(1/4-5/528)*2*pi)
            cosb2 <= ~sinb + (cosb>>>4);
            sinb2 <= cosb + (sinb>>>4);
            // So we have successfully constructed a phase separation between
            // those two points of about ((1/4-5/528) - (5/528))*2*pi radians
            // = (61/264)*2*pi radians. The two amplitudes balance, and have only
            // increased from nominal by a factor of sqrt(1+1/16^2) = 1.00195.
        end
        flevel_set level1(.clk(adc_clk),
            .cosd(cosb1), .sind(sinb1),
            .i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
            .q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
            .o_data(out1));

        flevel_set level2(.clk(adc_clk),
            .cosd(cosb2), .sind(sinb2),
            .i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
            .q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
            .o_data(out2));

        reg [(DW-2)*2+1:0] dac_grab=0;
        reg [DW-2:0] dac_mux=0;
        always @(posedge dac_clk) begin
           if (dac_iq_use) dac_grab <= {out1, out2};  // related-clock CDC-ish
           dac_mux <= dac_iq_use ? dac_grab[DW-2:0] : dac_grab[(DW-2)*2+1:(DW-2)*2-DW+3];  // no CDC
        end
        assign dac_out = dac_mux;
end else begin: no_fover4
        // LEMP/ALSU/USPAS case
        flevel_set level1(.clk(adc_clk),
            .cosd(cosa), .sind(sina),
            .i_data(drive_i), .i_gate(1'b1), .i_trig(1'b1),
            .q_data(drive_q), .q_gate(1'b1), .q_trig(1'b1),
            .o_data(out1));

        zest_dac_interp #(.DW(DW-1)) dac_interp_a (
            .dsp_clk        (adc_clk),
            .din            (out1),
            .coeff          (interp_coeff),
            .dac_clk        (dac_clk),
            .dout           (dac_out)
        );
end endgenerate
assign dac_mon = out1;
endmodule
