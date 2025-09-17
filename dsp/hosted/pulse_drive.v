`timescale 1ns / 1ns
// this module is used to pulse the drive signal (XXX I should probably call it
// something more meaningful)
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
    (* external *)
    input signed [17:0] amp,  // external
    (* external *)
    output [0:0] amp_addr,  // external address for amp
    // are in clk cycles, max of 1 us (max value of 94)
    (* external *)
    input [6:0] wth,  // external
    input bunch_arrival_trig,
    // interleaved X/Y for xy_pi_clip
    output signed [17:0] tri_out_xy
);

// to switch btw I/Q
assign amp_addr = iq;

reg [17:0] cnt = 0;
reg active = 0;
// Find the peak of the triangular wave (half of width)
wire [6:0] midpoint = wth >> 1;
// separate odd vs even widths
// for odd widths there will be single clock cycle of flatness
wire [6:0] up = midpoint;
wire [6:0] down = wth-midpoint-1;

reg ramp_up = 0;  // 1 = ramping up, 0 = ramping down
always @(posedge clk) begin
    if (bunch_arrival_trig && !active) begin
        // Start new triangle
        active <= 1;
        cnt <= 0;
        ramp_up <= 1;
    // Retrigger: always start ramping up from current value
    end else if (bunch_arrival_trig && active) ramp_up <= 1;
    else if (active) begin
        if (ramp_up) begin
            if (cnt < (wth-1) && wth !== 0) begin
                cnt <= cnt + 1;
                // hit midpoint, start ramping down
                if (cnt == ((wth-1)>>1)) ramp_up <= 0;
            end else begin
                cnt <= 0;
                active <= 0;
            end
        end else begin  // ramping down
            if (cnt > 0) cnt <= cnt - 1;
            else active <= 0;
        end
    end
end

reg signed [24:0] temp_tri = 0;
always @(posedge clk) begin
    if (active && (wth > 7'd1)) begin
        if (cnt <= up) temp_tri <= (2*cnt*amp)/(wth-1);
        else temp_tri <= (2*(wth-1-cnt)*amp)/(wth-1);
    end else temp_tri <= 0;
end

assign tri_out_xy = temp_tri[24:8] + temp_tri[7];

endmodule
