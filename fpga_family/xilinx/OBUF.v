module OBUF #(
    parameter IOSTANDARD = "DEFAULT"
) (
    output O,
    input I
);

buf b(O, I);

endmodule
