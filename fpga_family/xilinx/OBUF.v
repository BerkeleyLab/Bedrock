module OBUF #(
    parameter integer DRIVE = 12,
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
    output O,
    input I
);

buf b(O, I);

endmodule
