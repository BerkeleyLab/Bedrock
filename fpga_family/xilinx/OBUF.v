module OBUF #(
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "FAST"
) (
    output O,
    input I
);

buf b(O, I);

endmodule
