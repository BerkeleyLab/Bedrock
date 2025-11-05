// generate a trigger signal with a delay and divide
module trigger #(
    parameter DW=16
) (
    input   clk,
    input   reset,
    input   trig_in,
    input   [DW-1:0] delay,
    input   [DW-1:0] divide,
    output  trig_out
);
    reg [DW-1:0] cnt=0, div_cnt=0;
    reg trig_detected = 0, trig_in1 = 0;
    wire internal_trigger;

    always @(posedge clk) begin
        if (reset || !trig_detected) begin
            cnt <= delay;
        end else begin
            if (trig_detected && div_cnt == 0) cnt <= (cnt > 0) ? cnt - 1'b1 : cnt;
        end
        if (reset || !trig_detected) begin
            div_cnt <= (divide == 0) ? 0: divide - 1;
        end else begin
            if (trig_in) div_cnt <= (div_cnt > 0) ? div_cnt - 1 : div_cnt;
        end
        trig_detected <= trig_out ? 0 : trig_in ? 1 : trig_detected;
        trig_in1 <= trig_in;
    end

    assign trig_out = (divide != 0 || delay != 0) ? internal_trigger : trig_in1;
    assign internal_trigger = trig_detected & (div_cnt == 0) & (cnt == 0);

endmodule