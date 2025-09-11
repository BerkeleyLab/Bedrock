module pulse_drive_wrapper(
    input clk,
    input iq,
    input signed [17:0] ampx,
    input signed [17:0] ampy,
    input [6:0] wth,
    input bunch_arrival_trig,
    output reg signed [17:0] tri_out_x,
    output reg signed [17:0] tri_out_y
);
    wire [0:0] amp_addr = iq;
    wire signed [17:0] amp = amp_addr ? ampx : ampy;

    wire signed [17:0] tri_out_xy;
    pulse_drive dut (
        .clk(clk),
        .iq(iq),
        .amp(amp),
        .wth(wth),
        .bunch_arrival_trig(bunch_arrival_trig),
        .tri_out_xy(tri_out_xy)
    );

    always @(posedge clk) begin
        if (iq == 1'b0) tri_out_y <= tri_out_xy;
        else tri_out_x <= tri_out_xy;
    end

    initial begin
        $dumpfile("pulse_drive_wrapper.vcd");
        $dumpvars(10, pulse_drive_wrapper);
    end
endmodule
