`timescale 1ns / 1ns
// this module is used to pulse the drive signal (XXX I should probably call it
// something more meaningful) and should really belong in bedrock/dsp/hosted
// includes software settable registers:
// 1. X/Y amplitude - depends on the bunch charge and beam phase
// 2. pulse width (triangular wave)
// Also use the bunch_arrival_trig from timing system to has a trigger to
// start these pulses
// Final output is then added to the feedback loop (mp_proc/xy_pi_clip) (P+I+pulse)
module pulse_drive (
    input clk,
    input iq,
    // interleaved X/Y
    input signed [17:0] amp,      // external
    output [0:0] amp_addr,  // external address for amp
    // are in clk cycles, max of 1 us (max value of 94)
    input [6:0] pwidth,          // external
    input bunch_arrival_trig,
    // interleaved X/Y for xy_pi_clip
    output signed [17:0] tri_out_xy
);

// to switch btw I/Q
assign amp_addr = iq;

reg [17:0] cnt = 0;
reg active = 0;
// Find the peak of the triangular wave (half of width)
wire [6:0] midpoint = pwidth >> 1;
always @(posedge clk) begin
    if (bunch_arrival_trig) begin
        active <= 1;
        cnt <= 0;
    end else if (active) begin
        if (cnt < (pwidth - 1))
            cnt <= cnt + 1;
        else begin
            cnt <= 0;
            active <= 0;
        end
    end
end

reg signed [24:0] temp_tri = 0;
always @(posedge clk) begin
    if (active && (pwidth > 7'd1)) begin
        if (cnt <= (pwidth-1)/2) temp_tri <= (2*cnt*amp)/(pwidth-1);
        else temp_tri <= (2*(pwidth-1-cnt)*amp)/(pwidth-1);
    end else temp_tri <= 0;
end

assign tri_out_xy = temp_tri[17:0];

endmodule
