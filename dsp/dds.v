`timescale  1ns / 1ns

module dds #(
    parameter integer DWLO = 18,
    parameter integer DWH = 20,
    parameter integer DWL = 12
) (
    input clk,
    input reset,
    input [DWLO-1:0] amplitude,
    input signed [DWLO:0] phase_shift,
    input [DWH-1:0] phase_step_h,
    input [DWL-1:0] phase_step_l,
    input [DWL-1:0] modulo,
    output signed [DWLO-1:0] sin_out,
    output signed [DWLO-1:0] cos_out
);

    wire signed [DWLO-1:0] cosd, sind;
    wire [DWLO:0] phase_acc;
    ph_acc_general #(.DWH(DWH), .DWL(DWL), .DWO(DWLO+1)) dds_lo (
        .clk            (clk),
        .reset          (reset),
        .phase_acc      (phase_acc),
        .phase_step_h   (phase_step_h),
        .phase_step_l   (phase_step_l),
        .modulo         (modulo)
    );

    wire signed [DWLO:0] dds_phase = phase_acc + phase_shift;
    cordicg_b22 #(.nstg(20), .width(DWLO)) cordic (
        .clk            (clk),
        .opin           (2'b00),
        .xin            (amplitude),
        .yin            ({DWLO{1'b0}}),
        .phasein        (dds_phase),
        .xout           (cos_out),
        .yout           (sin_out)
    );

endmodule
